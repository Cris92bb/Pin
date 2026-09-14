# Form Factors & Multi-Device Guidelines

This repository supports four distinct device and viewport tiers:

| Tier | Enum | Condition / Width | Primary Target Devices | Layout Archetype |
|---|---|---|---|---|
| **Wearable** | `ScreenTier.wearable` | `longestSide <= 320.0` (both sides small) | Wear OS, Apple Watch | Circular/glanceable, high-contrast, vertical gestures |
| **Smartphone** | `ScreenTier.compact` | `width < 600.0` | Mobile phones, folded foldables | Single-column stacked, bottom navigation / app bar |
| **Foldable / Tablet** | `ScreenTier.foldOrTablet` | `600.0 <= width < 1024.0` | Foldables unfolded, 8-11" tablets | Dual-pane split view (along the hinge when reported), master-detail |
| **Desktop / Web** | `ScreenTier.desktopWeb` | `width >= 1024.0` | Windows, Linux, macOS, Full Web | Navigation rail, multi-column workspace, keyboard shortcuts |

---

## 1. Wearable Guidelines
- Inset safe padding using `WearableUtils.getSafeCircularPadding(context)` so circular bezels never clip text or action buttons.
- Scale glanceable content down (`FittedBox(fit: BoxFit.scaleDown)`) instead of overflowing small faces.
- Touch targets on wearable displays must be compact yet easily tappable with generous touch pads.
- Handle gestures carefully: avoid horizontal gestures that conflict with watch system dismiss swipe.

## 2. Foldable & Smartphone Guidelines
- Support fold state transitions smoothly without losing user input or navigation state (keep state above tier views).
- Read `MediaQuery.displayFeaturesOf(context)` and never place content under a hinge.
- In compact view, show master view; upon selecting an item or when unfolded, expand into dual-pane view.
- Wrap rows of buttons and make row text `Expanded`/`Flexible` so layouts survive narrow widths and large text scales.

## 3. Web & Desktop Guidelines
- Support keyboard navigation (`FocusNode`, `onKeyEvent`, `Shortcuts`/`CallbackShortcuts`); destinations use Ctrl/⌘ + 1–3.
- Support desktop mouse hover states (`MouseRegion`, `InkWell`).
- On Linux, build custom title bars with `WindowControlService` (drag/resize/close over `MethodChannel('pin/window')`); drag and resize work on X11 but are ignored by most Wayland compositors.
