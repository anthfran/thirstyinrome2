# FEAT-002 v2: Navigate to Fountain via Maps (Bottom Sheet) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the existing `confirmationDialog` navigation UI with a compact SwiftUI bottom sheet showing the fountain name and buttons for Apple Maps and Google Maps (both always shown, both open walking directions).

**Architecture:** Create `FountainSheet.swift` as a self-contained view that owns all navigation logic. Update `ContentView.swift` to add a `selectedPlace: Place?` state variable, replace `.confirmationDialog` with `.onChange(of: selectedPlaceID)` + `.sheet(item: $selectedPlace)`, and remove the three now-redundant private methods. Also remove the no-longer-needed `LSApplicationQueriesSchemes` build setting from `project.pbxproj`.

**Tech Stack:** SwiftUI (`.sheet`, `.presentationDetents`, `@Environment(\.dismiss)`), MapKit (`MKMapItem`, `MKLaunchOptionsDirectionsModeWalking`), `UIApplication.shared.open` for Google Maps.

---

### Task 1: Create FountainSheet.swift

**Files:**
- Create: `thirstyinrome/FountainSheet.swift`

- [ ] **Step 1: Create the file with complete implementation**

Create `/Users/anthony/github/thirstyinrome/thirstyinrome/FountainSheet.swift` with this exact content:

```swift
import SwiftUI
import MapKit

struct FountainSheet: View {
    let place: Place
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)

            Text(place.title ?? "Fontanella")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(spacing: 12) {
                Button {
                    openAppleMaps()
                } label: {
                    Label("Open in Apple Maps", systemImage: "map")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)

                Button {
                    openGoogleMaps()
                } label: {
                    Label("Open in Google Maps", systemImage: "map")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.horizontal)
            }

            Spacer()
        }
        .padding(.top)
        .presentationDetents([.height(220)])
    }

    private func openAppleMaps() {
        let coordinate = CLLocationCoordinate2D(latitude: place.lat, longitude: place.lon)
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = place.title ?? "Fontanella"
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking])
        dismiss()
    }

    private func openGoogleMaps() {
        let daddr = String(format: "%.6f,%.6f", place.lat, place.lon)
        guard let url = URL(string: "comgooglemaps://?daddr=\(daddr)&directionsmode=walking") else { return }
        UIApplication.shared.open(url)
        dismiss()
    }
}
```

Notes on this implementation:
- `Place` is defined in `thirstyinrome/Place.swift` as `struct Place: Codable, Identifiable { let id: String; let title: String?; let lat: Double; let lon: Double }`
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` — all types are implicitly `@MainActor`, no explicit annotation needed
- `UIApplication` requires no extra import beyond SwiftUI (it's available via UIKit which SwiftUI pulls in on iOS)
- The file is in `thirstyinrome/` which uses File System Synchronized Groups — no `project.pbxproj` edit needed for new source files

- [ ] **Step 2: Build to verify**

```bash
xcodebuild build -project thirstyinrome.xcodeproj -scheme thirstyinrome -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17' 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED"
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add thirstyinrome/FountainSheet.swift
git commit -m "feat: add FountainSheet bottom sheet view"
```

---

### Task 2: Update ContentView.swift

Replace `.confirmationDialog` with `.onChange` + `.sheet(item:)`, add `selectedPlace` state, and remove the three navigation methods that have moved to `FountainSheet`.

**Files:**
- Modify: `thirstyinrome/ContentView.swift`

The current file (on branch `feat/feat-002-maps-navigation`) already has:
- `@State private var selectedPlaceID: String?` — keep, still drives `Map(selection:)`
- `.confirmationDialog(...)` at lines 95–112 — replace
- `canOpenGoogleMaps()`, `openAppleMaps(for:)`, `openGoogleMaps(for:)` at lines 138–154 — remove

- [ ] **Step 1: Add selectedPlace state property**

After `@State private var selectedPlaceID: String?`, add:

```swift
@State private var selectedPlace: Place?
```

The state block should now read:
```swift
@State private var hasJumpedToUserLocation = false
@State private var mapSpan: Double = ContentView.zoomedInSpan
@State private var selectedPlaceID: String?
@State private var selectedPlace: Place?
```

- [ ] **Step 2: Replace .confirmationDialog with .onChange + .sheet**

Remove the entire `.confirmationDialog(...)` block:
```swift
.confirmationDialog(
    "Get Directions",
    // confirmationDialog requires Bool; derive from selectedPlaceID being non-nil
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

Replace it with:
```swift
.onChange(of: selectedPlaceID) { _, newID in
    selectedPlace = newID.flatMap { id in viewModel.places.first { $0.id == id } }
}
.sheet(item: $selectedPlace, onDismiss: { selectedPlaceID = nil }) { place in
    FountainSheet(place: place)
}
```

- [ ] **Step 3: Remove the three navigation methods**

Delete these three methods in their entirety:

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
    let daddr = String(format: "%.6f,%.6f", place.lat, place.lon)
    guard let url = URL(string: "comgooglemaps://?daddr=\(daddr)&directionsmode=walking") else { return }
    UIApplication.shared.open(url)
}
```

- [ ] **Step 4: Build and run tests**

```bash
xcodebuild test -project thirstyinrome.xcodeproj -scheme thirstyinrome -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17' -skip-testing:thirstyinromeUITests 2>&1 | grep -E "error:|warning:|Test Suite|Test Case|PASSED|FAILED|BUILD SUCCEEDED|BUILD FAILED|TEST SUCCEEDED|TEST FAILED"
```

Expected: `TEST SUCCEEDED` with all existing tests passing.

- [ ] **Step 5: Commit**

```bash
git add thirstyinrome/ContentView.swift
git commit -m "feat: replace confirmationDialog with FountainSheet bottom sheet"
```

---

### Task 3: Remove LSApplicationQueriesSchemes from build settings

`LSApplicationQueriesSchemes` was added to support `canOpenURL("comgooglemaps://")`, which has been removed. `UIApplication.shared.open` does not require this key, so the setting is now dead weight.

**Files:**
- Modify: `thirstyinrome.xcodeproj/project.pbxproj`

- [ ] **Step 1: Remove from Debug configuration**

In the Debug target build configuration block (`9272CE752F905FC1007C0D36`), remove this line:
```
INFOPLIST_KEY_LSApplicationQueriesSchemes = comgooglemaps;
```

- [ ] **Step 2: Remove from Release configuration**

In the Release target build configuration block (`9272CE762F905FC1007C0D36`), remove the same line:
```
INFOPLIST_KEY_LSApplicationQueriesSchemes = comgooglemaps;
```

- [ ] **Step 3: Build to verify**

```bash
xcodebuild build -project thirstyinrome.xcodeproj -scheme thirstyinrome -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17' 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED"
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 4: Commit**

```bash
git add thirstyinrome.xcodeproj/project.pbxproj
git commit -m "chore: remove unused LSApplicationQueriesSchemes build setting"
```

---

### Task 4: Manual verification checklist

Run the app on a physical device (Google Maps on simulator is not available, so only Apple Maps can be verified in simulator).

- [ ] Zoom in past the clustering threshold → tap any fountain marker → compact bottom sheet slides up
- [ ] Sheet shows fountain name (or "Fontanella") + "Open in Apple Maps" + "Open in Google Maps" + X button
- [ ] Tap "Open in Apple Maps" → Apple Maps opens with walking directions, sheet closes
- [ ] Tap "Open in Google Maps" → Google Maps opens with walking directions, sheet closes (device only)
- [ ] Tap X → sheet closes, fountain deselects
- [ ] Swipe down to dismiss → sheet closes, fountain deselects
- [ ] Tap map background → sheet closes
- [ ] Zoom out → tap a cluster → cluster zooms, no sheet appears
