#!/usr/bin/env python3
"""
Unit tests for tool/verify_android_manifest.py
"""

import os
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET

# Add tool directory to sys.path
TOOL_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "tool"))
sys.path.insert(0, TOOL_DIR)

from verify_android_manifest import audit_manifest_content, FORBIDDEN_PERMISSIONS

VALID_SOURCE_MANIFEST = """<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

    <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" tools:node="remove" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" tools:node="remove" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" tools:node="remove" />
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" tools:node="remove" />
    <uses-permission android:name="android.permission.READ_MEDIA_VIDEO" tools:node="remove" />
    <uses-permission android:name="com.google.android.gms.permission.AD_ID" tools:node="remove" />
    <uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" tools:node="remove" />
    <uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" tools:node="remove" />

    <application
        android:label="Tracklet"
        android:usesCleartextTraffic="false"
        android:networkSecurityConfig="@xml/network_security_config"
        android:dataExtractionRules="@xml/data_extraction_rules"
        android:fullBackupContent="@xml/backup_rules"
        android:enableOnBackInvokedCallback="true">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="nitcbus" android:host="auth-callback" />
            </intent-filter>
        </activity>
    </application>

    <queries>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="https" />
        </intent>
        <intent>
            <action android:name="android.support.customtabs.action.CustomTabsService" />
        </intent>
    </queries>
</manifest>
"""

class TestVerifyAndroidManifest(unittest.TestCase):
    def test_valid_source_manifest(self):
        root = ET.fromstring(VALID_SOURCE_MANIFEST)
        errors = audit_manifest_content(root, is_merged=False)
        self.assertEqual(errors, [])

    def test_missing_cleartext_traffic_fails(self):
        xml_content = VALID_SOURCE_MANIFEST.replace('android:usesCleartextTraffic="false"', '')
        root = ET.fromstring(xml_content)
        errors = audit_manifest_content(root, is_merged=False)
        self.assertTrue(any("usesCleartextTraffic" in err for err in errors))

    def test_missing_exported_attribute_fails(self):
        xml_content = VALID_SOURCE_MANIFEST.replace('android:exported="true"', '')
        root = ET.fromstring(xml_content)
        errors = audit_manifest_content(root, is_merged=False)
        self.assertTrue(any("lacks explicit android:exported" in err for err in errors))

    def test_missing_tools_node_remove_fails(self):
        xml_content = VALID_SOURCE_MANIFEST.replace(
            '<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" tools:node="remove" />',
            ''
        )
        root = ET.fromstring(xml_content)
        errors = audit_manifest_content(root, is_merged=False)
        self.assertTrue(any("ACCESS_BACKGROUND_LOCATION" in err for err in errors))

    def test_unpaired_fine_location_fails(self):
        xml_content = VALID_SOURCE_MANIFEST.replace(
            '<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />',
            ''
        )
        root = ET.fromstring(xml_content)
        errors = audit_manifest_content(root, is_merged=False)
        self.assertTrue(any("ACCESS_COARSE_LOCATION" in err for err in errors))

    def test_missing_oauth_deeplink_fails(self):
        xml_content = VALID_SOURCE_MANIFEST.replace('android:scheme="nitcbus"', 'android:scheme="other"')
        root = ET.fromstring(xml_content)
        errors = audit_manifest_content(root, is_merged=False)
        self.assertTrue(any("nitcbus://auth-callback" in err for err in errors))

    def test_merged_manifest_with_forbidden_permission_fails(self):
        merged_xml = """<?xml version="1.0" encoding="utf-8"?>
        <manifest xmlns:android="http://schemas.android.com/apk/res/android" package="in.ac.nitc.tracklet">
            <uses-permission android:name="android.permission.INTERNET" />
            <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
            <application android:usesCleartextTraffic="false">
                <activity android:name=".MainActivity" android:exported="true" />
            </application>
        </manifest>
        """
        root = ET.fromstring(merged_xml)
        errors = audit_manifest_content(root, is_merged=True)
        self.assertTrue(any("ACCESS_BACKGROUND_LOCATION" in err for err in errors))

    def test_merged_manifest_clean_passes(self):
        merged_xml = """<?xml version="1.0" encoding="utf-8"?>
        <manifest xmlns:android="http://schemas.android.com/apk/res/android" package="in.ac.nitc.tracklet">
            <uses-permission android:name="android.permission.INTERNET" />
            <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
            <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
            <application android:usesCleartextTraffic="false">
                <activity android:name=".MainActivity" android:exported="true" />
            </application>
        </manifest>
        """
        root = ET.fromstring(merged_xml)
        errors = audit_manifest_content(root, is_merged=True)
        self.assertEqual(errors, [])

if __name__ == "__main__":
    unittest.main()
