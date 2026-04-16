# FEAT-003: Re-center on Rome Button — Design Spec

**Date:** 2026-04-16
**Status:** Approved

## Overview

Add a button overlaid on the map that instantly resets the camera to Rome city center.

## Behavior

- Tapping the button sets `cameraPosition` to Rome center `(41.899159, 12.473065)` with span `0.027°` (matching the clustering threshold).
- The transition is instant — no animation. Direct assignment to `cameraPosition` with no `withAnimation`. This avoids a potentially jarring long pan for users outside Europe.

## Appearance

- White capsule button using `.buttonStyle(.bordered)`, `.tint(.white)`, and `.clipShape(.capsule)`.
- Label: `building.columns` SF Symbol + text "Rome".
- Drop shadow via `.shadow(radius: 4)`.
- Positioned bottom-leading with 16pt leading padding and safe-area-aware bottom inset via `.safeAreaInset(edge: .bottom)`.

## Implementation

**File changed:** `ContentView.swift` only. No changes to `PlaceViewModel`.

- Define a private constant `romeRegion: MKCoordinateRegion` at the top of `ContentView` (center `41.899159, 12.473065`, span `0.027°`). Naming it explicitly makes it reusable when FEAT-004 (GPS re-center) is added.
- Add `.overlay(alignment: .bottomLeading)` to the `Map` view containing the button.
- Button action: `cameraPosition = .region(romeRegion)`

## Future Compatibility

The `romeRegion` constant and bottom-leading placement leave the bottom-trailing corner free for the FEAT-004 GPS re-center button, which pairs naturally in the same zone of the screen.

## Out of Scope

- No haptic feedback.
- No visibility toggling (button is always visible).
- No changes to clustering threshold — 0.027° is already established in `PlaceViewModel`.
