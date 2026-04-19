# FEAT-002: Navigate to Fountain via Maps — Design Spec

**Date:** 2026-04-18
**Status:** Approved

## Overview

Tapping a fountain marker opens a "Get Directions" action sheet with options to navigate in Apple Maps (always shown) and Google Maps (shown only when installed). Both apps open with walking directions by default.

## User Interaction

- User taps any fountain `Marker` on the map
- An action sheet titled "Get Directions" slides up from the bottom
- Buttons: "Apple Maps" (always), "Google Maps" (only if installed), "Cancel"
- Tapping a Maps button opens the respective app with walking directions to the fountain
- Tapping Cancel or opening Maps dismisses the sheet and deselects the marker

## Architecture

No new files. All changes are in `ContentView.swift` and `project.pbxproj`.

## ContentView Changes

**New state property:**
```swift
@State private var selectedPlaceID: String?
```

**Map initializer:** Switch from `Map(position: $cameraPosition)` to `Map(position: $cameraPosition, selection: $selectedPlaceID)`.

**Marker tagging:** Every `Marker` gets `.tag(place.id)`. Applied in both branches:
- Zoomed-out singles (`result.singles`)
- Zoomed-in all-places (`viewModel.places`)

Cluster `Annotation`s are not tagged — they continue to handle taps via `onTapGesture`.

**Confirmation dialog** attached to the `Map`:
```swift
.confirmationDialog("Get Directions", isPresented: showingDirections, titleVisibility: .visible) {
    Button("Apple Maps") { openAppleMaps(for: selectedPlace) }
    if canOpenGoogleMaps() {
        Button("Google Maps") { openGoogleMaps(for: selectedPlace) }
    }
    Button("Cancel", role: .cancel) { }
}
```

`showingDirections` is a `Binding<Bool>` derived from `selectedPlaceID != nil`. `selectedPlace` is looked up from `viewModel.places` by ID. On dismiss, `selectedPlaceID` is set to `nil`.

## Navigation Helpers (private methods on ContentView)

**`canOpenGoogleMaps() -> Bool`**
Calls `UIApplication.shared.canOpenURL(URL(string: "comgooglemaps://")!)`.

**`openAppleMaps(for place: Place)`**
Creates `MKMapItem` from the place's coordinates, sets its name to `place.title ?? "Fontanella"`, opens with `MKLaunchOptionsDirectionsModeWalking`.

**`openGoogleMaps(for place: Place)`**
Constructs `comgooglemaps://?daddr=\(place.lat),\(place.lon)&directionsmode=walking` and calls `UIApplication.shared.open(url)`.

## Build Settings

Add `comgooglemaps` to `LSApplicationQueriesSchemes` in `project.pbxproj`. Required for `canOpenURL` to return a meaningful result — without it, iOS always returns `false`.

## Testing

No new unit tests. The navigation helpers open external apps and are not unit-testable in isolation. Existing `PlaceTests` suite passes unchanged.

Manual verification:
- Tap a fountain → action sheet appears with "Get Directions" title
- "Apple Maps" always present; "Google Maps" present only when installed
- Both open walking directions to the correct fountain coordinates
- Cancel dismisses the sheet
- Cluster tap behavior unchanged
