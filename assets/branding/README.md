# Broiler Farm branding pack

## Colours
| Use | Hex |
|-----|-----|
| Primary (terracotta) | `#B2472D` |
| Background (cream) | `#F1EBDD` |
| Text (dark brown) | `#4A3A2F` |
| Secondary (grey-brown, from the logo) | `#756B5D` |
| Android adaptive icon background | `#B2472D` |
| Splash background | `#F1EBDD` |
| Splash background, dark mode (optional) | `#2B2019` |

The dark splash colour `#2B2019` is my suggestion (a darker version of the text brown). The others come from your logo files.

## Files
**master/**
- `logo_mark.svg`: square mark only, transparent. Source for everything else.
- `logo_full.svg` / `logo_full.png`: mark + name, horizontal, transparent, 1600 px wide. For landing page header and login screens.
- `logo_vertical.svg` / `.png`: extra, stacked version (not in your list).

**android/**
- `app_icon.png`: 1024x1024, opaque. Standard launcher icon.
- `app_icon_foreground.png`: 1024x1024, transparent, mark inside the middle 66%. Adaptive icon.
- `app_icon_monochrome.png`: 1024x1024, transparent, one solid colour. Themed icon (Android 13+).

**splash/**
- `splash_logo.png`: 1152x1152, transparent, mark inside the central 768 px circle. Use on the cream background.
- `splash_logo_dark.png`: same, but cream mark for the dark splash background (optional).

**web/**
- `favicon.png` (32x32), `favicon-48.png` (48x48)
- `Icon-192.png`, `Icon-512.png`
- `Icon-maskable-192.png`, `Icon-maskable-512.png` (solid background, mark inside the central 80%)
- `apple-touch-icon.png` (180x180, opaque)

**social/**
- `og-image.png`: 1200x630, about 64 KB. Link preview for WhatsApp, Facebook, LinkedIn, X.

## Flutter setup (copy the files into `assets/branding/` first)
```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/branding/app_icon.png"
  adaptive_icon_background: "#B2472D"
  adaptive_icon_foreground: "assets/branding/app_icon_foreground.png"
  adaptive_icon_monochrome: "assets/branding/app_icon_monochrome.png"
  remove_alpha_ios: true

flutter_native_splash:
  color: "#F1EBDD"
  image: assets/branding/splash_logo.png
  color_dark: "#2B2019"
  image_dark: assets/branding/splash_logo_dark.png
  android_12:
    color: "#F1EBDD"
    image: assets/branding/splash_logo.png
```
Then run:
```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```
For the website, copy the files in `web/` into your Flutter `web/` folder (`web/favicon.png` and `web/icons/`), and put `og-image.png` where your `index.html` can link to it.

## Notes
- The text in `logo_full` and `logo_vertical` was converted to shapes, so it looks the same everywhere without needing the Nexa fonts.
- Everything was made from your SVG files. If you change the logo, send the new SVG and the files can be rebuilt.
