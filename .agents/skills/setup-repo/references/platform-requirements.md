# Platform Requirements & Environment Reference

This document outlines the system requirements, development packages, and runtime targets for the `agentic_template` repository.

---

## 1. Minimal Development Environment Strategy

The repository includes an **in-app device simulator** (`Auto Detect`, `Watch (Wear OS) 220×220`, `Smartphone 390×780`, `Foldable 720×760`, `Desktop/Web 1280×800`).

```
┌────────────────────────────────────────────────────────────────────────┐
│                   In-App Multi-Device Simulator                        │
│                                                                        │
│   ┌───────────────┐  ┌───────────────┐  ┌───────────────────────────┐  │
│   │ Wearable      │  │ Smartphone    │  │ Foldable / Tablet         │  │
│   │ 220×220 Round │  │ 390×780       │  │ 720×760 Dual-Pane         │  │
│   └───────────────┘  └───────────────┘  └───────────────────────────┘  │
│                                                                        │
│   Host Runners: Linux Desktop (GTK) OR Windows Desktop OR Web (Chrome) │
└────────────────────────────────────────────────────────────────────────┘
```

> [!TIP]
> **You do NOT need an Android phone, Wear OS smartwatch, emulator, or Xcode** to build and test features for all four tiers.
> Having **either Web or host Native Desktop** installed and working provides 100% functional testability of the entire UI and architecture!

---

## 2. Operating System & Toolchain Prerequisites

### Core Tooling (All Platforms)
- **Git**: `>= 2.20`
- **Flutter SDK**: `>= 3.13.2` (channel `stable` recommended, CI runs `3.47.4`)
- **Dart SDK**: bundled with Flutter (`sdk: ^3.13.2`)

---

### Linux (Host Desktop Runner)

To build and run native Linux GTK applications (`flutter run -d linux`):

#### Required Packages
- C++ Compiler (`clang` or `gcc`/`g++`)
- `cmake` (`>= 3.10`)
- `ninja-build` / `ninja`
- `pkg-config`
- `libgtk-3-dev` (GTK 3 headers and libraries)
- `liblzma-dev` (compression support)

#### Distribution Installation Commands

**Debian / Ubuntu / Linux Mint / Pop!_OS:**
```bash
sudo apt update
sudo apt install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev
```

**Fedora / RHEL / CentOS Stream:**
```bash
sudo dnf install -y clang cmake ninja-build pkgconf-pkg-config gtk3-devel xz-devel
```

**Arch Linux / Manjaro:**
```bash
sudo pacman -Syu --needed clang cmake ninja pkgconf gtk3
```

**openSUSE:**
```bash
sudo zypper install -y clang cmake ninja pkg-config gtk3-devel
```

---

### Windows (Host Desktop Runner)

To build and run native Windows desktop applications (`flutter run -d windows`):

#### Required Workload
- **Visual Studio 2022** (Community, Professional, or Build Tools)
- Workload: **"Desktop development with C++"**
  - Includes: MSVC v143 toolset, Windows 10/11 SDK, C++ CMake tools for Windows

#### Automated Installation via CLI
```powershell
# Using winget
winget install --id Microsoft.VisualStudio.2022.Community --override "--passive --wait --add Microsoft.VisualStudio.Workload.NativeDesktop --includeRecommended"

# Or with VS Build Tools
winget install --id Microsoft.VisualStudio.2022.BuildTools --override "--passive --wait --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
```

---

### Web (Chrome / Headless Runner)

To build and run Web applications (`flutter run -d chrome` or WASM build):

- **Google Chrome** or **Chromium** installed.
- In WSL or remote environments where no GUI display is attached:
  - Use `flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0`
  - Or set `export CHROME_EXECUTABLE=/usr/bin/chromium` (or path to Chrome/Chromium).
- For production Web builds (`bash build_web.sh`):
  - Requires `gzip` utility for static asset pre-compression.

---

## 3. Flutter Configuration Commands

Ensure your desired desktop and web targets are enabled in Flutter's global configuration:

```bash
# Enable Linux desktop
flutter config --enable-linux-desktop

# Enable Windows desktop
flutter config --enable-windows-desktop

# Enable Web
flutter config --enable-web
```

Verify available target devices:
```bash
flutter devices
```

---

## 4. Repo Verification & Quality Checks

Run these commands after setting up to verify environment health:

```bash
# 1. Fetch Dart packages
flutter pub get

# 2. Check architecture compliance (strict FSD v2.1)
dart run tool/verify_fsd.dart --strict

# 3. Analyze code quality
flutter analyze

# 4. Run test suite
flutter test
```

---

## 5. Common Troubleshooting

| Issue | Cause | Resolution |
|---|---|---|
| `CMake Error: Could not find package configuration file provided by "PkgConfig"` | Missing `pkg-config` | Install `pkg-config` (e.g. `sudo apt install pkg-config`) |
| `fatal error: gtk/gtk.h: No such file or directory` | Missing GTK 3 development headers | Install `libgtk-3-dev` (Debian/Ubuntu) or `gtk3-devel` (Fedora/openSUSE) |
| `No supported devices connected` | Platform target not enabled or missing runner | Run `flutter config --enable-<linux|windows|web>` and check `flutter devices` |
| `Cannot find Chrome` | Chrome not in standard PATH | Set `export CHROME_EXECUTABLE=/path/to/google-chrome` or use `-d web-server` |
| `WindowControlService drag/resize unresponsive` | Wayland compositor active | Linux custom title bar pointer grab works on X11; Wayland handles window actions natively |
