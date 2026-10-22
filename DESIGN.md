---
name: "PixelSearch"
description: "A native photographic light table for finding personal memories."
colors:
  primary: "#176B62"
  on-primary: "#FFFFFF"
  primary-container: "#E0EFEA"
  on-primary-container: "#124E46"
  surface: "#F8FAF9"
  on-surface: "#192B2B"
  on-surface-variant: "#50645F"
  surface-container-lowest: "#FFFFFF"
  surface-container-low: "#F0F5F2"
  surface-container: "#EAF1EE"
  surface-container-high: "#E5EFEB"
  surface-container-highest: "#DEEAE5"
  outline: "#758A81"
  outline-variant: "#D6E2DC"
  dark-primary: "#92D5C8"
  dark-on-primary: "#00382F"
  dark-primary-container: "#204B43"
  dark-on-primary-container: "#D0F5EB"
  dark-surface: "#111A19"
  dark-on-surface: "#E5EEEA"
  dark-on-surface-variant: "#B4C6C0"
  dark-surface-container-lowest: "#0D1514"
  dark-surface-container-low: "#182321"
  dark-surface-container: "#1E2C28"
  dark-surface-container-high: "#273730"
  dark-surface-container-highest: "#304139"
  dark-outline: "#7F9990"
  dark-outline-variant: "#344A42"
typography:
  headline-large:
    fontFamily: "Manrope"
    fontSize: "36px"
    fontWeight: 800
    lineHeight: 1.15
    letterSpacing: "-1.2px"
  headline-medium:
    fontFamily: "Manrope"
    fontSize: "28px"
    fontWeight: 700
    lineHeight: 1.29
    letterSpacing: "-0.7px"
  headline-small:
    fontFamily: "Manrope"
    fontSize: "24px"
    fontWeight: 700
    lineHeight: 1.33
    letterSpacing: "-0.5px"
  title-large:
    fontFamily: "Manrope"
    fontSize: "21px"
    fontWeight: 700
    lineHeight: 1.27
    letterSpacing: "-0.4px"
  title-medium:
    fontFamily: "Manrope"
    fontSize: "16px"
    fontWeight: 700
    lineHeight: 1.5
    letterSpacing: "0.15px"
  body-large:
    fontFamily: "Manrope"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: 1.45
    letterSpacing: "0.5px"
  body-medium:
    fontFamily: "Manrope"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1.45
    letterSpacing: "0.25px"
  body-small:
    fontFamily: "Manrope"
    fontSize: "12px"
    fontWeight: 400
    lineHeight: 1.33
    letterSpacing: "0.4px"
  label-large:
    fontFamily: "Manrope"
    fontSize: "14px"
    fontWeight: 600
    lineHeight: 1.43
    letterSpacing: "0.1px"
  label-medium:
    fontFamily: "Manrope"
    fontSize: "12px"
    fontWeight: 500
    lineHeight: 1.33
    letterSpacing: "0.5px"
rounded:
  photo: "4px"
  scrubber: "6px"
  thumbnail: "12px"
  surface: "16px"
  search-sheet: "28px"
  pill: "999px"
spacing:
  photo-gap: "3px"
  xs: "4px"
  sm: "8px"
  compact: "12px"
  md: "16px"
  card: "20px"
  page: "24px"
  section: "28px"
  bottom: "32px"
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    typography: "{typography.label-large}"
    rounded: "{rounded.pill}"
    padding: "0px 24px"
  button-outlined:
    textColor: "{colors.primary}"
    typography: "{typography.label-large}"
    rounded: "{rounded.pill}"
    padding: "0px 24px"
  button-text:
    textColor: "{colors.primary}"
    typography: "{typography.label-large}"
    rounded: "{rounded.pill}"
    padding: "8px 12px"
  input-standard:
    backgroundColor: "{colors.surface-container-low}"
    textColor: "{colors.on-surface}"
    rounded: "{rounded.surface}"
    padding: "16px"
  input-search:
    backgroundColor: "rgba(224,239,234,0.65)"
    textColor: "{colors.on-surface}"
    typography: "{typography.body-large}"
    rounded: "{rounded.search-sheet}"
    padding: "14px 16px"
  input-search-dark:
    backgroundColor: "rgba(32,75,67,0.65)"
    textColor: "{colors.dark-on-surface}"
    typography: "{typography.body-large}"
    rounded: "{rounded.search-sheet}"
    padding: "14px 16px"
  chip:
    backgroundColor: "{colors.surface}"
    typography: "{typography.label-large}"
    rounded: "{rounded.pill}"
    padding: "8px"
  chip-selected:
    backgroundColor: "{colors.primary-container}"
    typography: "{typography.label-large}"
    rounded: "{rounded.pill}"
    padding: "8px"
  navigation:
    backgroundColor: "{colors.surface}"
    height: "76px"
    typography: "{typography.label-medium}"
  navigation-selected:
    backgroundColor: "{colors.primary-container}"
    textColor: "{colors.primary}"
  card:
    backgroundColor: "{colors.surface-container-low}"
    rounded: "{rounded.surface}"
  privacy-status:
    backgroundColor: "{colors.primary-container}"
    textColor: "{colors.on-primary-container}"
    rounded: "{rounded.surface}"
    padding: "20px"
  photo-suggestion:
    textColor: "{colors.on-primary}"
    rounded: "{rounded.surface}"
    height: "112px"
  photo-tile:
    backgroundColor: "{colors.surface-container}"
    rounded: "{rounded.photo}"
  date-scrubber:
    width: "48px"
    height: "48px"
    rounded: "{rounded.scrubber}"
  viewer:
    backgroundColor: "{colors.dark-surface-container-lowest}"
    textColor: "{colors.dark-on-surface}"
  bottom-sheet:
    backgroundColor: "{colors.surface}"
---

# Design System: PixelSearch

## Overview

**Creative North Star: "The photographic light table"**

PixelSearch is a calm native Android gallery: photographs supply the visual richness, while cool surfaces, charcoal text, teal actions and mint selection states make finding a remembered moment feel direct. The approved Google Photos-inspired direction combines a friendly, weighty sans with familiar Material 3 controls and dense photographic browsing.

The same world spans search, results, detail, timeline, map and privacy. Search and settings use clear reading space; photographs use a tighter contact-sheet rhythm. The viewer turns dark even when the surrounding app is light. Privacy is communicated through literal state and native controls, including the functional on-device status, rather than decorative trust claims.

**Key Characteristics:**
- Untinted personal photographs remain the richest material.
- One teal/mint control family in paired light and dark themes.
- Bundled Manrope and familiar, reachable Material 3 controls.
- Dense photo grids coexist with spacious text and reflow for enlarged text.

This is a scan of the implemented Flutter app, not a new proposal. Authority: `pixelsearch_app/lib/core/theme.dart`, the adaptive shell, the six screen implementations and shared gallery widgets. The inherited Material 3 type and button defaults were checked in the installed Flutter SDK. Native screenshots and the final review verdict corroborate the initial six-screen result. The subsequent Home scrolling refinement below is recorded from source and verified by focused/full widget suites, native light/dark captures, and direct swipe checks on the connected vivo. See `.impeccable/review/home-scroll-verification.md` for evidence and review scope.

**Units:** The portable frontmatter uses CSS `px`. Read spatial numbers as Flutter logical **dp** and font sizes/letter spacing as unscaled **sp**; these are not device pixels. Font scaling, device density and safe areas remain native. `pill: 999px` translates Flutter's `StadiumBorder`, not a literal native radius. Component dimensions are base measurements, not a reason to clip enlarged text. The sidecar's self-contained HTML/CSS specimens translate the native controls for a browser panel; they are not production app code or pixel-equivalence evidence.

## Colors

The palette is cool and lightly green, allowing photographs to provide most of the screen's saturation. Frontmatter values are authoritative; unprefixed roles are light theme, and `dark-` roles are the corresponding dark theme overrides.

### Primary

- **Deep teal / pale mint teal:** `primary` and `dark-primary` identify actions, selected navigation icons and active text.
- **Mint selection / forest selection:** `primary-container` roles sit behind selected navigation, chips and the privacy status panel. Their `on-primary-container` partners carry readable content.
- **Search wash:** the search field uses the active primary container at 65% alpha over its surface. Its focus border is the active primary color.

### Neutral

- **Daylight / charcoal:** `surface` is persistent screen chrome; `on-surface` is main text. `on-surface-variant` carries hints and secondary information.
- **Tonal containers:** lowest through highest are the app's existing surface depth ladder. Cards and standard inputs use low; image placeholders use container. The immersive viewer uses dark lowest.
- **Soft boundaries:** `outline-variant` draws input/chip boundaries and dividers; `outline` remains available to native outlined controls.

Other Material roles, including secondary containers for tonal buttons, segmented controls and the date thumb, are generated by `ColorScheme.fromSeed` from the teal seed. Error and disabled colors also remain native; they are not additional brand accents. The sidecar's eight-step OKLCH ramps are exploratory swatches, not replacement production tokens.

**The Photo Color Rule.** Keep ordinary gallery photographs untinted. Use a dark scrim only where a suggestion or memory caption sits on its image.

## Typography

**Display and body font:** bundled Manrope (`assets/fonts/Manrope.ttf`), available offline. Flutter handles glyph fallback; browser specimens use `Manrope, sans-serif`. There is no separate display or mono face.

The hierarchy uses heavy, slightly tightened headlines and regular body text. Sizes are native Material roles with explicit app overrides; this is not a fixed mathematical ratio. The frontmatter includes inherited English-script metrics where they are actually used; Flutter retains locale-specific geometry.

| Role | Intended use |
|---|---|
| Headline large | Primary search and privacy statements; 36sp / 800. |
| Headline medium | Screen-level thematic headings; 28sp / 700. |
| Headline small | Brand and memory-story titles; 24sp / 700. |
| Title large | App bars and library/month headings; 21sp / 700. |
| Title medium | Section names, result counts and photo titles; 16sp / 700. |
| Body large / medium | Reading copy and hints; 16sp / 14sp, regular. |
| Body small | Compact library count and supporting metadata; 12sp, regular. |
| Label large | Buttons and chips; 14sp / 600, sentence case. |
| Label medium | Navigation labels; 12sp, 500 inactive and 700 selected. |

**The Reading Space Rule.** When text grows, reflow or condense the surrounding composition before reducing readable type.

## Layout

The reading gutter is usually 24dp. The photo gallery has equal 12dp side margins, 3dp gaps and square tiles. Home computes columns as `floor((availableWidth - 24) / 128)`, clamped to 3–8; the shared results grid uses `floor(availableWidth / 125)`, also clamped to 3–8. Their phone expression is three columns. Keep these two actual calculations distinct.

The app switches from a four-destination bottom bar to a labeled navigation rail at 700dp width. The bar's content height is 76dp before system safe-area insets. Standard app bars are 64dp high; Search uses 56dp. The shell preserves Search, Timeline, Map and Privacy in that order.

Home is one vertical scroll surface: dragging through its introduction, supporting content, suggestions, library summary or photos moves the same page. The local-status/Find a moment introduction scrolls away, while the variable-height search field pins below the app bar on a full-width opaque surface. Hints, notices, suggestions and the summary continue beneath it with the lazy dated gallery. Short and empty libraries retain the full body viewport. This is the user-requested refinement of Home, not a new visual world.

Home shows its full introductory block only above 720dp device height and while scaled 16sp text is at most 23sp. Photographic suggestions require over 400dp of Home body height and scaled 14sp text below 21sp; otherwise they become scrollable text chips. Suggestion covers are 112dp high, with widths clamped to 138–240dp and 8dp gaps. At scaled 14sp text of 21sp or more, the library title uses a full row and the count/actions move below it. Add photos becomes a labeled action at 410dp width when space and state permit.

Timeline's date controls stack when their available width is below 330dp or scaled 16sp exceeds 24sp. Its story height grows from 248dp to 300dp with enlarged text. Appearance segments turn vertical below 330dp available width when scaled 14sp exceeds 20sp. These checks use local layout constraints, not one universal device breakpoint.

The date scrubber is only a positioned 48×48dp thumb. It overlays the balanced gallery without reserving a column; no full-height hit surface exists. Date-header counts leave room for it. The thumb supports drag, tap-to-choose-month and semantic increment/decrement. It follows the gallery below the pinned search field; date jumps account for the measured content before the gallery and the pinned header height. The lazy gallery supplies its exact total extent, and each scrub drag keeps the travel range captured at pointer-down so the changing header position does not move the drag target unpredictably.

## Elevation & Depth

Persistent surfaces are flat and tonal. App bars, cards and bottom navigation explicitly use zero elevation, and app bars/sheets remove surface tint. One-dp boundaries separate navigation, fields and lists. Native Material buttons, menus, dialogs and modal sheets retain their standard feedback and elevation behavior; there is no custom box-shadow vocabulary.

**The Quiet Surface Rule.** Use tonal surfaces and thin boundaries for persistent chrome; keep custom ornamental shadows out of the gallery. Native Material feedback and modal depth remain appropriate.

Photo suggestions use a transparent-to-dark-green caption scrim ending at `#001612` with 70% alpha; memory stories end at `#001B16` with roughly 86% alpha. These protect white captions. Ordinary photo tiles have no overlay. Motion comes from Material ink, navigation and paging; button style transitions inherit the SDK's 200ms theme-change duration. Results tiles share a Hero with the viewer; the viewer disables that Hero when native reduced animation is requested. Home's indexed tiles currently do not supply the matching Hero.

## Shapes

Photo tiles use slight 4dp corners; the date thumb uses 6dp. Timeline row covers use 12dp, while cards, photographic suggestions and stories use 16dp. Search uses a broad 28dp capsule radius. Modal sheets round only their top corners to 28dp and show a native drag handle. Chips, buttons and navigation indicators use native pill forms. Images clip to their local shape; map pins use their own outlined thumbnail silhouette.

## Components

### Buttons

Quiet native actions. Filled buttons use primary/on-primary; outlined and text buttons use primary text. All four themed button families, including icon buttons, request a minimum 48×48dp. Filled/outlined base padding is 24dp horizontally; text-button base padding is 12dp horizontally and 8dp vertically. Flutter adjusts padding for text scale and icon variants. Tonal buttons use the generated secondary container. Preserve native disabled states, ink response, keyboard focus and accessible tooltips.

### Inputs / Fields

Standard fields use a low tonal container, 16dp corners and a thin outline-variant boundary. Focus changes the boundary to a 2dp primary stroke. Search is the borderless, mint-wash capsule variant with a search icon and a 48dp trailing voice/clear action. On Home it pins within the shared scroll surface; the same field preserves editing focus when typing transitions Home to Results. It remains editable on Results. Labels and chips come from the real query and indexed data.

### Chips

Pill-shaped, outlined controls on the surface, with mint container fill for selection and label-large text. Search filters use a horizontally scrollable row. Compact library suggestions preserve the same query action when photographic covers no longer fit. Native state feedback and hit targets remain active.

### Cards / Containers

General cards use the low tonal surface and 16dp shape without elevation. The privacy status panel uses the primary container, its matching foreground, 20dp padding and a shield icon; content changes with loaded/offline state. Timeline rows are flatter: a surface-colored tappable row with a 104dp square, 12dp-corner cover and text beside it.

### Navigation

Four named destinations use native Material icons, a mint selected indicator, primary selected content and subdued inactive content. Labels remain visible in both the bottom bar and wide rail. A thin, half-opacity outline-variant divider separates the bottom bar from content. Native SafeArea handles device chrome.

### Photographic suggestions and stories

Search suggestions pair a runtime library cover with a literal indexed-label query, white label and search icon. Tapping starts that query. Memory stories use a taller photo, headline-small caption, photo count and play action. Their scrims are caption support, not a general photo filter. The sidecar embeds a bundled sample photo solely to demonstrate this visual pattern.

### Photo grid and viewer

Tiles crop to a square and expose a semantic photo title/date. The viewer presents the original image on dark-lowest framing with swipe and zoom (1–6×), date/count navigation and wrapping text actions for Details, Labels, Caption and, when available, Why this matched. Metadata sits beneath the image rather than on top of it. Details use the native modal sheet.

### Map and privacy

Map content uses verified photo positions and thumbnail/count pins. Consent and offline states keep explanations, a Map privacy action and available local photo browsing usable. OpenStreetMap attribution stays visible. Privacy uses stateful native switches and an adaptive appearance selector; the shield/status text is functional feedback and does not establish a generic decorative heading style.

## Do's and Don'ts

### Do:
- Do keep Home on one vertical scroll surface, with Find a moment scrolling away and search remaining visible on an opaque pinned header.
- Do use the paired light/dark semantic roles from AppTheme instead of introducing an independent palette.
- Do keep gallery margins balanced, photo gaps narrow, and captions outside ordinary grid tiles.
- Do preserve the 48dp minimum action targets and native text scaling; reflow the library summary and compact optional header material when space is tight.
- Do use actual indexed photographs, counts, labels and verified locations in production; the preview photograph and review fixtures are illustrative.
- Do retain functional on-device processing status, explicit online consent and usable offline map content.

### Don't:
- Don't reserve a permanent blank column for date navigation or place an invisible full-height touch rail over photo edges.
- Don't turn the functional status line into a generic decorative eyebrow pattern.
- Don't cover ordinary gallery photographs with labels, gradients or accent tints; caption scrims belong to the existing suggestion and story patterns.
- Don't add unsupported favorites, backup, sharing or encryption claims to make a screen look complete.
- Don't treat light OpenStreetMap tiles in dark mode, absent Home hero continuity or raw mockup pixel drift as new design-system rules.

**Not canonized:** The dark map currently retains light provider cartography, and Home lacks the viewer continuity already used by Results. These are observed limitations, not reusable visual rules. Native runtime-image equivalence was accepted by review; raw comp similarity remains 0.6642 / drift, not a pixel-match pass. Review fixtures do not define production library content. The follow-up verdict withdrew the functional-status objection and resolved the gallery/thumb/large-text findings.
