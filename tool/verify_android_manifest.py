#!/usr/bin/env python3
"""
Manifest & Google Play Policy Verification Utility.
Audits Android source and merged manifests to ensure strict compliance with:
1. Google Play Store Developer Policies.
2. Least-privilege permissions & tools:node="remove" guards.
3. Explicit component export attributes (Android 12+).
4. Deep link OAuth callbacks (nitcbus://auth-callback).
5. Cleartext traffic restriction and network security configurations.
"""

import argparse
import os
import sys
import xml.etree.ElementTree as ET

ANDROID_NS = "http://schemas.android.com/apk/res/android"
TOOLS_NS = "http://schemas.android.com/tools"

NAMESPACES = {
    "android": ANDROID_NS,
    "tools": TOOLS_NS,
}

FORBIDDEN_PERMISSIONS = {
    "android.permission.ACCESS_BACKGROUND_LOCATION",
    "android.permission.READ_EXTERNAL_STORAGE",
    "android.permission.WRITE_EXTERNAL_STORAGE",
    "android.permission.READ_MEDIA_IMAGES",
    "android.permission.READ_MEDIA_VIDEO",
    "com.google.android.gms.permission.AD_ID",
    "android.permission.REQUEST_INSTALL_PACKAGES",
    "android.permission.SYSTEM_ALERT_WINDOW",
}

def get_attr(element, namespace, name):
    """Retrieve attribute with namespace or unqualified fallback."""
    namespaced = f"{{{namespace}}}{name}"
    if namespaced in element.attrib:
        return element.attrib[namespaced]
    return element.attrib.get(name)

def audit_manifest_content(root, is_merged=False):
    """
    Audits an XML ElementTree root representing an AndroidManifest.xml.
    Returns a list of error strings (empty if valid).
    """
    errors = []

    # 1. Package / Application ID audit (in merged manifest)
    pkg = root.attrib.get("package")
    if pkg and pkg.startswith("com.example"):
        errors.append(f"Forbidden placeholder package name '{pkg}'.")

    # 2. Application element audit
    application = root.find("application")
    if application is None and is_merged:
        errors.append("Missing <application> element in manifest.")
    elif application is not None:
        uses_cleartext = get_attr(application, ANDROID_NS, "usesCleartextTraffic")
        if not is_merged:
            # Main source manifest must explicitly enforce usesCleartextTraffic="false"
            if uses_cleartext != "false":
                errors.append(
                    f"Main manifest <application> must set android:usesCleartextTraffic='false'. Found: '{uses_cleartext}'."
                )
            
            # Security & backup rules audit
            net_sec = get_attr(application, ANDROID_NS, "networkSecurityConfig")
            if net_sec != "@xml/network_security_config":
                errors.append(
                    f"<application> must declare android:networkSecurityConfig='@xml/network_security_config'. Found: '{net_sec}'."
                )
            
            data_ext = get_attr(application, ANDROID_NS, "dataExtractionRules")
            if data_ext != "@xml/data_extraction_rules":
                errors.append(
                    f"<application> must declare android:dataExtractionRules='@xml/data_extraction_rules'. Found: '{data_ext}'."
                )
            
            full_backup = get_attr(application, ANDROID_NS, "fullBackupContent")
            if full_backup != "@xml/backup_rules":
                errors.append(
                    f"<application> must declare android:fullBackupContent='@xml/backup_rules'. Found: '{full_backup}'."
                )
        else:
            # Merged release manifest must not have cleartext permitted
            if uses_cleartext == "true":
                errors.append("Merged release manifest has android:usesCleartextTraffic='true'!")

    # 3. Component explicit android:exported audit
    if application is not None:
        for tag in ["activity", "service", "receiver"]:
            for comp in application.findall(tag):
                intent_filters = comp.findall("intent-filter")
                if intent_filters:
                    exported = get_attr(comp, ANDROID_NS, "exported")
                    comp_name = get_attr(comp, ANDROID_NS, "name") or "<unnamed>"
                    if exported not in ("true", "false"):
                        errors.append(
                            f"<{tag} android:name='{comp_name}'> has intent-filters but lacks explicit android:exported attribute."
                        )

    # 4. Permissions audit
    declared_permissions = set()
    removed_permissions = set()

    for perm in root.findall("uses-permission"):
        name = get_attr(perm, ANDROID_NS, "name")
        node_action = get_attr(perm, TOOLS_NS, "node")
        if not name:
            continue
        
        if node_action == "remove":
            removed_permissions.add(name)
        else:
            declared_permissions.add(name)

    if not is_merged:
        # Source manifest must have tools:node="remove" for high-risk forbidden permissions
        for forbidden in FORBIDDEN_PERMISSIONS:
            if forbidden not in removed_permissions:
                errors.append(
                    f"Source manifest must explicitly strip '{forbidden}' using tools:node='remove'."
                )
    else:
        # Merged manifest must NOT contain any forbidden permissions
        for forbidden in FORBIDDEN_PERMISSIONS:
            if forbidden in declared_permissions:
                errors.append(
                    f"Merged release manifest contains forbidden Google Play permission: '{forbidden}'!"
                )

    # Location permission pairing check (Android 12+)
    if "android.permission.ACCESS_FINE_LOCATION" in declared_permissions:
        if "android.permission.ACCESS_COARSE_LOCATION" not in declared_permissions:
            errors.append(
                "ACCESS_FINE_LOCATION is declared without required companion ACCESS_COARSE_LOCATION (Android 12+ requirement)."
            )

    # 5. OAuth Deep link registration check (nitcbus://auth-callback)
    if not is_merged:
        has_oauth_deeplink = False
        if application is not None:
            for activity in application.findall("activity"):
                for ifilter in activity.findall("intent-filter"):
                    actions = [get_attr(a, ANDROID_NS, "name") for a in ifilter.findall("action")]
                    categories = [get_attr(c, ANDROID_NS, "name") for c in ifilter.findall("category")]
                    has_view = "android.intent.action.VIEW" in actions
                    has_default = "android.intent.category.DEFAULT" in categories
                    has_browsable = "android.intent.category.BROWSABLE" in categories

                    for data in ifilter.findall("data"):
                        scheme = get_attr(data, ANDROID_NS, "scheme")
                        host = get_attr(data, ANDROID_NS, "host")
                        if scheme == "nitcbus" and host == "auth-callback" and has_view and has_default and has_browsable:
                            has_oauth_deeplink = True
                            # Ensure activity is exported
                            act_exported = get_attr(activity, ANDROID_NS, "exported")
                            if act_exported != "true":
                                errors.append("Activity handling 'nitcbus://auth-callback' must be android:exported='true'.")

        if not has_oauth_deeplink:
            errors.append("Source manifest lacks intent-filter for OAuth callback scheme 'nitcbus://auth-callback'.")

        # 6. Package visibility queries
        queries = root.find("queries")
        if queries is None:
            errors.append("Source manifest lacks <queries> declaration.")
        else:
            has_https_query = False
            has_custom_tabs_query = False
            for intent in queries.findall("intent"):
                for data in intent.findall("data"):
                    if get_attr(data, ANDROID_NS, "scheme") == "https":
                        has_https_query = True
                for action in intent.findall("action"):
                    if get_attr(action, ANDROID_NS, "name") == "android.support.customtabs.action.CustomTabsService":
                        has_custom_tabs_query = True

            if not has_https_query:
                errors.append("<queries> must include an intent for https scheme.")
            if not has_custom_tabs_query:
                errors.append("<queries> must include an intent for CustomTabsService.")

    return errors

def audit_file(path, is_merged=False):
    if not os.path.exists(path):
        return [f"File not found: {path}"]
    try:
        tree = ET.parse(path)
        root = tree.getroot()
        return audit_manifest_content(root, is_merged=is_merged)
    except Exception as e:
        return [f"XML parsing failed for {path}: {str(e)}"]

def main():
    parser = argparse.ArgumentParser(description="Audit Android Manifest for Google Play compliance.")
    parser.add_argument(
        "--source",
        default="android/app/src/main/AndroidManifest.xml",
        help="Path to source AndroidManifest.xml"
    )
    parser.add_argument(
        "--merged",
        help="Path to merged release AndroidManifest.xml (optional)"
    )
    parser.add_argument(
        "--check-all",
        action="store_true",
        help="Check source and auto-detect merged release manifest if present."
    )
    args = parser.parse_args()

    project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    source_path = os.path.join(project_root, args.source) if not os.path.isabs(args.source) else args.source

    all_errors = []

    print(f"==> Auditing source manifest: {source_path}")
    source_errors = audit_file(source_path, is_merged=False)
    if source_errors:
        print("  ❌ Source manifest issues found:")
        for err in source_errors:
            print(f"     - {err}")
        all_errors.extend(source_errors)
    else:
        print("  ✓ Source manifest complies with Google Play policy & hardening rules.")

    merged_path = args.merged
    if not merged_path and args.check_all:
        candidate = os.path.join(
            project_root,
            "build/app/intermediates/merged_manifest/release/processReleaseMainManifest/AndroidManifest.xml"
        )
        if os.path.exists(candidate):
            merged_path = candidate

    if merged_path:
        merged_abs = os.path.join(project_root, merged_path) if not os.path.isabs(merged_path) else merged_path
        print(f"==> Auditing merged release manifest: {merged_abs}")
        merged_errors = audit_file(merged_abs, is_merged=True)
        if merged_errors:
            print("  ❌ Merged manifest issues found:")
            for err in merged_errors:
                print(f"     - {err}")
            all_errors.extend(merged_errors)
        else:
            print("  ✓ Merged release manifest has zero forbidden permissions and complies with Play policies.")

    if all_errors:
        print(f"\nManifest audit FAILED with {len(all_errors)} error(s).")
        sys.exit(1)
    else:
        print("\nAll Android manifest compliance checks PASSED successfully.")
        sys.exit(0)

if __name__ == "__main__":
    main()
