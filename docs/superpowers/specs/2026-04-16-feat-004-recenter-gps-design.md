# FEAT-004: Re-center on GPS Button — Design Spec

**Date:** 2026-04-16
**Status:** Approved
**Branch:** `feat/feat-004-recenter-gps`

## Overview

Add a button overlaid on the map (bottom-trailing) that re-centers the camera on the user's current GPS position. The button is always visible and reflects location state through color and icon.

## Button States

| State | Condition | Color | SF Symbol |
|-------|-----------|-------|-----------|
| Ready | Authorized + fix available | Blue | `location.fill` |
| No fix | Authorized + no fix yet | Red | `location.slash.fill` |
| Unauthorized | `.notDetermined`, `.denied`, `.restricted` | Grey | `location.fill` |

## Tap Behavior

- **Ready (blue):** Set `cameraPosition` to the user's current location with span `0.01°`. Instant, no animation.
- **No fix (red):** Show a brief overlay message "Waiting for GPS signal…" that auto-dismisses after 2 seconds via `DispatchQueue.main.asyncAfter`.
- **Unauthorized — `.notDetermined` (grey):** Call `viewModel.requestAuthorization()` to trigger the system permission dialog.
- **Unauthorized — `.denied` / `.restricted` (grey):** Show a SwiftUI `.alert` titled "Location Access Required" with message "To re-center on your position, enable Location in Settings." and an "Open Settings" button that deep-links to `UIApplication.openSettingsURLString`.

## PlaceViewModel Changes

1. Add `var authorizationStatus: CLAuthorizationStatus = .notDetermined` (observed by SwiftUI).
2. Update `locationManagerDidChangeAuthorization` to set `self.authorizationStatus = manager.authorizationStatus`.
3. Add `func requestAuthorization()` that calls `locationManager.requestWhenInUseAuthorization()`.
4. Add `didFailWithError` delegate method: nil out `userLocation` when `(error as? CLError)?.code == .locationUnknown` so the button transitions to red when GPS signal is lost (e.g. indoors).
5. Set `locationManager.distanceFilter = 10` (metres) in `setupLocationManager()` to avoid redundant updates while stationary.

## ContentView Changes

**New private enum** (inside `ContentView.swift`):
```swift
private enum LocationButtonState {
    case ready, noFix, unauthorized
}
```

**New computed property:**
```swift
private var locationButtonState: LocationButtonState {
    switch viewModel.authorizationStatus {
    case .notDetermined, .denied, .restricted:
        return .unauthorized
    case .authorizedWhenInUse, .authorizedAlways:
        return viewModel.userLocation != nil ? .ready : .noFix
    @unknown default:
        return .unauthorized
    }
}
```

**New state:**
```swift
@State private var showGPSWaitToast = false
@State private var showSettingsAlert = false
```

**GPS button** (`.overlay(alignment: .bottomTrailing)`):
- Label: `Label("My Location", systemImage: locationButtonIcon)`
- `locationButtonIcon`: `"location.slash.fill"` when `.noFix`, `"location.fill"` otherwise
- `.tint(locationButtonColor)`: `.blue` / `.red` / `.gray`
- Same capsule/bordered/shadow styling as the Rome button
- `.safeAreaPadding(.bottom)` + `.padding(.trailing, 16)`

**Toast overlay** on the `Map`:
```swift
.overlay(alignment: .bottom) {
    if showGPSWaitToast {
        Text("Waiting for GPS signal…")
            .padding(.horizontal, 16).padding(.vertical, 8)
            .background(.regularMaterial, in: Capsule())
            .transition(.opacity)
    }
}
```
Auto-dismissed via `DispatchQueue.main.asyncAfter(deadline: .now() + 2)`.

**Settings alert** chained onto the Map:
```swift
.alert("Location Access Required", isPresented: $showSettingsAlert) {
    Button("Open Settings") {
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
    }
    Button("Cancel", role: .cancel) {}
} message: {
    Text("To re-center on your position, enable Location in Settings.")
}
```

## Auto-Update Behavior

All state transitions are event-driven (no polling):
- **Permission change** (grey ↔ blue/red): `locationManagerDidChangeAuthorization` fires automatically when the user changes location permission in Settings. `authorizationStatus` is `@Observable` so the button re-renders instantly.
- **GPS fix gained** (red → blue): `didUpdateLocations` sets `userLocation`, driving the transition.
- **GPS fix lost** (blue → red, e.g. indoors): `didFailWithError` nils `userLocation` on `CLError.locationUnknown`.

## Appearance

Bottom-trailing placement pairs with the FEAT-003 Rome button (bottom-leading). Both buttons use identical visual styling (capsule, `.bordered`, drop shadow) for visual consistency.

## Out of Scope

- No haptic feedback.
- No animation on camera re-center (consistent with Rome button).
- No visibility toggling — button always shown.
