---
name: setup-repo
description: >-
  Inspect and set up the development environment for this repository.
  Verifies host operating system, Git, Flutter SDK, Dart SDK, desktop/web build
  dependencies (C++, CMake, Ninja, GTK 3, Chrome), resolves pub packages, and validates
  that the minimal development environment (Web or host Native Desktop with full in-app viewport simulation) is functional.
---

# Setup Repository & Development Environment

This skill guides agents and developers through verifying prerequisites, installing dependencies, configuring Flutter, and confirming that the minimal development environment is fully functional.

--------------------------------------------------------------------------------

## 1. Minimal Development Environment Strategy

> [!IMPORTANT]
> **No Mobile Hardware or Emulators Required!**
> This repository ships with an **In-App Device Simulator** (accessible via the header button or Settings) that can simulate and render:
> - ⌚ **Wearable (Wear OS)**: 220×220 circular frame with safe circular padding
> - 📱 **Smartphone**: 390×780 portrait mobile viewport
> - 📖 **Foldable / Tablet**: 720×760 dual-pane layout split along the hinge
> - 🖥️ **Desktop & Web**: 1280×800 adaptive layout with navigation rail
>
> Therefore, the **minimal development environment** requires having **EITHER Web (Chrome / web-server) OR Host Native Desktop (Linux GTK / Windows C++)** working. Once either is running, you can test and develop for all four form factors directly!

--------------------------------------------------------------------------------

## 2. Automated Diagnostic Script

A dedicated helper script is included in this skill to audit all requirements in one command:

```bash
# Run diagnostics (OS, Git, Flutter, Toolchains, Devices, Pub)
bash .agents/skills/setup-repo/scripts/setup_check.sh

# Automatically fix missing Flutter config flags and fetch packages
bash .agents/skills/setup-repo/scripts/setup_check.sh --fix

# Run diagnostics + FSD architectural audit + test suite
bash .agents/skills/setup-repo/scripts/setup_check.sh --verify
```

--------------------------------------------------------------------------------

## 3. Step-by-Step Manual Setup Workflow

Follow these steps when onboarding a new workstation, container, or CI runner.

### Step 1: Detect Host OS and Architecture
Check the host operating system:
```bash
uname -s
uname -m
```
- **Linux**: Target runner is **Linux Desktop** (`-d linux`) or **Web** (`-d chrome`).
- **Windows**: Target runner is **Windows Desktop** (`-d windows`) or **Web** (`-d chrome`).
- **macOS**: Target runner is **macOS Desktop** (`-d macos`) or **Web** (`-d chrome`).

---

### Step 2: Verify Git
Ensure Git is installed and that the working tree is valid:
```bash
git --version
git rev-parse --is-inside-work-tree
```
If Git is missing:
- **Debian/Ubuntu**: `sudo apt install git`
- **Fedora**: `sudo dnf install git`
- **Arch**: `sudo pacman -S git`
- **Windows**: Install Git for Windows (`winget install Git.Git`)

#### Configure Pre-Commit Hook
Activate the repository's pre-commit hook (which prevents commits when AST static analysis or FSD architecture rules fail):
```bash
git config core.hooksPath .githooks
chmod +x .githooks/pre-commit
```

---

### Step 3: Verify Flutter & Dart SDKs
Ensure Flutter and Dart are in PATH and satisfy SDK constraints (`sdk: ^3.13.2`):
```bash
flutter --version
dart --version
flutter doctor -v
```
If Flutter is missing, download Flutter stable from [flutter.dev](https://docs.flutter.dev/get-started/install).

---

### Step 4: Verify Platform Development Toolchains

#### For Linux Host (Native Desktop):
Verify C++ build tools and GTK 3 headers:
```bash
# Check C++ compiler, CMake, Ninja, and GTK 3 pkg-config
command -v clang || command -v gcc
cmake --version
ninja --version || ninja-build --version
pkg-config --exists gtk+-3.0 && echo "GTK3 OK"
```
If missing, install distribution packages:
- **Debian / Ubuntu**:
  ```bash
  sudo apt update && sudo apt install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev
  ```
- **Fedora**:
  ```bash
  sudo dnf install -y clang cmake ninja-build pkgconf-pkg-config gtk3-devel xz-devel
  ```
- **Arch Linux**:
  ```bash
  sudo pacman -Syu --needed clang cmake ninja pkgconf gtk3
  ```

#### For Windows Host (Native Desktop):
Ensure Visual Studio 2022 with **"Desktop development with C++"** workload is installed:
```powershell
winget install Microsoft.VisualStudio.2022.BuildTools --override "--passive --wait --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
```

#### For Web (Chrome / Headless):
Verify Google Chrome or Chromium:
```bash
command -v google-chrome || command -v chromium || echo "Chrome not in PATH"
```
If running in a headless Linux environment (WSL, Docker, remote SSH), use `flutter run -d web-server --web-port=8080` or export `CHROME_EXECUTABLE`.

---

### Step 5: Enable Target Platforms in Flutter
Enable the host desktop and web targets:
```bash
# On Linux:
flutter config --enable-linux-desktop

# On Windows:
flutter config --enable-windows-desktop

# Web:
flutter config --enable-web
```
Confirm the available targets:
```bash
flutter devices
```

---

### Step 6: Install Project Dependencies
Fetch Dart and Flutter pub dependencies:
```bash
flutter pub get
```
Verify that `.dart_tool/package_config.json` was generated.

---

### Step 7: Launch & Validate Minimal Environment

Launch the application on your available target:

**Option A: Linux Desktop**
```bash
flutter run -d linux
```
*(Or use `./launch_app.sh` which checks release/debug builds automatically)*

**Option B: Web**
```bash
flutter run -d chrome
# Or headless / server mode:
flutter run -d web-server --web-port=8080 --web-hostname=0.0.0.0
```

**Option C: Windows Desktop**
```bash
flutter run -d windows
```

Once running, verify:
1. The app displays the **Overview** dashboard.
2. Click the device switcher in the header or in **Settings** (`Ctrl+3`).
3. Switch through each tier:
   - **Watch (Wear OS)**: Verify circular padding and high-contrast watch view.
   - **Smartphone**: Verify compact column layout and bottom navigation.
   - **Foldable**: Verify dual-pane master-detail view.
   - **Desktop / Web**: Verify navigation rail and keyboard shortcuts (`Ctrl+1`, `Ctrl+2`, `Ctrl+3`).

---

### Step 8: Verify Architectural Integrity & Tests
Run static checks and automated tests before making or committing changes:
```bash
# 1. Feature-Sliced Design (FSD v2.1) strict audit
dart run tool/verify_fsd.dart --strict

# 2. Static analysis
flutter analyze

# 3. Unit, widget, and architecture tests
flutter test
```

--------------------------------------------------------------------------------

## 4. References & Related Guides

- [Platform Requirements Reference](./references/platform-requirements.md): Detailed package lists, build commands, and platform quirks.
- [Form Factors & Multi-Device Guidelines](../../rules/form-factors.md): Architectural rules for the 4 supported screen tiers.
- [Architecture Guidelines](../../rules/architecture.md): FSD v2.1 layer hierarchy and cross-slice isolation rules.
