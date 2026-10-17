#!/usr/bin/env python3
"""
Generate App Icons, Favicons, Android Adaptive Icons & Backgrounds from Brand Assets.

Processes:
- assets/branding/app_launcher_icon.png (512x512)
- assets/branding/adaptive_foreground_icon.png (432x432)
- assets/branding/bustracker_bus_icon.png (726x726)
- assets/branding/ic_notification.png (96x96)

Outputs:
1. Android:
   - res/values/colors.xml (ic_launcher_background & tracklet_primary: #6F61EF)
   - res/drawable/ic_launcher_background.xml (solid #6F61EF background)
   - res/mipmap-anydpi-v26/ic_launcher.xml (Adaptive icon definition)
   - res/mipmap-anydpi-v26/ic_launcher_round.xml (Adaptive round icon definition)
   - res/mipmap-{density}/ic_launcher_foreground.png (108, 162, 216, 324, 432)
   - res/mipmap-{density}/ic_launcher_monochrome.png (108, 162, 216, 324, 432)
   - res/mipmap-{density}/ic_launcher.png (48, 72, 96, 144, 192)
   - res/mipmap-{density}/ic_launcher_round.png (48, 72, 96, 144, 192)
   - res/drawable-{density}/ic_notification.png (24, 36, 48, 72, 96)
2. Web:
   - web/favicon.png (32x32)
   - web/favicon-16x16.png (16x16)
   - web/favicon-32x32.png (32x32)
   - web/favicon.ico (16, 32, 48)
   - web/apple-touch-icon.png (180x180)
   - web/icons/Icon-192.png (192x192)
   - web/icons/Icon-512.png (512x512)
   - web/icons/Icon-maskable-192.png (192x192)
   - web/icons/Icon-maskable-512.png (512x512)
3. In-App Assets:
   - assets/images/app_launcher_icon.png (512x512)
   - assets/images/adaptive_foreground_icon.png (432x432)
   - assets/images/favicon.png (128x128)
"""

import os
import sys
from PIL import Image, ImageDraw

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BRANDING_DIR = os.path.join(PROJECT_ROOT, "assets", "branding")
RES_DIR = os.path.join(PROJECT_ROOT, "android", "app", "src", "main", "res")
WEB_DIR = os.path.join(PROJECT_ROOT, "web")
IMAGES_DIR = os.path.join(PROJECT_ROOT, "assets", "images")

PRIMARY_COLOR = (111, 97, 239, 255)  # #6F61EF
PRIMARY_HEX = "#6F61EF"

DENSITIES = {
    "mdpi": {
        "launcher": 48,
        "foreground": 108,
        "notification": 24,
    },
    "hdpi": {
        "launcher": 72,
        "foreground": 162,
        "notification": 36,
    },
    "xhdpi": {
        "launcher": 96,
        "foreground": 216,
        "notification": 48,
    },
    "xxhdpi": {
        "launcher": 144,
        "foreground": 324,
        "notification": 72,
    },
    "xxxhdpi": {
        "launcher": 192,
        "foreground": 432,
        "notification": 96,
    },
}

def make_circular_masked_image(source: Image.Image, size: int) -> Image.Image:
    """Create a round icon by antialiased circular masking."""
    resized = source.resize((size, size), Image.Resampling.LANCZOS)
    
    # 4x supersampled mask for clean subpixel edges
    supersample = 4
    large_size = size * supersample
    mask = Image.new("L", (large_size, large_size), 0)
    draw = ImageDraw.Draw(mask)
    draw.ellipse((0, 0, large_size - 1, large_size - 1), fill=255)
    mask = mask.resize((size, size), Image.Resampling.LANCZOS)

    result = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    result.paste(resized, (0, 0))
    
    # Merge existing alpha with circular mask
    r, g, b, a = result.split()
    final_a = Image.new("L", (size, size), 0)
    # Combine alpha channels
    combined_mask = Image.new("L", (size, size), 0)
    for y in range(size):
        for x in range(size):
            alpha_val = int((a.getpixel((x, y)) * mask.getpixel((x, y))) / 255)
            final_a.putpixel((x, y), alpha_val)
    result.putalpha(final_a)
    return result

def make_monochrome_foreground(fg_image: Image.Image, size: int) -> Image.Image:
    """Generate pure white monochrome silhouette for Android 13+ Material You themed icons."""
    resized = fg_image.resize((size, size), Image.Resampling.LANCZOS)
    r, g, b, a = resized.split()
    mono = Image.new("RGBA", (size, size), (255, 255, 255, 255))
    mono.putalpha(a)
    return mono

def make_maskable_pwa_icon(fg_image: Image.Image, size: int) -> Image.Image:
    """
    Generate W3C-compliant maskable PWA icon with safe margin on #6F61EF background.
    Safe zone is 80% circle, perfectly filled by the 66.7% adaptive foreground.
    """
    bg = Image.new("RGBA", (size, size), PRIMARY_COLOR)
    resized_fg = fg_image.resize((size, size), Image.Resampling.LANCZOS)
    bg.alpha_composite(resized_fg)
    return bg

def main():
    print("==> Generating Brand Icons, Adaptive Layers, Favicons, and PWA Assets...")

    # Load source icons
    app_icon_src = Image.open(os.path.join(BRANDING_DIR, "app_launcher_icon.png")).convert("RGBA")
    adaptive_fg_src = Image.open(os.path.join(BRANDING_DIR, "adaptive_foreground_icon.png")).convert("RGBA")
    bus_icon_src = Image.open(os.path.join(BRANDING_DIR, "bustracker_bus_icon.png")).convert("RGBA")
    notification_src = Image.open(os.path.join(BRANDING_DIR, "ic_notification.png")).convert("RGBA")

    # 1. Android XML Resources
    values_dir = os.path.join(RES_DIR, "values")
    os.makedirs(values_dir, exist_ok=True)
    colors_xml_path = os.path.join(values_dir, "colors.xml")
    with open(colors_xml_path, "w", encoding="utf-8") as f:
        f.write('<?xml version="1.0" encoding="utf-8"?>\n')
        f.write('<resources>\n')
        f.write(f'    <color name="ic_launcher_background">{PRIMARY_HEX}</color>\n')
        f.write(f'    <color name="tracklet_primary">{PRIMARY_HEX}</color>\n')
        f.write('</resources>\n')
    print(f"  ✓ Written: {colors_xml_path}")

    drawable_dir = os.path.join(RES_DIR, "drawable")
    os.makedirs(drawable_dir, exist_ok=True)
    bg_drawable_path = os.path.join(drawable_dir, "ic_launcher_background.xml")
    with open(bg_drawable_path, "w", encoding="utf-8") as f:
        f.write('<?xml version="1.0" encoding="utf-8"?>\n')
        f.write('<shape xmlns:android="http://schemas.android.com/apk/res/android"\n')
        f.write('    android:shape="rectangle">\n')
        f.write('    <solid android:color="@color/ic_launcher_background" />\n')
        f.write('</shape>\n')
    print(f"  ✓ Written: {bg_drawable_path}")

    # Adaptive Icon XMLs for API 26+
    anydpi_dir = os.path.join(RES_DIR, "mipmap-anydpi-v26")
    os.makedirs(anydpi_dir, exist_ok=True)
    
    adaptive_xml = (
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@drawable/ic_launcher_background" />\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground" />\n'
        '    <monochrome android:drawable="@mipmap/ic_launcher_monochrome" />\n'
        '</adaptive-icon>\n'
    )
    with open(os.path.join(anydpi_dir, "ic_launcher.xml"), "w", encoding="utf-8") as f:
        f.write(adaptive_xml)
    with open(os.path.join(anydpi_dir, "ic_launcher_round.xml"), "w", encoding="utf-8") as f:
        f.write(adaptive_xml)
    print(f"  ✓ Written: {anydpi_dir}/ic_launcher.xml & ic_launcher_round.xml")

    # 2. Android Mipmap & Drawable Density Folders
    for density, specs in DENSITIES.items():
        mipmap_folder = os.path.join(RES_DIR, f"mipmap-{density}")
        drawable_folder = os.path.join(RES_DIR, f"drawable-{density}")
        os.makedirs(mipmap_folder, exist_ok=True)
        os.makedirs(drawable_folder, exist_ok=True)

        # Legacy launcher icon (ic_launcher.png)
        launcher_size = specs["launcher"]
        launcher_img = app_icon_src.resize((launcher_size, launcher_size), Image.Resampling.LANCZOS)
        launcher_img.save(os.path.join(mipmap_folder, "ic_launcher.png"), "PNG")

        # Round launcher icon (ic_launcher_round.png)
        round_img = make_circular_masked_image(app_icon_src, launcher_size)
        round_img.save(os.path.join(mipmap_folder, "ic_launcher_round.png"), "PNG")

        # Adaptive foreground (ic_launcher_foreground.png)
        fg_size = specs["foreground"]
        fg_img = adaptive_fg_src.resize((fg_size, fg_size), Image.Resampling.LANCZOS)
        fg_img.save(os.path.join(mipmap_folder, "ic_launcher_foreground.png"), "PNG")

        # Monochrome foreground for Material You (ic_launcher_monochrome.png)
        mono_img = make_monochrome_foreground(adaptive_fg_src, fg_size)
        mono_img.save(os.path.join(mipmap_folder, "ic_launcher_monochrome.png"), "PNG")

        # Notification icon (ic_notification.png) as pure white silhouette for Android status bar
        notif_size = specs["notification"]
        notif_img = make_monochrome_foreground(bus_icon_src, notif_size)
        notif_img.save(os.path.join(drawable_folder, "ic_notification.png"), "PNG")

        print(f"  ✓ Android {density}: launcher ({launcher_size}px), fg ({fg_size}px), round, mono, notif ({notif_size}px)")

    # Save default fallback notification icon in drawable/
    notif_default = make_monochrome_foreground(bus_icon_src, 48)
    notif_default.save(os.path.join(drawable_dir, "ic_notification.png"), "PNG")
    notif_brand = make_monochrome_foreground(bus_icon_src, 96)
    notif_brand.save(os.path.join(BRANDING_DIR, "ic_notification.png"), "PNG")
    print("  ✓ Android: default ic_notification.png written to drawable/ and assets/branding/")

    # 3. Web Assets (Favicons using Bus Logo, Touch Icons & PWA Icons)
    web_icons_dir = os.path.join(WEB_DIR, "icons")
    os.makedirs(web_icons_dir, exist_ok=True)

    # Standard favicon (32x32) generated from Bus Logo
    fav_32 = bus_icon_src.resize((32, 32), Image.Resampling.LANCZOS)
    fav_32.save(os.path.join(WEB_DIR, "favicon.png"), "PNG")

    # Additional standard favicon sizes generated from Bus Logo
    fav_16 = bus_icon_src.resize((16, 16), Image.Resampling.LANCZOS)
    fav_16.save(os.path.join(WEB_DIR, "favicon-16x16.png"), "PNG")
    fav_32.save(os.path.join(WEB_DIR, "favicon-32x32.png"), "PNG")

    # Multi-resolution favicon.ico (16, 32, 48) generated from Bus Logo
    fav_48 = bus_icon_src.resize((48, 48), Image.Resampling.LANCZOS)
    fav_48.save(
        os.path.join(WEB_DIR, "favicon.ico"),
        format="ICO",
        sizes=[(16, 16), (32, 32), (48, 48)],
    )

    # Apple touch icon (180x180) generated from Bus Logo
    apple_touch = bus_icon_src.resize((180, 180), Image.Resampling.LANCZOS)
    apple_touch.save(os.path.join(WEB_DIR, "apple-touch-icon.png"), "PNG")

    # PWA icons generated from Bus Logo
    icon_192 = bus_icon_src.resize((192, 192), Image.Resampling.LANCZOS)
    icon_192.save(os.path.join(web_icons_dir, "Icon-192.png"), "PNG")

    icon_512 = bus_icon_src.resize((512, 512), Image.Resampling.LANCZOS)
    icon_512.save(os.path.join(web_icons_dir, "Icon-512.png"), "PNG")

    # PWA Maskable icons (with 80% safe zone on #6F61EF)
    maskable_192 = make_maskable_pwa_icon(adaptive_fg_src, 192)
    maskable_192.save(os.path.join(web_icons_dir, "Icon-maskable-192.png"), "PNG")

    maskable_512 = make_maskable_pwa_icon(adaptive_fg_src, 512)
    maskable_512.save(os.path.join(web_icons_dir, "Icon-maskable-512.png"), "PNG")

    print("  ✓ Web: favicon.png (32px), favicon.ico (16, 32, 48), apple-touch-icon.png (180px) using Bus Logo")
    print("  ✓ Web PWA: Icon-192, Icon-512 using Bus Logo, Icon-maskable-192, Icon-maskable-512")

    # 4. In-App Assets Synchronization
    os.makedirs(IMAGES_DIR, exist_ok=True)
    app_icon_src.save(os.path.join(IMAGES_DIR, "app_launcher_icon.png"), "PNG")
    adaptive_fg_src.save(os.path.join(IMAGES_DIR, "adaptive_foreground_icon.png"), "PNG")
    
    # In-app favicon image (128x128 for crisp rendering inside login and other screens)
    fav_128 = bus_icon_src.resize((128, 128), Image.Resampling.LANCZOS)
    fav_128.save(os.path.join(IMAGES_DIR, "favicon.png"), "PNG")

    print("  ✓ In-App Assets: synchronized app_launcher_icon, adaptive_foreground_icon, and favicon.png")
    print("==> All brand icons successfully generated!")

if __name__ == "__main__":
    main()
