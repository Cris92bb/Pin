# Multi-Device & Form Factor Guide

This project supports modern multi-device form factors:

1. **Wearable (Wear OS & Smartwatches)**
2. **Smartphone (Portrait Compact)**
3. **Foldable & Tablet (Unfolded Dual-Pane / Multi-Drawer)**
4. **Web & Desktop (Windows, Linux — Expanded Multi-Column / Companion View)**

---

## 1. Breakpoint Philosophy

Pin layout breakpoints adapt dynamically based on screen tiers and window widths (`PinBreakpoints` / `PinScreenTier`):
- **Wearable (`PinScreenTier.xs`)**: Smartwatches / Wear OS viewports detected via `WearableUtils.isWearable(context)` or display width $< 320.0$ logical pixels (`PinBreakpoints.xsMax`). Renders the dedicated `WearableHomePage`.
- **Smartphone / Compact (`PinScreenTier.small`)**: Screen width $< 720.0$ logical pixels (`PinBreakpoints.smallMax`). Single-column companion mode with layered swipeable deck drawers (`LayeredDeckView`).
- **Foldable, Tablet & Desktop / Web (`PinScreenTier.wide`)**: Screen width $\ge 720.0$ logical pixels up to `wideMaxWidth` ($1240.0$ logical pixels). Responsive 3-drawer layout (`WideFoldKanbanView`) with physical cross-screen drawer swap transitions, docking tray outline, side-by-side visible queue, and active sliding overlay panel.

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
