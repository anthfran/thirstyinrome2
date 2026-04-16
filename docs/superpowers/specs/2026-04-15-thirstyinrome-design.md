# ThirstyInRome — Design Spec

**Date:** 2026-04-15
**Status:** Approved

## Overview

ThirstyInRome is a single-screen iOS 17 app that shows Rome's public drinking water fountains ("nasoni") on a full-screen map. Users can see all fountains as map pins and their own GPS position relative to them.

---

## Stack

- SwiftUI + MapKit
- Swift Package Manager
- Swift Testing framework
- Minimum deployment target: iOS 17

---

## Data

`Places.json` is bundled with the app and loaded once at launch. It also must be added to the test target's bundle resources.

**Schema:**
```json
[{ "title": String?, "lat": Double, "lon": Double }]
```

**Model:**
```swift
struct Place: Codable, Identifiable {
    let id = UUID()
    let title: String?
    let lat: Double
    let lon: Double

    enum CodingKeys: String, CodingKey {
        case title, lat, lon
    }
}
```

`id` is excluded from `CodingKeys` so each decoded instance gets a stable UUID for the session. Since the array is loaded once at launch and never re-decoded, stability across re-renders is guaranteed.

---

## File Structure

```
thirstyinrome/
  thirstyinromeApp.swift     — @main; creates PlaceViewModel once; injects via .environment()
  Place.swift                — Codable + Identifiable model
  PlaceViewModel.swift       — @Observable; loads JSON in init(); owns [Place] + location state
  ContentView.swift          — Full-screen Map view; reads ViewModel from environment

thirstyinromeTests/
  PlaceTests.swift           — Swift Testing; 3 test cases
```

---

## Architecture

### PlaceViewModel

`@Observable` class, instantiated once in `thirstyinromeApp` and injected via `.environment()`.

**Responsibilities:**
- Load and decode `Places.json` from `Bundle.main` in `init()` via a private `loadPlaces()` method
- If bundle lookup or decode fails, `places` stays empty; error is printed to console (no user-facing error UI)
- Conform to `CLLocationManagerDelegate`; own a `CLLocationManager` instance
- Expose `userLocation: CLLocation?` updated on each delegate callback
- Request location authorization only when `authorizationStatus == .notDetermined`

**Properties:**
```swift
var places: [Place] = []
var userLocation: CLLocation? = nil
```

### ContentView

- Renders a SwiftUI `Map` with `.ignoresSafeArea()` (full screen)
- Holds `@State var cameraPosition: MapCameraPosition` initialized to Rome center
- Observes `viewModel.userLocation`; on the **first** non-nil update, jumps camera to user's position — after that the user pans freely
- Renders `Marker` for each place; nil titles fall back to `"Fontanella"`
- Includes user location dot via MapKit's native user location support

---

## Map

**Default camera (no GPS):** Rome city center `(41.899159, 12.473065)`, span `MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)` (~1 km radius).

**Camera with GPS:** On first location fix, camera jumps to user's current coordinate. User can pan freely thereafter.

**Markers:** Default MapKit pin styling. `Marker(place.title ?? "Fontanella", coordinate: CLLocationCoordinate2D(latitude: place.lat, longitude: place.lon))`.

**Map style:** `.standard`

---

## Location & Permissions

- Permission level: `requestWhenInUseAuthorization()` — minimal, active only while app is in foreground
- Only requested when `authorizationStatus == .notDetermined`
- No `.always` permission, no background location, no `NSLocationAlwaysUsageDescription`
- `Info.plist` key: `NSLocationWhenInUseUsageDescription` → `"To show your position near Rome's drinking fountains."`
- `CLLocationManager` configured with `desiredAccuracy = kCLLocationAccuracyBest`

---

## Testing (Swift Testing)

Three tests in `PlaceTests.swift`:

1. **`testPlacesJSONLoads`** — Decodes `Places.json` from the test bundle; asserts result is non-empty and no error is thrown.

2. **`testNilTitleHandled`** — Constructs a minimal JSON string with a `null` title and decodes it; asserts decoding succeeds and `title` is `nil`.

3. **`testCoordinatesInRomeBounds`** — Decodes `Places.json`; iterates all places; asserts `lat ∈ 41.0...42.0` and `lon ∈ 12.0...13.0` for every entry.

`Places.json` must be added to the test target's bundle resources so the bundle lookup succeeds at test time.

---

## Out of Scope (MVP)

- Detail views, navigation stack, tabs
- Custom marker styling
- Offline caching or data refresh
- Error UI for failed JSON load
- Background location updates
