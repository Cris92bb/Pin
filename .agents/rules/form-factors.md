# Form Factors & Multi-Device Guidelines

This repository supports three canonical viewport tiers defined in `PinScreenTier` and `PinBreakpoints`:

| Tier | Enum | Condition / Width | Primary Target Devices | Layout Archetype |
|---|---|---|---|---|
| **Wearable** | `PinScreenTier.xs` | `WearableUtils.isWearable` or `width < 320.0` | Wear OS (Pixel Watch, Galaxy Watch) | Circular/glanceable, high-contrast, infinite left-only carousel (`WearableHomePage`) |
| **Smartphone / Compact** | `PinScreenTier.small` | `width < 720.0` | Mobile phones, folded foldables, compact companion | Single-column layered deck, swipeable drawers (`LayeredDeckView`) |
| **Foldable / Tablet / Desktop / Web** | `PinScreenTier.wide` | `width >= 720.0` | Unfolded foldables, tablets, desktop, web | Responsive 3-drawer layout (`WideFoldKanbanView`), docking drawers & side overlay |

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
