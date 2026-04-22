# FEAT-007: Compass / Heading-Up Map Mode — Design Spec

**Date:** 2026-04-19
**Status:** Approved

---

## Overview

A toggle button in the top-right corner lets the user switch between north-up (default) and heading-up mode. In heading-up mode the map rotates so the device's compass direction points to the top. The user location dot always shows a directional cone when heading data is available, regardless of map orientation mode.

---

## Architecture

Two files change. No new files.

### `PlaceViewModel`

- Add `var userHeading: CLHeading?` — published so `UserAnnotation()` can render the heading cone.
- Call `locationManager.startUpdatingHeading()` alongside `startUpdatingLocation()` inside `locationManagerDidChangeAuthorization` (when authorized). Heading updates run continuously whenever location is active — not toggled by the button.
- Add `locationManager(_:didUpdateHeading:)` delegate method — sets `userHeading` from `newHeading` when `headingAccuracy >= 0`.

### `ContentView`

- Add `@State var isHeadingUp: Bool = false`.
- Add a new `.overlay(alignment: .topTrailing)` containing the compass `Button`.
- **Toggle on:** set `cameraPosition = .userLocation(followsHeading: true, fallback: cameraPosition)`.
- **Toggle off:** set `isHeadingUp = false`; leave `cameraPosition` at its current value (no jump).
- **Pan exit (and Rome/GPS button exit):** detect when `cameraPosition` transitions away from `.userLocation(followsHeading:)` tracking — via pattern matching on `cameraPosition` in `onChange(of:)` or a `followsUserLocation` property if available. Set `isHeadingUp = false`. This single check covers all exit paths — user pan, Rome button, GPS re-center — because all of them cause MapKit to break out of `.userLocation(followsHeading:)` tracking. Exact API to be confirmed during implementation.

---

## UI — Compass Button

- **Position:** `.overlay(alignment: .topTrailing)` with `.safeAreaPadding(.top)` + `.padding(.trailing, 16)`.
- **SF Symbol:** `safari` (compass rose), label `"Heading Up"`.
- **Style:** `.borderedProminent` + `.clipShape(.capsule)` + `.shadow(radius: 4)` — matches Rome and GPS buttons.
- **Tint:**
  - North-up (off): `Color(UIColor.systemGray)`
  - Heading-up (on): `.blue`

---

## UI — Directional Cone

`UserAnnotation()` is already on the map. When `startUpdatingHeading()` is active, MapKit automatically renders the heading accuracy cone on the blue user dot. No custom annotation needed.

The cone is visible in **both** north-up and heading-up modes whenever heading data flows (i.e., whenever location is authorized).

---

## Data Flow

```
App launches / location authorized
  └─ startUpdatingLocation() + startUpdatingHeading()
       └─ didUpdateHeading → userHeading published
            └─ UserAnnotation() renders cone (both modes)

User taps compass button (off → on)
  └─ isHeadingUp = true
  └─ cameraPosition = .userLocation(followsHeading: true, fallback: current)
       └─ MapKit rotates map to match heading continuously

User taps compass button (on → off)
  └─ isHeadingUp = false
  └─ cameraPosition unchanged (stays at current position)

User pans / taps Rome / taps GPS while heading-up
  └─ MapKit breaks out of .userLocation(followsHeading:) tracking
  └─ onMapCameraChange fires: cameraPosition.followsUserLocation == false
  └─ isHeadingUp = false (automatic — no per-button handling needed)
```

---

## Edge Cases

| Scenario | Behaviour |
|---|---|
| Simulator / no compass hardware | `didUpdateHeading` never fires; cone never appears; button still tappable; map doesn't rotate. No crash. |
| Location not authorized | `startUpdatingHeading()` not called; cone absent; heading-up button tappable but `MapCameraPosition.userLocation(followsHeading:)` falls back silently. |
| `headingAccuracy < 0` | `userHeading` not updated; stale or absent cone. MapKit handles accuracy display internally. |
| `hasJumpedToUserLocation` | Heading-up sets a tracking camera; `onChange(of: viewModel.userLocation)` guard (`!hasJumpedToUserLocation`) prevents conflicting camera jumps. |

---

## Testing

No new unit tests. The existing `PlaceTests.swift` suite (JSON loading) must continue to pass. Build must succeed on `platform=iOS Simulator,OS=latest,name=iPhone 17`.

Manual verification on device: confirm cone appears in north-up, map rotates in heading-up, pan exits heading-up.

---

## Acceptance Criteria (from backlog)

- [ ] A compass/heading toggle button appears in the top-right corner (`safari` SF Symbol).
- [ ] Tapping enters heading-up mode: map rotates to follow `CLLocationManager` heading.
- [ ] The user location blue dot shows a directional cone in both north-up and heading-up modes (always, when heading data flows).
- [ ] Tapping the button again returns to north-up mode (cone remains visible).
- [ ] Heading updates do not interfere with user panning or the Rome/GPS re-center buttons.
- [ ] Build succeeds and all existing tests pass.
