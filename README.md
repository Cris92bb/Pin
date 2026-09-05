# <p align="center"><img src="assets/icons/pin.png" width="64" height="64" alt="Pin Icon" valign="middle" /><br>Pin</p>

<p align="center">
  <strong>A minimalist, high-focus companion Kanban desktop app built for Linux.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Platform-Linux%20(GTK)-E95420?logo=linux&logoColor=white" alt="Linux" />
  <img src="https://img.shields.io/badge/Architecture-Riverpod-blueviolet" alt="Riverpod" />
  <img src="https://img.shields.io/badge/Storage-Local--First%20(Offline)-green" alt="Local-First" />
</p>

---

## 📌 Overview

**Pin** is a companion Kanban application tailored for power users, developers, and writers on Linux desktop environments (such as GNOME). 

Designed to sit snugly alongside your IDE, terminal, or web browser, **Pin** adopts a **companion layout** (fixed 430px width, height-only resizing, and full monitor workarea default height) so you never lose context while organizing your workload.

![Pin Screenshot](screenshot.png)

---

## ✨ Features

- **🗂️ Layered Deck Kanban**:
  - Three intuitive, full-width drawers: **Backlog**, **In Progress**, and **Done**.
  - One-click toggling and seamless animated transitions between layers.
- **⚡ Atomic Steps & Task Breakdown**:
  - Decompose large cards into actionable, bite-sized micro-steps.
  - Interactive checklists with real-time completion progress indicators.
- **🎯 Focus Mode**:
  - Single-task immersion view designed to eliminate visual clutter.
  - Integrated timer, step-by-step checklist, and one-tap task completion.
- **🎨 System Theme Integration**:
  - Automatically matches system dark or light theme preferences via real-time GNOME / system observer.
  - Manual override toggle available in the header menu.
- **🪟 Custom Frameless Window**:
  - Frameless, modern interface without bulky OS title bars.
  - Custom draggable header bar for effortless positioning.
  - Vertical-only edge resizing locked to companion width (430px).
- **💾 Local-First & Private**:
  - 100% offline, stored locally via `SharedPreferences`.
  - Zero cloud dependencies, accounts, tracking, or telemetry.
- **📤 Export & Import**:
  - Full JSON backup and restore capabilities for data safety and cross-machine migration.
- **🐧 Native Linux Integration**:
  - GNOME Application Menu (`.desktop`) integration.
  - Multi-resolution hicolor icon assets (`16x16` through `512x512`).
  - Intelligent launcher script that auto-detects and launches the latest build.

---

## ⌨️ Keyboard Shortcuts

| Shortcut | Action |
| :--- | :--- |
| <kbd>Ctrl</kbd> + <kbd>N</kbd> | Create a new task |
| <kbd>Ctrl</kbd> + <kbd>Q</kbd> / <kbd>Ctrl</kbd> + <kbd>W</kbd> | Exit application |
| <kbd>1</kbd> / <kbd>2</kbd> / <kbd>3</kbd> | Switch to Backlog / In Progress / Done drawer |
| <kbd>Esc</kbd> | Close open modals / drawer |

---

## 🏗️ Architecture & Project Structure

Pin follows a feature-first and entity-driven architecture powered by **Flutter Riverpod**:

```
Pin/
├── assets/
│   └── icons/                 # High-resolution pushpin icon assets
├── build_release.sh           # Helper script to build release bundle
├── launch_pin.sh              # Auto-detect launcher (release vs debug)
├── pin.desktop                # XDG desktop shortcut definition
├── linux/
│   └── runner/
│       ├── main.cc
│       └── my_application.cc  # GTK window customization (frameless, drag, resize, theme channels)
├── lib/
│   ├── main.dart              # Application entry point
│   ├── app/                   # App-wide routing, configuration & theme tokens
│   ├── entities/
│   │   ├── task/              # PinTask entity, state notifier & repository
│   │   └── atomic_step/       # Micro-step models and widgets
│   ├── features/
│   │   ├── focus_mode/        # Deep-focus immersion view and timer
│   │   ├── task_crud/         # Task creation, editing & priority tags
│   │   └── task_export_import/# JSON export & import tools
│   ├── pages/
│   │   └── home/              # Main companion window & header controls
│   ├── shared/                # Common UI tokens, constants & utilities
│   └── widgets/
│       └── kanban_board/      # Layered deck view, columns & task cards
└── test/                      # Comprehensive unit and widget test suite
```

---

## 🚀 Getting Started

### Prerequisites

Ensure you have the following installed on your Linux machine:

- **Flutter SDK** (>= 3.19.0)
- **Dart SDK** (>= 3.3.0)
- Linux build dependencies:
  ```bash
  sudo apt-get update
  sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev
  ```

### Development & Debugging

Clone or navigate to the repository and run:

```bash
# Fetch dependencies
flutter pub get

# Run on Linux desktop in debug mode
flutter run -d linux
```

### Running Tests

Run the full automated test suite:

```bash
flutter test
```

---

## 📦 Building & Desktop Installation

### 1. Build the Release Binary

Compile an optimized release bundle:

```bash
./build_release.sh
```

The output binary will be created at `build/linux/x64/release/bundle/pin`.

### 2. Launching

The provided `launch_pin.sh` script automatically detects whether a release or debug build exists, preferring the freshest build:

```bash
./launch_pin.sh
```

### 3. GNOME Desktop Integration

To make Pin searchable in your GNOME Applications overview (`Super` key) and add a desktop shortcut:

```bash
# Install the application launcher
cp pin.desktop ~/.local/share/applications/pin.desktop

# Optional: Add to desktop
cp pin.desktop ~/Desktop/pin.desktop
gio set ~/Desktop/pin.desktop metadata::trusted true

# Update desktop and icon databases
update-desktop-database ~/.local/share/applications
gtk-update-icon-cache -f ~/.local/share/icons/hicolor 2>/dev/null || true
```

---

## 📄 License

This project is licensed under the MIT License — see the LICENSE file for details.
