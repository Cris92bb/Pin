# <p align="center"><img src="assets/icons/pin.png" width="64" height="64" alt="Pin Icon" valign="middle" /><br>Pin</p>

<p align="center">
  <strong>A minimalist, high-focus companion Kanban app built for Linux Desktop & Wear OS Smartwatches.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Platform-Linux%20(GTK)-E95420?logo=linux&logoColor=white" alt="Linux" />
  <img src="https://img.shields.io/badge/Platform-Wear%20OS%20%7C%20Android-green?logo=android&logoColor=white" alt="Wear OS" />
  <img src="https://img.shields.io/badge/Architecture-Riverpod-blueviolet" alt="Riverpod" />
  <img src="https://img.shields.io/badge/Storage-Local--First%20(Offline)-green" alt="Local-First" />
</p>

---

## 📌 Overview

**Pin** is a companion Kanban application tailored for power users, developers, and writers on Linux desktop environments (such as GNOME) as well as **Wear OS smartwatches**.

On desktop, designed to sit snugly alongside your IDE, terminal, or web browser, **Pin** adopts a **companion layout** (fixed 430px width, height-only resizing, and full monitor workarea default height) so you never lose context while organizing your workload.

On smartwatches, **Pin** seamlessly adapts into a lightweight, tactile wrist companion with gesture-safe navigation, OLED-optimized contrast, full-width task cards, and cloud synchronization.

![Pin Screenshot](screenshot.png)

---

## ✨ Features

- **🗂️ Layered Deck Kanban**:
  - Three intuitive, full-width drawers: **Backlog**, **In Progress**, and **Done**.
  - One-click toggling and seamless animated transitions between layers.
- **⌚ Wear OS Smartwatch Companion**:
  - **Auto Viewport Adaptation**: Automatically identifies circular and wearable viewports via `WearableUtils.isWearable(context)` and activates `WearableHomePage`.
  - **Left-Only Infinite Carousel Navigation**: Custom `LeftOnlyPageScrollPhysics` ensures navigation only swipes left forward (`Today -> Backlog -> Completed -> Account -> Today...`), completely avoiding interference with the Wear OS left-edge swipe-to-dismiss system gesture.
  - **Full-Width Multi-Line Task Cards**: Expands cards to edge-to-edge width with 2-line title and 3-line description rendering so you can read your pins at a glance on the go.
  - **Wearable Focus Mode**: Immersive single-pin focus view with elapsed timer, step-by-step checklist, and instant completion.
  - **Watch Cloud Sync & Account**: Dedicated watch Account screen with 1-click Google Sign-In, Email/Password sign-in, case-insensitive credential normalization, and auto password prompting.
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
- **🔥 Firebase Offline-First Dual-Layer Synchronization**:
  - **Zero-Latency Optimistic UI**: UI updates immediately via Riverpod state (0ms latency).
  - **Guaranteed Local Persistence**: Instant writes to local storage (`PrefsStorageAdapter`) on every single change ensure zero offline data loss, even in guest mode.
  - **1,000ms Debounced Cloud Firestore Sync**: When signed in, rapid edits or checklist toggles debounce for 1,000ms before sending a single compact snapshot to `/users/{userId}/meta/board`, preventing write thrashing and API quota exhaustion.
  - **Multi-Device Cloud Hydration**: Logging in automatically hydrates your board from the cloud; if logging into a new cloud account with existing local pins, your local pins seed the cloud board.
  - **Tactile Header Badge**: Real-time cloud sync status indicator in the companion header (Synced, Syncing, Offline, Guest).
  - **GDPR Right-to-Erasure**: One-click deletion of cloud board snapshot, user profile, and authentication account.
  - **Security Rules**: User-scoped data isolation enforced via [`firestore.rules`](firestore.rules).
- **💾 Local-First & Private by Default**:
  - 100% functional without an account or internet connection.
  - Zero required cloud dependencies or telemetry; guest mode works entirely offline.
- **📤 Export & Import**:
  - Full JSON backup and restore capabilities for data safety and cross-machine migration.
- **✨ Gemini AI Decomposition & Auto-Fill**:
  - Securely configure your Google Gemini API key via the header menu or inside the task dialog.
  - One-click task breakdown: type a quick idea or title, and Gemini refines the title, generates a clear objective description, sets the cognitive energy profile, estimates total duration, attaches relevant tags, and generates 2–6 bite-sized atomic subtasks (each $\le 15$ minutes).
  - Supports model selection (`gemini-1.5-flash`, `gemini-2.5-flash`, `gemini-2.0-flash`) and zero-config fallback via the `GEMINI_API_KEY` environment variable.
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
├── android/                   # Android & Wear OS runner manifests and configurations
├── lib/
│   ├── main.dart              # Application entry point
│   ├── app/                   # App-wide routing, configuration & theme tokens
│   ├── entities/
│   │   ├── task/              # PinTask entity, state notifier & repository
│   │   └── atomic_step/       # Micro-step models and widgets
│   ├── features/
│   │   ├── ai/                # Gemini task breakdown & smart decomposition
│   │   ├── focus_mode/        # Deep-focus immersion view and timer
│   │   ├── sync/              # Cloud Firestore dual-layer sync & auth service
│   │   ├── task_crud/         # Task creation, editing & priority tags
│   │   ├── task_export_import/# JSON export & import tools
│   │   └── wearable/          # Wear OS smartwatch UI, left-only physics & watch login
│   ├── pages/
│   │   └── home/              # Main companion window & header controls
│   ├── shared/                # Common UI tokens, constants & utilities
│   └── widgets/
│       └── kanban_board/      # Layered deck view, columns & task cards
└── test/                      # Comprehensive unit and widget test suite
```

---

## 🚀 Getting Started

### 1. Environment & Prerequisites Check

Audit host OS, Git, Flutter/Dart SDKs, desktop/web build toolchains, and packages:

```bash
bash .agents/skills/setup-repo/scripts/setup_check.sh

# Or auto-enable missing platform flags and fetch packages:
bash .agents/skills/setup-repo/scripts/setup_check.sh --fix
```

A Git pre-commit hook is included in `.githooks/pre-commit` to prevent committing code if FSD architecture rules, AST static analysis, or architecture tests fail:

```bash
git config core.hooksPath .githooks
```

### 2. Development & Debugging

Clone or navigate to the repository and run:

```bash
# Fetch dependencies
flutter pub get

# Run on Linux desktop in debug mode
flutter run -d linux

# Or Windows desktop (on Windows host):
flutter run -d windows

# Or Web (Chrome or local server):
flutter run -d chrome

# Run on connected Wear OS smartwatch (e.g. Pixel Watch)
flutter run -d <device_id_or_watch_name>
```

### 3. Running Verification & Tests

Run the FSD architecture audit, static analyzer, and test suite:

```bash
# Verify Feature-Sliced Design boundary rules
dart run tool/verify_fsd.dart --strict

# Static analysis
flutter analyze

# Full test suite
flutter test
```

---

## 🏛️ Code Quality, Architecture & Design Tokens

Pin adheres to strict code quality and architectural guidelines:

- **Feature-Sliced Design (FSD v2.1)**: Strictly unidirectional dependencies (`app` → `pages` → `widgets` → `features` → `entities` → `shared`) with zero cross-slice coupling. Verify with `dart run tool/verify_fsd.dart --strict`.
- **File Sizing & Modularity (<= 300 LOC)**: All Dart source files ideally remain under 300 lines of code. Large files and monolithic views are broken down into clean, modular sub-components in dedicated `components/` subdirectories.
- **Doctype & Documentation Comments**: Every component, class, method, and state provider is documented with descriptive Dart doc comments (`///`) providing role descriptions, architectural context, and parameter specifications.
- **Design Token Consistency & Zero Hardcoded Colors**: No hardcoded `Color(0x...)` or random hex literals in UI files. All visual styles, borders, radii, and shadows reference `PinTokens` or `Theme.of(context)` to preserve the faded sage green and OLED dark palettes.

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

To install the desktop launcher and high-resolution icon for your user:

```bash
bash install_desktop_entry.sh
```

This automatically configures `pin.desktop` with the current checkout path and installs the application icon into `~/.local/share/icons/hicolor/512x512/apps/pin.png`.

---

## 📄 License

This project is licensed under the MIT License — see the LICENSE file for details.
