# FEAT-008: Two-Tone Splash Screen Background — Design Spec

## Summary

Replace the plain white `LaunchScreen.storyboard` background with a vertical 50/50 split: left half dark red RGB(112, 12, 20), right half amber RGB(243, 138, 21). The existing centered `LaunchIcon` remains unchanged. Colors are fixed and non-adaptive (identical in light and dark mode).

## Design

### Change

Single file change: `thirstyinrome/LaunchScreen.storyboard`.

- Remove the solid white `backgroundColor` from the root view (set to clear).
- Add two `UIView` subviews before the existing `imageView` in the subviews list so the icon renders on top:
  - **leftHalfView**: anchored to leading/top/bottom of superview, width = superview.width × 0.5, color RGB(112, 12, 20) in sRGB, non-adaptive.
  - **rightHalfView**: anchored to trailing/top/bottom of superview, leading edge = leftHalfView trailing, color RGB(243, 138, 21) in sRGB, non-adaptive.
- `LaunchIcon` imageView stays centered on the root view (constraints unchanged); z-order places it above both color views.

### Non-adaptive colors

Colors are specified using `colorSpace="custom" customColorSpace="sRGB"` with explicit normalized float values — no system color references. This ensures identical appearance in both light and dark mode.

### Auto Layout

| View | Leading | Trailing | Top | Bottom | Width |
|------|---------|----------|-----|--------|-------|
| leftHalfView | = superview leading | — | = superview top | = superview bottom | = superview.width × 0.5 |
| rightHalfView | = leftHalfView trailing | = superview trailing | = superview top | = superview bottom | — |
| LaunchIcon | centerX = superview centerX | — | centerY = superview centerY | — | 200pt fixed |

## Acceptance Criteria

- `LaunchScreen.storyboard` background replaced with two `UIView` subviews — left half RGB(112,12,20), right half RGB(243,138,21).
- The vertical split falls exactly at the horizontal midpoint on all device sizes.
- Colors are non-adaptive — identical in both light and dark mode.
- Existing centered `LaunchIcon` image remains centered over both halves.
- Build succeeds and all existing tests pass.

## Out of Scope

- No asset catalog changes.
- No icon image changes.
- No other UI modifications.
