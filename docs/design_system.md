# Pin Design System: Faded Sage Green Specification

This document provides the canonical design system specification for the **Pin** companion application. It details all visual tokens, color roles, typography, elevation models, and component guidelines used across the interface.

---

## 1. Aesthetic Philosophy

Pin is designed as an **editorial, tactile desk companion**. It rejects harsh, unstyled wireframe aesthetics (stark `#FFFFFF` paired with heavy `#000000` strokes) in favor of:
- **Atmospheric Warm Tranquility**: A faded misty sage and warm olive palette that reduces visual fatigue during high-intensity focus sessions.
- **Physical Stacking Depth**: Natural layer separation via subtle value stepping (`#F3F5EE` → `#E7ECE1` → `#EFF3EA`) and low-opacity slate borders rather than stark outlines or heavy drop-shadows.
- **Intentional Action Accents**: Grounded spruce evergreen (`#2B3B32`) anchors primary actions (FAB, checkboxes, completed WIP indicators) with authority without shouting.

---

## 2. Design Token Variable Reference

### 2.1 Core Palette Tokens (Light Mode)

| Variable / Token | HEX Code | RGB / CSS | Visual Tone | Semantic Usage |
| --- | --- | --- | --- | --- |
| `PinTokens.lightCanvasBg` | `#F3F5EE` | `rgb(243, 245, 238)` | Very soft warm sage-tinted white | Main page backdrop, companion frame background, Focus Mode canvas |
| `PinTokens.lightSheetBg` | `#E7ECE1` | `rgb(231, 236, 225)` | Faded misty sage green | Active sliding bottom sheet container ("To do"), Focus Mode subtasks tray |
| `PinTokens.lightStackedTabBg` | `#DEE3D7` | `rgb(222, 227, 215)` | Muted desaturated olive-gray | Collapsed background drawer tabs ("Backlog", "Done"), secondary hover state |
| `PinTokens.lightCardBg` | `#EFF3EA` | `rgb(239, 243, 234)` | Ultra-light tinted off-white | Foreground task item cards, atomic subtask tiles, text input fields, modal surfaces |
| `PinTokens.lightTagBg` | `#E2E9DC` | `rgb(226, 233, 220)` | Soft desaturated sage fill | Category tags (`#dev`), duration/energy pills, secondary button background |
| `PinTokens.lightBorder` | `#D4DCCE` | `rgb(212, 220, 206)` | Soft leafy gray | 1.0px card outlines, sheet borders, dividers, available WIP slot track |
| `PinTokens.lightTextPrimary` | `#1A241E` | `rgb(26, 36, 30)` | Deep forest near-black | Primary task titles, active sheet header, modal titles, stopwatch timer digits |
| `PinTokens.lightTextSecondary` | `#5F6D64` | `rgb(95, 109, 100)` | Muted sage slate | Task body descriptions, auxiliary counter badges, duration text, subtask counts |
| `PinTokens.lightTextTertiary` | `#8E9C92` | `rgb(142, 156, 146)` | Soft olive-slate | Drawer pull grab bar, unchecked radio rings, unpin/delete icons, input placeholder hints |
| `PinTokens.lightFabBg` | `#2B3B32` | `rgb(43, 59, 50)` | Dark spruce evergreen | Action Accent: Floating `+` button, primary buttons, checked checkboxes, progress fill |

### 2.2 Semantic & Accent Tokens

| Variable / Token | HEX Code | Dark Mode Counterpart | Usage |
| --- | --- | --- | --- |
| `PinTokens.accentEmerald` | `#10B981` | `#10B981` | Success celebration, completed milestone badges |
| `PinTokens.accentAmber` | `#F59E0B` | `#F59E0B` | Medium flow, warnings, caution indicators |
| `PinTokens.accentRose` | `#F43F5E` | `#F43F5E` | Danger actions, delete confirmations, error messages |
| `PinTokens.accentSky` | `#0EA5E9` | `#38BDF8` | Informational links, tags |
| `PinTokens.accentViolet` | `#8B5CF6` | `#A78BFA` | Deep focus tags, secondary highlights |

---

## 3. Typography Hierarchy

Pin uses a clean, modern sans-serif system typeface (`fontFamily: 'sans-serif'`) with disciplined font weights and tracking to establish clear visual hierarchy:

| Level | Size | Weight | Line Height | Letter Spacing | Color Token | Example Usage |
| --- | --- | --- | --- | --- | --- | --- |
| **Stopwatch Digits** | `56px` | `FontWeight.w700` | `1.0` | `2.0` (Tabular) | `lightTextPrimary` | Focus Mode elapsed timer |
| **Drawer Header (Active)** | `24px` | `FontWeight.w800` | `1.2` | `-0.5` | `lightTextPrimary` | "To do" active sheet title |
| **Drawer Header (Inactive)**| `14px` | `FontWeight.w500` | `1.2` | `0.0` | `lightTextSecondary` | "Backlog" / "Done" tab title |
| **Section / Modal Title** | `18px` | `FontWeight.w700` | `1.3` | `-0.3` | `lightTextPrimary` | Modals, card action bubble |
| **Task Title** | `15px` | `FontWeight.w700` | `1.3` | `0.0` | `lightTextPrimary` | Task card foreground title |
| **Subtask Title** | `13px` | `FontWeight.w500` | `1.3` | `0.0` | `lightTextPrimary` | Focus Mode atomic checklist |
| **Body / Description** | `13px` | `FontWeight.w400` | `1.35` | `0.0` | `lightTextSecondary` | Task description snippet |
| **Metadata & Badges** | `11px` | `FontWeight.w600` | `1.2` | `0.4` | `lightTextSecondary` | Energy chips, duration pills |
| **Micro Labels** | `10.5px`| `FontWeight.w600` | `1.1` | `0.6` | `lightTextSecondary` | Category tags, checklist counts |

---

## 4. Spacing & Shape Geometry

### 4.1 Corner Radii
- **Full / Pill (`PinTokens.radiusFull`)**: `BorderRadius.circular(999)` — Badges, WIP pills, pill buttons, grab bar.
- **Sliding Sheet Top (`PinTokens.radiusDeck`)**: `BorderRadius.vertical(top: Radius.circular(28))` — Active kanban drawer.
- **Stacked Tab Top**: `BorderRadius.vertical(top: Radius.circular(24))` — Inactive drawer tabs.
- **Card Surface (`PinTokens.radiusCard`)**: `BorderRadius.circular(20)` — Inner task cards (`radiusLg` is `16.0`).
- **Subtask / Input (`PinTokens.radiusMd`)**: `BorderRadius.circular(10)` — Micro-step tiles, text fields.
- **Control / Checkbox (`PinTokens.radiusSm`)**: `BorderRadius.circular(6)` — Action icons, micro buttons.

### 4.2 Elevation & Shadows
- **Card Subtle Shadow**: `BoxShadow(color: Color(0xFF0F172A).withValues(alpha: 0.03), blurRadius: 10, offset: Offset(0, 2))`
- **Active Sheet Depth Shadow**: `BoxShadow(color: Color(0xFF0F172A).withValues(alpha: 0.04), blurRadius: 16, spreadRadius: 1, offset: Offset(0, -5))`
- **Floating Action Button (FAB)**: `BoxShadow(color: Color(0xFF2B3B32).withValues(alpha: 0.25), blurRadius: 14, offset: Offset(0, 5))`

---

## 5. Component Implementation Rules

### 5.1 Layered Deck View
1. **Background Drawer Stacking**:
   - Depth layer 0 (Backlog): `cardBg: PinTokens.lightStackedTabBg` (`#DEE3D7`), hover: `#D6DCCF`.
   - Depth layer 1 (Done): `cardBg: PinTokens.lightStackedTabBg` (`#DEE3D7`), hover: `#D6DCCF`.
   - Active Foreground (To do): `cardBg: PinTokens.lightSheetBg` (`#E7ECE1`), border: `PinTokens.lightBorder` (`#D4DCCE`).
2. **Tactile Grab Handle**:
   - `width: 36`, `height: 4`, `borderRadius: 2`, `color: PinTokens.lightTextTertiary` (`#8E9C92`).
3. **WIP Segment Track**:
   - Filled slots: `PinTokens.lightFabBg` (`#2B3B32`).
   - Available/empty slots: `PinTokens.lightBorder` (`#D4DCCE`).

### 5.2 Task Cards
1. **Card Container**:
   - Background: `PinTokens.lightCardBg` (`#EFF3EA`).
   - Border: No border in light mode (`border: null`), keeping the card seamless. (Dark mode uses `PinTokens.darkBorder`, width: 1.6).
   - Elevation Shadow: Multi-layered soft ambient shadow (`PinTokens.lightCardShadow`):
     - Layer 1: `BoxShadow(color: Color(0xFF1A241E).withValues(alpha: 0.04), blurRadius: 4, offset: Offset(0, 1))`
     - Layer 2: `BoxShadow(color: Color(0xFF1A241E).withValues(alpha: 0.07), blurRadius: 16, spreadRadius: -2, offset: Offset(0, 4))`
2. **Checkbox Radio**:
   - Unchecked: `border: 1.5px PinTokens.lightTextTertiary` (`#8E9C92`), background: transparent.
   - Checked: `color: PinTokens.lightFabBg` (`#2B3B32`), icon: white check (`size: 14`).
3. **Category Tags**:
   - Split whitespace/newlines cleanly into individual rounded mini-pills (`#E2E9DC` fill, `#5F6D64` text, radius: 6).
4. **Icon Actions**:
   - Unpin and delete icons: `PinTokens.lightTextTertiary` (`#8E9C92`).

### 5.3 Focus Mode View
1. **Canvas**:
   - `PinTokens.lightCanvasBg` (`#F3F5EE`).
2. **Top Minimalist Bar**:
   - Border bottom: `PinTokens.lightBorder` (`#D4DCCE`).
   - "FOCUS" badge: background `PinTokens.lightTagBg` (`#E2E9DC`), border `PinTokens.lightBorder` (`#D4DCCE`), indicator dot & text `PinTokens.lightFabBg` (`#2B3B32`) / `PinTokens.lightTextPrimary` (`#1A241E`).
3. **Timer Display**:
   - Digits in `PinTokens.lightTextPrimary` (`#1A241E`).
   - Live session label in `PinTokens.lightFabBg` (`#2B3B32`).
4. **Subtasks Tray**:
   - Background: `PinTokens.lightSheetBg` (`#E7ECE1`), matching the sliding sheet.
   - Progress meter track: `PinTokens.lightBorder` (`#D4DCCE`), fill: `PinTokens.lightFabBg` (`#2B3B32`).
   - Step tiles: `PinTokens.lightCardBg` (`#EFF3EA`) with `PinTokens.lightBorder` (`#D4DCCE`).
   - Quick-add input: `fillColor: PinTokens.lightCardBg` (`#EFF3EA`), `focusedBorder: PinTokens.lightFabBg` (`#2B3B32`).

### 5.4 Buttons (`PinButton`)
1. **Primary**:
   - Base: `PinTokens.lightFabBg` (`#2B3B32`), hover: `#202D26`, text/icon: white.
2. **Secondary**:
   - Base: `PinTokens.lightTagBg` (`#E2E9DC`), hover: `PinTokens.lightStackedTabBg` (`#DEE3D7`), border: `PinTokens.lightBorder` (`#D4DCCE`), text: `PinTokens.lightTextPrimary` (`#1A241E`).
3. **Ghost**:
   - Base: transparent, hover: `PinTokens.lightTagBg.withValues(alpha: 0.6)`.

---

## 6. Token Mapping Cross-Reference

| Role | Light Mode Token | Light Mode HEX | Dark Mode Token | Dark Mode HEX |
| --- | --- | --- | --- | --- |
| Canvas Background | `lightCanvasBg` | `#F3F5EE` | `darkCanvasBg` | `#090A0F` |
| Primary Sheet Body | `lightSheetBg` | `#E7ECE1` | `darkCardBg` | `#171B26` |
| Stacked Drawer Tabs| `lightStackedTabBg` | `#DEE3D7` | `darkCardBg` | `#171B26` |
| Task Item Cards | `lightCardBg` | `#EFF3EA` | `darkCardBg` | `#171B26` |
| Pill & Tag Fill | `lightTagBg` | `#E2E9DC` | `surfaceColumn` | `#131722` |
| Borders & Dividers | `lightBorder` | `#D4DCCE` | `darkBorder` | `rgba(255, 255, 255, 0.08)` |
| Primary Typography | `lightTextPrimary` | `#1A241E` | `darkTextPrimary` | `#F8FAFC` |
| Secondary Typography| `lightTextSecondary`| `#5F6D64` | `darkTextSecondary`| `#94A3B8` |
| Tertiary / Icons | `lightTextTertiary` | `#8E9C92` | `darkTextMuted` | `#64748B` |
| Action Accent (FAB) | `lightFabBg` | `#2B3B32` | `accentEmerald` | `#10B981` |

---

## 7. Smartwatch & Wear OS Design Specification

When running on Wear OS devices (e.g. Pixel Watch, Galaxy Watch), Pin shifts to an ultra-compact, tactile wrist companion interface (`WearableHomePage`):

### 7.1 OLED Dark-First Palette
- **Canvas Backdrop**: Pure `#000000` (true OLED black) to maximize battery longevity and blend seamlessly into circular smartwatch bezels.
- **Card Surfaces**: Deep charcoal `#1B1D1C` and container `#141916` with low-opacity sage borders (`PinTokens.accentSage.withValues(alpha: 0.25)`).
- **Accents**: 
  - `PinTokens.accentEmerald` (`#10B981`) for completed pins and verified sync status.
  - `PinTokens.accentSage` (`#A3B899`) for primary interactive controls, hero focus triggers, and Google authentication.

### 7.2 Multi-Line Compact Typography
To optimize the limited screen real estate on circular displays ($\sim 1.2" - 1.4"$), typography uses tight line heights and multi-line wrapping:
- **Task Titles**: `11px` (compact) to `12px` (hero), `FontWeight.w700`, `maxLines: 2`, `height: 1.15`.
- **Task Descriptions**: `9.5px`, `FontWeight.w400`, `maxLines: 3`, `height: 1.18` in `Colors.white70`.
- **Badges & Metadata**: `8.5px` to `9.5px` uppercase tracking for energy tags and subtask counts.

### 7.3 Edge-to-Edge Spatial Geometry
- **Horizontal Width**: Full-bleed edge layout with minimal `6.0px` side margin, ensuring cards utilize maximum screen width.
- **Vertical Safe Insets**: Preserves system top/bottom chin margins (`safePadding.top`, `safePadding.bottom + 8.0`) to avoid cut-off content on round displays.
- **Corner Radii**: Rounded `10px` to `16px` corners matching the circular geometry of the chassis.

### 7.4 Gesture & Navigation Constraints
- **`LeftOnlyPageScrollPhysics`**: Restricts carousel swiping to leftward forward motion only (`offset <= 0`), preventing conflicts with the Wear OS system-level left-edge swipe-to-dismiss gesture.
- **Infinite Carousel Loop**: 4-page sequence (`Today -> Backlog -> Completed -> Account -> Today...`).
- **Input Sanitization**: Virtual keyboard inputs for email explicitly enforce `textCapitalization: TextCapitalization.none` and `autocorrect: false` to guarantee credential parity across devices.

---

## 8. Strict Design Token Consistency & Zero Hardcoded Colors

1. **Zero Hardcoded Colors**: All UI elements, modal cards, buttons, backgrounds, and badges must reference `PinTokens` or `Theme.of(context)`. Hardcoded `Color(0x...)` or random hex literals are strictly prohibited.
2. **Harmonious Palette Enforcement**: The tactile faded sage green light palette (`#F3F5EE`, `#E7ECE1`, `#EFF3EA`, `#2B3B32`) and the OLED dark palette are the sole sources of styling truth across desktop, foldables, and Wear OS watches.
3. **Shadow and Border Cohesion**: Shadows and borders must use standardized tokens (`PinTokens.lightCardShadow`, `PinTokens.shadowSlate`, `PinTokens.shadowForest`, `PinTokens.lightBorder`, `PinTokens.darkBorder`).

---

## 9. File Size & Clean Componentization Standard (<= 300 LOC)

1. **Target File Threshold**: Strive to keep all Dart source files **under 300 lines of code**.
2. **Sub-Component Modularity**: Complex multi-part widgets and large modal dialogs must be extracted into dedicated `components/` subdirectories with clear single responsibilities.
3. **Comprehensive Dart Doc Comments**: Every public component, class, method, and constructor must include descriptive Dart doc comments (`///`) detailing purpose, interaction models, parameters, and architectural classification.


