# REFACTOR-004: Extract LocationButton Subview

**Date:** 2026-04-17
**Backlog item:** REFACTOR-004

## Problem

`ContentView` is 199 lines and handles map rendering, clustering branch logic, the Rome button, the GPS button state machine, the GPS wait toast, and the settings alert. The GPS button and its supporting logic are a natural, self-contained unit that can be extracted to improve readability and reduce ContentView's surface area.

## Goal

Extract the GPS location button, its state machine, the "Waiting for GPS signal…" toast, and the Settings alert into a new `LocationButton` subview. No behavior changes.

## Design

### New file: `thirstyinrome/LocationButton.swift`

Contains:
- `LocationButtonState` enum (moved from `ContentView.swift`): `.ready`, `.noFix`, `.unauthorized`
- `LocationButton` struct conforming to `View`

**`LocationButton` internals:**
- `@Environment(PlaceViewModel.self)` — reads `authorizationStatus` and `userLocation`
- `@State private var showGPSWaitToast: Bool`
- `@State private var showSettingsAlert: Bool`
- `@State private var toastDismissTask: Task<Void, Never>?`
- `let onCenterOnUser: (CLLocation) -> Void` — called when the user has a GPS fix and taps the button; ContentView uses this to move the camera
- Computed props moved from ContentView: `locationButtonState`, `locationButtonIcon`, `locationButtonColor`
- `handleLocationButtonTap()` moved from ContentView

**`LocationButton.body`** is a `VStack` with the toast above the button. The toast animates in/out above the capsule button. The settings alert is attached as a modifier on the `VStack`.

Note: the toast position changes slightly — currently it is a centered-bottom overlay on the map (via a sibling overlay with `.padding(.bottom, 80)`); after extraction it appears above the GPS button in the bottom-trailing area. This is an acceptable visual simplification for a structural refactor.

### Changes to `ContentView.swift`

**Removed:**
- `LocationButtonState` enum
- `@State var showGPSWaitToast`, `showSettingsAlert`, `toastDismissTask`
- `locationButtonState`, `locationButtonIcon`, `locationButtonColor` computed props
- `handleLocationButtonTap()` method
- `.overlay(alignment: .bottomTrailing)` GPS button overlay
- `.overlay(alignment: .bottom)` toast overlay
- `.alert("Location Access Required", ...)` modifier

**Added:**
```swift
.overlay(alignment: .bottomTrailing) {
    LocationButton { location in
        cameraPosition = .region(MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: Self.zoomedInSpan, longitudeDelta: Self.zoomedInSpan)
        ))
    }
    .safeAreaPadding(.bottom)
    .padding(.trailing, 16)
}
```

`zoomedInSpan` stays on `ContentView` — it is also used by the Rome button region and the user-location `onChange` handler.

## Out of Scope

- No behavior changes
- No new tests (pure structural refactor; no new logic to verify)
- Rome button is not extracted in this refactor

## Acceptance Criteria

- `LocationButtonState` enum lives in `LocationButton.swift`, not `ContentView.swift`
- `ContentView` contains no GPS-specific state vars, computed props, or methods
- The GPS button, toast, and settings alert behavior is identical to before (toast position moves to above the GPS button in bottom-trailing area)
- Build succeeds and all existing tests pass
