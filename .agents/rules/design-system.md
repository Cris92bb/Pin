# Design System & Palette Guidelines for Pin

These rules enforce the visual language, color tokens, and UI styling standards for all AI agents modifying the Pin application.

---

## 1. Faded Sage Green Design Palette (Light Mode)

When creating or modifying light mode UI components, never use generic cold grays (`#FFFFFF`, `#F3F4F6`, `#E5E7EB`, `#9CA3AF`), stark black outlines (`#000000`), or uncoordinated accent colors. Always reference and use tokens from `PinTokens` or `Theme.of(context)`:

| Token Name | HEX Code | Visual Tone | Role & Application |
| --- | --- | --- | --- |
| `PinTokens.lightCanvasBg` | `#F3F5EE` | Soft sage-tinted white | Main page backdrop, companion frame background |
| `PinTokens.lightSheetBg` | `#E7ECE1` | Faded misty sage green | Active sliding sheet body ("To do"), Focus Mode subtask tray |
| `PinTokens.lightStackedTabBg` | `#DEE3D7` | Muted olive-gray | Stacked background drawer tabs ("Backlog", "Done"), secondary hover |
| `PinTokens.lightCardBg` | `#EFF3EA` | Ultra-light tinted off-white | Inner task cards, text input fields, modal surfaces |
| `PinTokens.lightTagBg` | `#E2E9DC` | Soft desaturated sage fill | Category tags (`#dev`), duration/energy badges, secondary button background |
| `PinTokens.lightBorder` | `#D4DCCE` | Soft leafy gray | 1.0px card borders, dividers, grab handle tracks, progress meter track |
| `PinTokens.lightTextPrimary` | `#1A241E` | Deep forest near-black | Task titles, active drawer title, modal headings, primary stopwatch digits |
| `PinTokens.lightTextSecondary` | `#5F6D64` | Muted sage slate | Task body descriptions, auxiliary counter badges, subtask count labels |
| `PinTokens.lightTextTertiary` | `#8E9C92` | Soft olive-slate | Drawer pull grab bar, radio ring borders, unpin & delete icons, input hint text |
| `PinTokens.lightFabBg` | `#2B3B32` | Dark spruce evergreen | Primary Action Accent: Floating `+` button, primary buttons, checked checkboxes, progress fill |

---

## 2. Component Design Standards

### Drawer & Deck Stacking
- **Active Sheet**: Fill with `#E7ECE1` (`PinTokens.lightSheetBg`) with top radius of 28px and 1.0px `#D4DCCE` border. Title must be bold (`FontWeight.w800`, 24px).
- **Inactive Stacked Tabs**: Fill with `#DEE3D7` (`PinTokens.lightStackedTabBg`) with top radius of 24px and 1.0px `#D4DCCE` border. Titles must be medium weight (`FontWeight.w500`, 14-17px) and colored with `PinTokens.lightTextSecondary` (`#5F6D64`) to preserve clear visual hierarchy.
- **Grab Handle**: Center pill (36x4px) tinted with `#8E9C92` (`PinTokens.lightTextTertiary`).

### Task & Step Cards
- **Card Surfaces**: In light mode, use `#EFF3EA` (`PinTokens.lightCardBg`) with **no border** (`border: null`) and elevated with soft multi-layer ambient shadow (`PinTokens.lightCardShadow` - `blurRadius: 4` + `blurRadius: 16`). In dark mode, use 1.6px border with `PinTokens.darkBorder`.
- **Checkboxes**: Unchecked state must use a 1.5px ring border in `#8E9C92` (`PinTokens.lightTextTertiary`) with transparent center. Completed state must use solid `#2B3B32` (`PinTokens.lightFabBg`) fill with white check icon.
- **Category Tags**: Split whitespace/newlines into distinct rounded badges (`#E2E9DC` fill, `#5F6D64` text, radius: 6).
- **Micro-actions**: Delete and pin/unpin buttons must use `#8E9C92` (`PinTokens.lightTextTertiary`), not harsh black or generic gray.

### Focus Mode & Immersive Views
- **Backdrop**: `#F3F5EE` (`PinTokens.lightCanvasBg`).
- **Status Pill**: `#E2E9DC` (`PinTokens.lightTagBg`) with `#D4DCCE` border, `#2B3B32` indicator dot, and `#1A241E` label.
- **Timer / Stopwatch**: Digits in `#1A241E` (`FontWeight.w700`, 56px, tabular figures). Active live session text in `#2B3B32`.
- **Subtask Tray**: Recessed bottom container in `#E7ECE1` (`PinTokens.lightSheetBg`) with top radius 24px.
- **Progress Track**: Track in `#D4DCCE` (`PinTokens.lightBorder`), filled value in `#2B3B32` (`PinTokens.lightFabBg`).

### Buttons & Interactive Controls
- **Primary Buttons (`PinButton.primary`)**: Solid spruce evergreen `#2B3B32` (hover `#202D26`) with white text/icon.
- **Secondary Buttons (`PinButton.secondary`)**: Soft sage background `#E2E9DC` (hover `#DEE3D7`), border `#D4DCCE`, text `#1A241E`.
- **Ghost Buttons**: Transparent background with hover fill `#E2E9DC` (alpha 0.6).
