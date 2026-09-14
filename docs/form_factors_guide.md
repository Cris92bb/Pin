# Multi-Device & Form Factor Guide

This project supports modern multi-device form factors:

1. **Wearable (Wear OS & Smartwatches)**
2. **Smartphone (Portrait Compact)**
3. **Foldable & Tablet (Unfolded Dual-Pane / Multi-Drawer)**
4. **Web & Desktop (Windows, Linux — Expanded Multi-Column / Companion View)**

---

## 1. Breakpoint Philosophy

Pin layout breakpoints adapt dynamically based on screen tiers and window widths (`PinBreakpoints`):
- **Wearable**: Both display sides $\le 320$ logical pixels (Wear OS, smartwatch viewports). Dedicated `WearableHomePage` with vertical focus cards.
- **Smartphone / Compact (< 600px)**: Companion single-column layout or compact single-drawer mode with swipeable decks.
- **Foldable / Tablet (600px - 1024px)**: Dual/three-drawer responsive layout adapting to screen width or hinge display features.
- **Desktop / Web ($\ge$ 1024px)**: Multi-drawer companion kanban workspace with responsive overlays, keyboard shortcuts, and full workarea height.

---

## 2. Wearable (Smartwatch) Implementation

Smartwatches present unique constraints:
- **Circular Display Insets**: Square viewports clip corners on circular screens. Use `WearableUtils.getSafeCircularPadding(context)` to compute the maximal inscribed rectangular padding.
- **Glanceable Hierarchy**: Large typography, high-contrast badges, single-touch actions, and no overflow.
- **Dismiss Navigation**: System dismiss edge-swipes are accommodated using dedicated gesture isolation and back buttons.

---

## 3. Desktop & Web Implementation

- **Windows**: Standard Flutter Windows desktop runner (`windows/`).
- **Linux GTK Integration**:
  - Theme synchronization via `MethodChannel('pin/theme')`.
  - Window dragging, resizing, and closing via `MethodChannel('pin/window')`.
  - Fixed-width companion geometry hints (430px) and primary monitor workarea height querying in `my_application.cc`.
  - Desktop launcher installation via `install_desktop_entry.sh` and launcher shortcut `pin.desktop`.
- **Web**:
  - Optimized WASM-GC + Skwasm / CanvasKit compilation via `build_web.sh`.
  - Smooth multi-device scroll behavior with `PinScrollBehavior`.
