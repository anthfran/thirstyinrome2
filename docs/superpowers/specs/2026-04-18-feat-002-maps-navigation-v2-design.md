# FEAT-002 v2: Navigate to Fountain via Maps — Redesign Spec

**Date:** 2026-04-18
**Status:** Approved
**Supersedes:** `2026-04-18-feat-002-maps-navigation-design.md`

## Overview

Tapping a fountain marker opens a compact bottom sheet with the fountain name, an "Open in Apple Maps" button, and an "Open in Google Maps" button. Both buttons always appear. Both open walking directions and dismiss the sheet.

## User Interaction

- User taps any fountain `Marker` on the map
- A compact bottom sheet slides up from the bottom (~220pt tall)
- Sheet shows: fountain name (or "Fontanella"), "Open in Apple Maps" button, "Open in Google Maps" button, X close button (top-trailing)
- Tapping either Maps button opens the respective app with walking directions and dismisses the sheet
- Tapping X or swiping down dismisses the sheet and deselects the marker
- Tapping the map background also closes the sheet (Map clears `selectedPlaceID` → onChange clears `selectedPlace`)
- Cluster tap behavior unchanged (no sheet)

## Architecture

Two files change:
- **Modify:** `thirstyinrome/ContentView.swift`
- **Create:** `thirstyinrome/FountainSheet.swift`

## ContentView Changes

**New state property** (alongside existing `selectedPlaceID: String?`):
```swift
@State private var selectedPlace: Place?
```

**Remove:** `.confirmationDialog(...)` modifier and `canOpenGoogleMaps()`, `openAppleMaps(for:)`, `openGoogleMaps(for:)` methods.

**Add** two modifiers in place of `.confirmationDialog`:
```swift
.onChange(of: selectedPlaceID) { _, newID in
    selectedPlace = newID.flatMap { id in viewModel.places.first { $0.id == id } }
}
.sheet(item: $selectedPlace, onDismiss: { selectedPlaceID = nil }) { place in
    FountainSheet(place: place)
}
```

No changes to `Map(position:selection:)`, `.tag(place.id)`, or any other existing modifiers.

## FountainSheet

New self-contained view in `thirstyinrome/FountainSheet.swift`:

- Receives `place: Place`
- Uses `@Environment(\.dismiss)` for X button and post-navigation dismissal
- Title: `place.title ?? "Fontanella"`
- Two full-width buttons: "Open in Apple Maps", "Open in Google Maps" — both always shown
- X close button in top-trailing corner
- `.presentationDetents([.height(220)])` for compact appearance

**Navigation methods (private, on FountainSheet):**

`openAppleMaps()` — creates `MKMapItem` from place coordinates, sets name to `place.title ?? "Fontanella"`, opens with `MKLaunchOptionsDirectionsModeWalking`, then calls `dismiss()`.

`openGoogleMaps()` — constructs `comgooglemaps://?daddr=\(String(format: "%.6f,%.6f", place.lat, place.lon))&directionsmode=walking`, calls `UIApplication.shared.open(url)`, then calls `dismiss()`.

## Testing

No new unit tests. Existing `PlaceTests` suite passes unchanged.

Manual verification:
- Tap fountain → compact sheet appears with name + two buttons
- "Open in Apple Maps" → Apple Maps opens walking directions, sheet closes
- "Open in Google Maps" → Google Maps opens walking directions, sheet closes
- X button → sheet closes, marker deselects
- Swipe to dismiss → sheet closes, marker deselects
- Tap map background → sheet closes
- Tap cluster → zoom behavior unchanged, no sheet
