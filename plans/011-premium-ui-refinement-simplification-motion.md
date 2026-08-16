# Plan 011: Premium UI/UX refinement, simplification & motion pass

**Status: DONE**

A deliberate senior-level UI/UX refinement pass on the existing GST
Calculator. No redesign, no new visual language, no changes to the GST
calculation UX, GST math, money reconciliation, history logic, PDF/CSV
behavior, backup behavior, persistence, or the semantic GST colors.

## Goals

Make the existing calculator feel like a polished, manually designed premium
utility app rather than an AI-generated Flutter interface — with the
icon-derived brand palette (Plan 007) as the fixed identity.

## What changed

### 1. Invoice removed entirely (follow-up)
- The `Invoices` destination was first removed from the bottom dock (leaving
  exactly three destinations: Calculate / History / Settings, rebalanced by
  the existing `Expanded` row — no empty fourth slot), then, on the user's
  request, the invoice function was removed completely.
- Deleted feature code: `lib/features/invoice/`, `lib/features/hsn_lookup/`,
  `lib/features/business_profile/`; the "Generate Invoice" quick action was
  removed from the calculator; invoice-only dependencies (printing,
  image_picker, pdf, path_provider) dropped from `pubspec.yaml`; CSV export
  no longer emits the invoice section; dead `sacColor`/`hsnColor` theme slots
  and the unused `DateFormatter.compact` were removed; README, privacy
  policy, and Android backup rules updated.
- Dock lightened: height 62 → 58, radius 26 → 20, softer shadow, smaller
  selected indicator pill (42×28), tighter bottom margin.

### 2. Custom accent setting removed
- Settings no longer shows an Accent Color / Custom Accent row, swatches,
  "Reset", or any accent picker.
- `settings_provider.dart`: `accentColor` field, `setAccentColor` /
  `clearAccentColor`, and the `accent_color` pref key were removed from the
  model. A legacy persisted `accent_color` value is simply ignored (safe
  backward compatibility — the stored value is inert).
- `theme_controller.dart`: `accentColorProvider` removed.
- `app_theme.dart`: `buildLightTheme` / `buildDarkTheme` no longer accept an
  `accentColor`; `onPrimary` is always white on the brand primaries.
- `app.dart`: accent watch removed.
- Onboarding slide 3 copy no longer advertises "pick an accent colour".

### 3. Typography — single modern sans family
- Dropped the Fraunces serif/display face from the UI. The text theme now
  uses Manrope at every level; hierarchy comes from size/weight, not a
  decorative serif.
- App header title ("GST Calculator") renders in Manrope 28 w700 (was serif).
- Amount input and result totals use Manrope with tabular figures and strong
  numeric weights (40–42sp, w700).
- Section labels standardized via a shared `SectionLabel` (12sp, w700,
  letter-spacing 1.2, quiet uppercase).

### 4. Pill controls — shared primitives + alignment
- New `lib/core/widgets/brand_chip.dart`: one recipe for icon/label
  alignment, radius (12, not a capsule), padding, selected state
  (solid brand-primary fill, high-contrast content), and a 0.97 press scale
  (120ms). Used by the GST rate chips and quick amount chips.
- Quick amount chips are now quiet tinted secondary actions (+ icon, brand
  tint, no selected state).
- Segmented controls (Add/Remove GST, Intra/Inter-State) reworked: subtle
  radius track, solid brand-primary sliding thumb for the primary control,
  quiet tonal thumb for the secondary, no shadow/glow, consistent
  icon/label centering, 200ms easeOutCubic thumb transition.

### 5. Amount input
- Focus border restrained to a 1.5px brand-primary line (no heavy outline),
  radius 20 → 16.
- ₹ prefix and digits share the Manrope family/weight so the symbol belongs
  to the amount; tighter vertical padding.
- Cursor/selection colors come from the brand system via
  `textSelectionTheme`.

### 6. Result surface
- 'Result' header and the hero total now use Manrope.
- Empty state is much lighter: compact row (36px icon), subtle fill + thin
  border, same text guidance ("Your result appears here" / "Enter an amount
  and pick a rate…").
- Empty ⇄ result swap animates (220ms fade + slight rise) via
  `AnimatedSwitcher`; the hero total keeps its existing 220ms number
  transition.

### 7. Motion & touch feedback
- One consistent language: press 120ms, segment/chip selection 180–220ms,
  result appearance 220–280ms, dock transition 220ms; `easeOutCubic`.
- Chips use press-scale only (no stacked ripple+glow+scale).

### 8. Dark/light hierarchy
- Dark surfaces nudged apart: card `#161D2F → #182136`, interactive input
  `#1C2436 → #212B42` — background < card < input now reads clearly.
- Light mode unchanged (already clean/cool with white cards and navy text).
- Brand blue reserved for selected/active/focused/important states.

### 9. Protected behaviors untouched
GST math, rate logic, CGST/SGST/IGST semantics, money.dart, gst_math.dart,
history behavior/persistence, CSV export, backup XML, privacy, platform
config, web build, Plan 005 accessibility, Plan 006 contrast safety, Plan
007 BrandColors, launcher icon/assets.

## Validation

- `flutter analyze` — clean (0 issues).
- `flutter test` — all 887 tests pass (the invoice/HSN/business-profile
  regression tests and their mocks were removed along with the feature; a
  new focused test asserts the calculator exposes no invoice entry points,
  and the calculator, settings, history, and brand tests remain).
- Existing smoke tests re-verified: 360×640 and 2.0× text scale still render
  without horizontal/vertical overflow; light and dark themes both pass.
- History CSV export test keeps a `path_provider` mock for the share flow.
