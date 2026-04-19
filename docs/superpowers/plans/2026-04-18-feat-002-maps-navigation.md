# FEAT-002: Navigate to Fountain via Maps — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tapping a fountain marker opens a "Get Directions" action sheet with Apple Maps (always) and Google Maps (when installed), both opening with walking directions.

**Architecture:** Add `Map(selection:)` binding to detect fountain taps, show a `.confirmationDialog`, and open the chosen Maps app via `MKMapItem` or URL scheme. No new files — all changes in `ContentView.swift` and `project.pbxproj`.

**Tech Stack:** SwiftUI, MapKit (`MKMapItem`, `MKLaunchOptionsDirectionsModeWalking`), `UIApplication.canOpenURL` for Google Maps detection.

---

### Task 1: Create feature branch

**Files:**
- No file changes

- [ ] **Step 1: Create and switch to feature branch**

```bash
git checkout -b feat/feat-002-maps-navigation
```

Expected: `Switched to a new branch 'feat/feat-002-maps-navigation'`

---

### Task 2: Add LSApplicationQueriesSchemes to build settings

`canOpenURL("comgooglemaps://")` always returns `false` unless `comgooglemaps` is declared in `LSApplicationQueriesSchemes`. Add it to both Debug and Release target build configurations in `project.pbxproj`.

**Files:**
- Modify: `thirstyinrome.xcodeproj/project.pbxproj`

- [ ] **Step 1: Add the scheme to the Debug configuration**

Find the Debug target build configuration block (search for `9272CE752F905FC1007C0D36 /* Debug */`). Add one line after `INFOPLIST_KEY_NSLocationWhenInUseUsageDescription`:

```
INFOPLIST_KEY_LSApplicationQueriesSchemes = comgooglemaps;
```

The block should look like:
```
INFOPLIST_KEY_CFBundleDisplayName = "Thirsty In Rome";
INFOPLIST_KEY_LSApplicationQueriesSchemes = comgooglemaps;
INFOPLIST_KEY_NSLocationWhenInUseUsageDescription = "To show your position near Rome's drinking fountains.";
```

- [ ] **Step 2: Add the scheme to the Release configuration**

Find the Release target build configuration block (search for `9272CE762F905FC1007C0D36 /* Release */`). Add the same line in the same position:

```
INFOPLIST_KEY_LSApplicationQueriesSchemes = comgooglemaps;
```

- [ ] **Step 3: Build to verify the project still compiles**

```bash
xcodebuild build -project thirstyinrome.xcodeproj -scheme thirstyinrome -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17' 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED"
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 4: Commit**

```bash
git add thirstyinrome.xcodeproj/project.pbxproj
git commit -m "chore: add comgooglemaps to LSApplicationQueriesSchemes"
```

---

### Task 3: Wire up Map selection binding and tag Markers

Switch the `Map` initializer to use `selection:` and add `.tag(place.id)` to every `Marker`. This enables MapKit to report which fountain the user tapped via the `selectedPlaceID` binding.

**Files:**
- Modify: `thirstyinrome/ContentView.swift`

- [ ] **Step 1: Add selectedPlaceID state property**

In `ContentView`, after the existing `@State private var mapSpan` line, add:

```swift
@State private var selectedPlaceID: String?
```

The state properties block should now read:
```swift
@State private var cameraPosition: MapCameraPosition = .region(...)
@State private var hasJumpedToUserLocation = false
@State private var mapSpan: Double = ContentView.zoomedInSpan
@State private var selectedPlaceID: String?
```

- [ ] **Step 2: Update the Map initializer to include the selection binding**

Change:
```swift
Map(position: $cameraPosition) {
```

To:
```swift
Map(position: $cameraPosition, selection: $selectedPlaceID) {
```

- [ ] **Step 3: Tag Markers in the zoomed-out singles branch**

In the `if mapSpan > ContentView.clusteringThreshold` branch, change the singles `ForEach` from:
```swift
ForEach(result.singles) { place in
    Marker(
        place.title ?? "Fontanella",
        coordinate: CLLocationCoordinate2D(latitude: place.lat, longitude: place.lon)
    )
}
```

To:
```swift
ForEach(result.singles) { place in
    Marker(
        place.title ?? "Fontanella",
        coordinate: CLLocationCoordinate2D(latitude: place.lat, longitude: place.lon)
    )
    .tag(place.id)
}
```

- [ ] **Step 4: Tag Markers in the zoomed-in all-places branch**

In the `else` branch, change the `viewModel.places` `ForEach` from:
```swift
ForEach(viewModel.places) { place in
    Marker(
        place.title ?? "Fontanella",
        coordinate: CLLocationCoordinate2D(latitude: place.lat, longitude: place.lon)
    )
}
```

To:
```swift
ForEach(viewModel.places) { place in
    Marker(
        place.title ?? "Fontanella",
        coordinate: CLLocationCoordinate2D(latitude: place.lat, longitude: place.lon)
    )
    .tag(place.id)
}
```

- [ ] **Step 5: Build to verify**

```bash
xcodebuild build -project thirstyinrome.xcodeproj -scheme thirstyinrome -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17' 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED"
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 6: Commit**

```bash
git add thirstyinrome/ContentView.swift
git commit -m "feat: wire Map selection binding and tag fountain Markers"
```

---

### Task 4: Add navigation helpers and confirmation dialog

Add three private methods to `ContentView` and attach a `.confirmationDialog` to the `Map`. When a fountain is tapped, `selectedPlaceID` becomes non-nil, the dialog appears, and the user picks a Maps app.

**Files:**
- Modify: `thirstyinrome/ContentView.swift`

- [ ] **Step 1: Add the three private navigation methods**

After the existing `private func zoomToCluster` method, add:

```swift
private func canOpenGoogleMaps() -> Bool {
    guard let url = URL(string: "comgooglemaps://") else { return false }
    return UIApplication.shared.canOpenURL(url)
}

private func openAppleMaps(for place: Place) {
    let coordinate = CLLocationCoordinate2D(latitude: place.lat, longitude: place.lon)
    let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
    mapItem.name = place.title ?? "Fontanella"
    mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking])
}

private func openGoogleMaps(for place: Place) {
    guard let url = URL(string: "comgooglemaps://?daddr=\(place.lat),\(place.lon)&directionsmode=walking") else { return }
    UIApplication.shared.open(url)
}
```

- [ ] **Step 2: Attach the confirmation dialog to the Map**

Add the `.confirmationDialog` modifier immediately after the `.onMapCameraChange` modifier (before `.onChange(of: viewModel.userLocation)`):

```swift
.confirmationDialog(
    "Get Directions",
    isPresented: Binding(
        get: { selectedPlaceID != nil },
        set: { if !$0 { selectedPlaceID = nil } }
    ),
    titleVisibility: .visible
) {
    if let id = selectedPlaceID,
       let place = viewModel.places.first(where: { $0.id == id }) {
        Button("Apple Maps") { openAppleMaps(for: place) }
        if canOpenGoogleMaps() {
            Button("Google Maps") { openGoogleMaps(for: place) }
        }
    }
    Button("Cancel", role: .cancel) { selectedPlaceID = nil }
}
```

Note: the dialog content closure captures `selectedPlaceID` and `viewModel.places` at presentation time. Tapping any button (including Cancel) causes iOS to dismiss the dialog, which sets `isPresented` to `false`, which triggers the `Binding.set` closure and clears `selectedPlaceID`.

- [ ] **Step 3: Build and run tests**

```bash
xcodebuild test -project thirstyinrome.xcodeproj -scheme thirstyinrome -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17' -skip-testing:thirstyinromeUITests 2>&1 | grep -E "error:|warning:|Test Suite|Test Case|PASSED|FAILED|BUILD SUCCEEDED|BUILD FAILED|TEST SUCCEEDED|TEST FAILED"
```

Expected: `TEST SUCCEEDED` with all existing tests passing.

- [ ] **Step 4: Commit**

```bash
git add thirstyinrome/ContentView.swift
git commit -m "feat: add Get Directions action sheet for fountain markers"
```

---

### Task 5: Manual verification checklist

Run the app in the simulator. Google Maps cannot be installed on a simulator, so only Apple Maps will show — this correctly verifies the conditional logic.

- [ ] Zoom in past the clustering threshold (0.027°) so individual fountain markers appear
- [ ] Tap any fountain marker → "Get Directions" action sheet slides up
- [ ] Sheet shows "Apple Maps" button and "Cancel" button (no Google Maps in simulator — correct)
- [ ] Tap "Apple Maps" → Apple Maps opens with walking directions to the fountain
- [ ] Return to app — sheet is dismissed, fountain is deselected
- [ ] Tap "Cancel" → sheet dismisses, no navigation opens
- [ ] Zoom out past clustering threshold → tap a cluster → cluster zoom behavior unchanged (no sheet)
- [ ] Tap a fountain in the zoomed-out singles view → sheet appears correctly

---

### Task 6: Open PR

- [ ] **Step 1: Push branch and open PR**

```bash
git push -u origin feat/feat-002-maps-navigation
```

Then open a PR targeting `main` with title: `feat: FEAT-002 navigate to fountain via Maps`.
