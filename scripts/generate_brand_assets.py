from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageOps


ROOT = Path(__file__).resolve().parents[1]
APP_ICON_SOURCE = ROOT / "UI设计" / "Windows" / "notification_icon.png"
TRAY_ICON_SOURCE = ROOT / "UI设计" / "ios桌面端设计原型图" / "IOS挂起图标.png"
UPDATE_TRAY_ASSETS = False

APP_BACKGROUND_COLOR = "#F5F7FF"
TRAY_LIGHT_COLOR = (255, 255, 255)
TRAY_DARK_COLOR = (30, 41, 59)


def ensure_parent(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)


def save_png(image: Image.Image, path: Path) -> None:
    ensure_parent(path)
    image.save(path, format="PNG")


def save_ico(image: Image.Image, path: Path) -> None:
    ensure_parent(path)
    image.save(path, format="ICO", sizes=[(16, 16), (24, 24), (32, 32), (40, 40), (48, 48), (64, 64), (128, 128), (256, 256)])


def save_webp(image: Image.Image, path: Path) -> None:
    ensure_parent(path)
    image.save(path, format="WEBP", lossless=True, method=6)


def resize_square(source: Image.Image, size: int) -> Image.Image:
    return source.resize((size, size), Image.Resampling.LANCZOS)


def compose_centered(source: Image.Image, canvas_size: tuple[int, int], padding_ratio: float, background: tuple[int, int, int, int]) -> Image.Image:
    canvas = Image.new("RGBA", canvas_size, background)
    max_width = max(1, int(canvas_size[0] * (1 - padding_ratio * 2)))
    max_height = max(1, int(canvas_size[1] * (1 - padding_ratio * 2)))
    fitted = ImageOps.contain(source, (max_width, max_height), Image.Resampling.LANCZOS)
    x = (canvas_size[0] - fitted.width) // 2
    y = (canvas_size[1] - fitted.height) // 2
    canvas.alpha_composite(fitted, (x, y))
    return canvas


def make_tray_glyph(source: Image.Image, color: tuple[int, int, int], padding_ratio: float = 0.08) -> Image.Image:
    gray = ImageOps.grayscale(source)
    alpha = gray.point(lambda value: value)
    solid = Image.new("RGBA", source.size, color + (0,))
    solid.putalpha(alpha)
    bbox = alpha.point(lambda value: 255 if value > 12 else 0).getbbox()
    cropped = solid.crop(bbox) if bbox else solid
    return compose_centered(cropped, (256, 256), padding_ratio, (0, 0, 0, 0))


def make_adaptive_icon(source: Image.Image, size: int, padding_ratio: float = 0.16) -> Image.Image:
    return compose_centered(source, (size, size), padding_ratio, (0, 0, 0, 0))


def write_text(path: Path, content: str) -> None:
    ensure_parent(path)
    path.write_text(content, encoding="utf-8")


def generate_logo_svg(path: Path) -> None:
    svg = """<svg width="64" height="64" viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg">
<rect x="8" y="9" width="6" height="46" rx="1.5" fill="#FFFFFF"/>
<rect x="18" y="9" width="6" height="46" rx="1.5" fill="#FFFFFF"/>
<rect x="28" y="9" width="6" height="21" rx="1.5" fill="#FFFFFF"/>
<path d="M10 55C10 35.5 25.2 18.4 48.8 11.8" stroke="#FFFFFF" stroke-width="6" stroke-linecap="round"/>
<path d="M21.5 55C21.5 38.8 33.4 25.4 50.8 20.2" stroke="#FFFFFF" stroke-width="6" stroke-linecap="round"/>
<path d="M33.5 55C33.5 42.4 42.4 32.7 54.5 28.2" stroke="#FFFFFF" stroke-width="6" stroke-linecap="round"/>
<path d="M45.5 55C45.5 48.6 50.1 41.8 57.5 37.2" stroke="#FFFFFF" stroke-width="6" stroke-linecap="round"/>
</svg>
"""
    write_text(path, svg)


def generate_android_foreground_xml(path: Path, drawable_name: str) -> None:
    content = f"""<bitmap xmlns:android="http://schemas.android.com/apk/res/android"
    android:gravity="center"
    android:src="@drawable/{drawable_name}" />
"""
    write_text(path, content)


def generate_color_xml(path: Path, color_name: str, color_value: str) -> None:
    content = f"""<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="{color_name}">{color_value}</color>
</resources>
"""
    write_text(path, content)


def overwrite_existing_pngs(directory: Path, source: Image.Image) -> None:
    for png_path in directory.rglob("*.png"):
        existing = Image.open(png_path)
        if existing.width == existing.height:
            output = resize_square(source, existing.width)
        else:
            output = compose_centered(source, existing.size, 0.18, (0, 0, 0, 0))
        save_png(output, png_path)


def main() -> None:
    app_icon = Image.open(APP_ICON_SOURCE).convert("RGBA")
    tray_source = Image.open(TRAY_ICON_SOURCE).convert("RGBA")

    tray_light = make_tray_glyph(tray_source, TRAY_LIGHT_COLOR)
    tray_dark = make_tray_glyph(tray_source, TRAY_DARK_COLOR)
    adaptive_foreground = make_adaptive_icon(app_icon, 432)
    banner_foreground = compose_centered(app_icon, (640, 360), 0.24, (0, 0, 0, 0))
    banner_raster = compose_centered(app_icon, (320, 180), 0.18, (245, 247, 255, 255))
    stat_icon = compose_centered(tray_light, (96, 96), 0.18, (0, 0, 0, 0))

    for path in [
        ROOT / "assets" / "images" / "app_icon_splash.png",
        ROOT / "assets" / "images" / "source" / "ic_launcher_border.png",
        ROOT / "assets" / "images" / "source" / "ic_launcher_splash.png",
        ROOT / "assets" / "images" / "source" / "ic_launcher_foreground.png",
    ]:
        save_png(resize_square(app_icon, 1024 if "splash" in path.name or "border" in path.name else 432), path)

    save_png(compose_centered(tray_light, (256, 256), 0.18, (0, 0, 0, 0)), ROOT / "assets" / "images" / "source" / "ic_notify.png")

    generate_logo_svg(ROOT / "assets" / "images" / "logo.svg")

    save_ico(resize_square(app_icon, 256), ROOT / "windows" / "runner" / "resources" / "app_icon.ico")
    save_ico(resize_square(app_icon, 256), ROOT / "assets" / "images" / "source" / "hiddify.ico")

    if UPDATE_TRAY_ASSETS:
        tray_targets = {
            "tray_icon": tray_light,
            "tray_icon_connected": tray_light,
            "tray_icon_disconnected": tray_light,
            "tray_icon_dark": tray_dark,
        }
        for name, image in tray_targets.items():
            save_png(image, ROOT / "assets" / "images" / f"{name}.png")
            save_ico(image, ROOT / "assets" / "images" / f"{name}.ico")
            if name != "tray_icon_dark":
                save_png(image, ROOT / "assets" / "images" / "source" / f"{name}.png")

    overwrite_existing_pngs(ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset", app_icon)
    overwrite_existing_pngs(ROOT / "macos" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset", app_icon)

    android_root = ROOT / "android" / "app" / "src" / "main"
    mipmap_sizes = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    for folder, size in mipmap_sizes.items():
        launcher = resize_square(app_icon, size)
        save_webp(launcher, android_root / "res" / folder / "ic_launcher.webp")
        save_webp(launcher, android_root / "res" / folder / "ic_launcher_round.webp")

    save_png(resize_square(app_icon, 512), android_root / "ic_launcher-playstore.png")
    save_png(banner_raster, android_root / "res" / "mipmap-xhdpi" / "ic_banner.png")
    save_png(resize_square(app_icon, 192), android_root / "res" / "drawable-xxxhdpi" / "splash.png")
    save_png(adaptive_foreground, android_root / "res" / "drawable" / "ic_launcher_foreground_png.png")
    save_png(banner_foreground, android_root / "res" / "drawable" / "ic_banner_foreground_png.png")
    save_png(resize_square(stat_icon, 72), android_root / "res" / "drawable-hdpi" / "ic_stat_logo.png")
    save_png(resize_square(stat_icon, 48), android_root / "res" / "drawable-mdpi" / "ic_stat_logo.png")

    generate_android_foreground_xml(android_root / "res" / "drawable" / "ic_launcher_foreground.xml", "ic_launcher_foreground_png")
    generate_android_foreground_xml(android_root / "res" / "drawable" / "ic_banner_foreground.xml", "ic_banner_foreground_png")
    generate_color_xml(android_root / "res" / "values" / "ic_launcher_background.xml", "ic_launcher_background", APP_BACKGROUND_COLOR)
    generate_color_xml(android_root / "res" / "values" / "ic_banner_background.xml", "ic_banner_background", APP_BACKGROUND_COLOR)


if __name__ == "__main__":
    main()
