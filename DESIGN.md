# Tracklet design tokens

## Purpose and source of truth

Tracklet's visual identity uses Outfit and Satoshi typography, a violet primary, teal secondary, peach tertiary, cool neutral surfaces, and separately tuned light and dark themes. Tokens exist so shared design decisions change in one place while transit, map, permission, and status roles remain explicit.

The Flutter implementation is authoritative: [`lib/design_system/tokens/`](lib/design_system/tokens/) defines runtime values and [`lib/design_system/theme/tracklet_theme.dart`](lib/design_system/theme/tracklet_theme.dart) maps them to Flutter `ThemeData`. The portable machine-readable view is the Material Design System Package (DSP) at [`design_tokens/dsp.json`](design_tokens/dsp.json), importing [`design_tokens/data/tokens.json`](design_tokens/data/tokens.json). Keep both representations synchronized when changing tokens.

Google's [Material design-token guidance](https://m3.material.io/foundations/design-tokens/how-to-use-tokens) recommends Material Design Package (DSP) export for interchange with the Material Theme Builder. Material's own token taxonomy separates reference palette values (`md.ref.palette.*`) from semantic system roles (`md.sys.color.*`), with light and dark role assignments. Tracklet mirrors that separation in Dart as `TrackletPalette` and `TrackletColors`; product colors remain Tracklet values rather than being mislabeled as Google's generated tonal palette.

The machine-readable package follows the published [DSP 1.0 format](https://github.com/AdobeXD/design-system-package-dsp), which is the package format Google's guidance points to: `dsp.json` imports data files, and each data file carries `dsp_spec_version` plus typed `entities` with `class`, `type`, `id`, `value`, and descriptive metadata. DSP is the applicable interchange specification; Google does not define a separate JSON schema for Tracklet. No `$schema` URI or custom Google schema is asserted.

## Taxonomy

| Domain | Flutter source | DSP representation | Use |
| --- | --- | --- | --- |
| Reference palette primitives | `TrackletPalette` in `tokens/colors.dart` | DSP `class: token`, `type: color`; IDs start `palette-` | Literal colors stored once; analogous to Material `md.ref.palette.*` |
| Semantic color roles | `TrackletColors` in `tokens/colors.dart` and `ThemeData.colorScheme` | DSP `class: token`, `type: alias`; IDs start `color-` | Brand, surface, text, feedback, transit, map, and feature roles; analogous to Material `md.sys.color.*` |
| Spacing and sizing | `TrackletSpacing` in `tokens/spacing.dart` | `type: size`; IDs start `space-` | Flutter logical pixels (`dp` in the package), scale steps, component dimensions, icon and avatar sizes |
| Corner radii | `TrackletRadii` in `tokens/radii.dart` | `type: size`; IDs start `radius-` | Base radius scale and semantic shape roles |
| Typography | `TrackletTypography` in `tokens/typography.dart` | `type: size` font-size, letter-spacing, and line-height primitives plus `type: custom` font weights and styles; IDs start `type-` | Font-size scale in logical text pixels and JSON-encoded `TextStyle` property records |
| Elevation | `TrackletShadows` in `tokens/shadows.dart` | `type: size` level values and `type: custom` shadow records | Flutter elevation levels and `BoxShadow` records, including offset, blur, spread, and color |
| Motion | `TrackletMotion` in `tokens/motion.dart` | Runtime-only | Durations, curves, and reduced-motion handling |
| Component defaults | `TrackletTheme` and `components/` | Semantic tokens referenced by component code | Flutter Material defaults and Tracklet component contracts |

Palette entries are primitives because they hold raw values. Semantic colors are aliases because they say what a color means in the interface. Spacing scale entries such as `sm` and `md` are primitives; dimensions such as `minTouchTarget` and `cardPadding` are semantic aliases when their value is shared. Specialized tokens such as `mapRoad` remain semantic even if their color matches another role: their meaning and ownership differ.

## Naming rules

1. In Dart, use `Tracklet`-prefixed types and lower camel case for static members: `TrackletColors.primary`, `TrackletSpacing.minTouchTarget`, `TrackletRadii.roundedCard`.
2. In DSP, use stable lowercase kebab-case IDs with a domain prefix: `palette-ff6f61ef` (ARGB primitive), `color-primary`, `space-min-touch-target`, `radius-rounded-card`, `type-size-14`, `type-body-medium`, `elevation-card`. These are Tracklet DSP IDs; the DSP entity structure remains the published interchange format.
3. Name semantic colors for purpose, not hue. Use `textSecondary` or `busLiveBg`, not a new `gray2` or `green` role.
4. Use `Dark` only for explicit dark-theme counterparts where the role needs a distinct value. Unchanged roles use one shared token; do not duplicate light and dark values just to fill a pair.
5. Use aliases for repeated values and reserve literal colors for `TrackletPalette`. Add a palette primitive only when it is a real new color decision.
6. Use the existing spacing and radius scales where intent matches. Add a semantic size only for a real component contract; do not add synonyms for the same role.

## Themes and semantic roles

`TrackletTheme.lightTheme` and `TrackletTheme.darkTheme` explicitly map Tracklet values into the complete Material 3 `ColorScheme`, including fixed brand roles, surface containers, inverse roles, tint, shadow, and scrim, then define component defaults. Deprecated Material roles are not redundantly set; Flutter derives their compatibility values from current roles. `TrackletColors.adaptive*` resolves context-sensitive roles from `Theme.of(context).brightness`. Explicit roles such as `primaryContainerDark` and `busLiveBgDark` support custom surfaces and badges that do not read a `ColorScheme` slot directly.

The dark theme intentionally keeps the same violet brand primary while changing surfaces, text, outlines, and containers. Status roles pair foreground and container colors (`success` / `successContainer`, `busLive` / `busLiveBg`); use the paired role rather than placing a foreground color directly on an unrelated surface. Feature colors for maps and permissions remain distinct semantic groups because they are used by non-Material surfaces.

DSP aliases use the DSP reference form `{token-id}`. For example, the runtime declaration `TrackletColors.busLive = success` is represented as an alias to `color-success`, which in turn resolves to a palette primitive. The `theme:dark`, `theme:light`, and `theme:all` tags identify intended theme coverage; they do not replace Flutter's runtime theme selection. Material role naming in Dart remains idiomatic (`primary`, `surfaceContainerLow`, `inversePrimary`) and each `ColorScheme` maps those roles to explicit Tracklet tokens.

The following DSP entity is copied from the current package; it demonstrates a semantic alias to the single stored violet reference color:

```json
{
  "class": "token",
  "type": "alias",
  "id": "color-primary",
  "name": "primary",
  "value": "{palette-ff6f61ef}",
  "description": "Tracklet semantic color role primary.",
  "last_updated": "2026-10-20T00:00:00.000Z",
  "last_updated_by": "Tracklet maintainers",
  "tags": ["color", "semantic", "theme:all"]
}
```

## Component usage

Consume semantic roles and component tokens rather than literals:

```dart
Container(
  padding: const EdgeInsets.all(TrackletSpacing.cardPadding),
  decoration: BoxDecoration(
    color: TrackletColors.adaptiveSurfaceElevated(context),
    borderRadius: TrackletRadii.roundedCard,
    boxShadow: TrackletShadows.adaptiveCard(context),
  ),
  child: Text('Next bus', style: TrackletTypography.titleMedium),
)
```

For repeated patterns, use the shared components, which already consume the same token layer:

```dart
TrackletCard(
  child: TrackletButton(label: 'View route', onPressed: openRoute),
)
```

Use a `Theme.of(context).colorScheme` role when implementing a standard Material control. Use `TrackletColors` when a custom Tracklet surface, map, or transit status has a product-specific semantic role. Context-free code may use constants, but should not choose between light and dark with manual branching when an adaptive helper or theme role exists.

## Migration guidelines

1. Search all callers of a token before renaming or removing it. Preserve the value and behavior of existing semantic roles during migration.
2. If adding a color, add its single literal to `TrackletPalette`, expose the intended role through `TrackletColors`, then add/update its DSP primitive and alias with a description and theme tag.
3. If adding spacing, sizing, radius, typography, or elevation, extend the existing token file and corresponding DSP entity using the same domain prefix and units.
4. Migrate shared components first, then feature callers. Prefer a semantic token or standard Flutter `ThemeData` slot; keep genuinely unique geometry local only when it has a distinct layout purpose. Preserve values exactly when replacing an existing literal so tokenization does not redesign the UI.
5. Validate DSP imports and alias references, token ID casing, light/dark semantic coverage, both theme definitions, and representative component rendering. Run the relevant Flutter tests, `flutter analyze`, and the repository architecture checker before accepting a token change.
6. Keep machine-readable DSP values and Dart runtime values in sync. The DSP package is for design-tool interchange; it is not loaded by Flutter at runtime.

## Current integration points

The shared system exports `TrackletTheme`, colors, spacing, radii, shadows, typography, and reusable components through `lib/design_system/design_system.dart`. The reusable card and button components are `TrackletCard` and `TrackletButton`. Feature-specific colors remain in `TrackletColors` for map cartography, permission illustrations, transit status, notifications, and onboarding gradients.
