# ThirstyInRome Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a single-screen iOS app that shows Rome's public drinking fountains on a full-screen map with live user location.

**Architecture:** `@Observable` `PlaceViewModel` owns `[Place]` (decoded from bundled JSON at init) and `userLocation` (fed by `CLLocationManagerDelegate`). `ContentView` consumes the ViewModel from the SwiftUI environment and renders a full-screen `Map` with default-styled `Marker` pins. Camera defaults to Rome center, jumps once to user location on first GPS fix.

**Tech Stack:** SwiftUI, MapKit (iOS 17+ API), CoreLocation, Swift Testing, Xcode 26 / Swift 6 (`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`)

---

## Project Context

- **File System Synchronized Groups**: Any file added to `thirstyinrome/` on disk is automatically included in the build. No pbxproj edits needed for new source/resource files.
- **`GENERATE_INFOPLIST_FILE = YES`**: Location usage description is injected via `INFOPLIST_KEY_NSLocationWhenInUseUsageDescription` build setting — no separate `.plist` file.
- **`BUNDLE_LOADER`**: Tests run inside the app process, so `Bundle.main` in tests resolves to the app bundle. `Places.json` does not need to be separately added to the test target.
- **`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`**: All types are implicitly `@MainActor`. No explicit annotations needed on the ViewModel or delegate methods.

---

## File Map

| Action | Path | Responsibility |
|--------|------|----------------|
| Move   | `thirstyinrome/Places.json` | Bundled fountain data (moved from repo root) |
| Create | `thirstyinrome/Place.swift` | `Codable + Identifiable` model |
| Create | `thirstyinrome/PlaceViewModel.swift` | `@Observable` class; loads JSON, owns location state |
| Modify | `thirstyinrome/ContentView.swift` | Full-screen `Map` with markers and user location |
| Modify | `thirstyinrome/thirstyinromeApp.swift` | Creates `PlaceViewModel`, injects via `.environment()` |
| Modify | `thirstyinrome.xcodeproj/project.pbxproj` | Add `INFOPLIST_KEY_NSLocationWhenInUseUsageDescription` |
| Create | `thirstyinromeTests/PlaceTests.swift` | Swift Testing: 3 tests for JSON loading, nil title, bounds |

---

## Task 1: Move Places.json into the app bundle

**Files:**
- Move: `Places.json` → `thirstyinrome/Places.json`

- [ ] **Step 1: Move the file**

```bash
mv /Users/anthony/github/thirstyinrome/Places.json /Users/anthony/github/thirstyinrome/thirstyinrome/Places.json
```

Because the app target uses a `PBXFileSystemSynchronizedRootGroup` pointing at the `thirstyinrome/` folder, Xcode automatically includes this as a bundle resource. No pbxproj edit required.

- [ ] **Step 2: Commit**

```bash
git add -A
git commit -m "chore: move Places.json into app source folder for bundle inclusion"
```

---

## Task 2: Add location permission to build settings

**Files:**
- Modify: `thirstyinrome.xcodeproj/project.pbxproj`

The project uses `GENERATE_INFOPLIST_FILE = YES`, so the usage description must be added as a build setting. It must appear in both the Debug (`9272CE752F905FC1007C0D36`) and Release (`9272CE762F905FC1007C0D36`) build configurations for the app target.

- [ ] **Step 1: Add the key to the Debug build config**

In `thirstyinrome.xcodeproj/project.pbxproj`, find the block:
```
9272CE752F905FC1007C0D36 /* Debug */ = {
    isa = XCBuildConfiguration;
    buildSettings = {
        ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
```

Add this line inside `buildSettings`:
```
INFOPLIST_KEY_NSLocationWhenInUseUsageDescription = "To show your position near Rome's drinking fountains.";
```

- [ ] **Step 2: Add the key to the Release build config**

Find:
```
9272CE762F905FC1007C0D36 /* Release */ = {
    isa = XCBuildConfiguration;
    buildSettings = {
        ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
```

Add the same line inside `buildSettings`:
```
INFOPLIST_KEY_NSLocationWhenInUseUsageDescription = "To show your position near Rome's drinking fountains.";
```

- [ ] **Step 3: Commit**

```bash
git add thirstyinrome.xcodeproj/project.pbxproj
git commit -m "chore: add NSLocationWhenInUseUsageDescription to generated Info.plist"
```

---

## Task 3: Create Place model (TDD)

**Files:**
- Create: `thirstyinromeTests/PlaceTests.swift`
- Create: `thirstyinrome/Place.swift`

### Step 1 — Write the failing tests first

- [ ] **Step 1: Create PlaceTests.swift**

Create `thirstyinromeTests/PlaceTests.swift`:

```swift
import Testing
import Foundation
@testable import thirstyinrome

struct PlaceTests {

    @Test func testPlacesJSONLoads() throws {
        guard let url = Bundle.main.url(forResource: "Places", withExtension: "json") else {
            Issue.record("Places.json not found in Bundle.main")
            return
        }
        let data = try Data(contentsOf: url)
        let places = try JSONDecoder().decode([Place].self, from: data)
        #expect(!places.isEmpty)
    }

    @Test func testNilTitleHandled() throws {
        let json = Data("""
        [{"lat": 41.9, "lon": 12.5}]
        """.utf8)
        let places = try JSONDecoder().decode([Place].self, from: json)
        #expect(places.count == 1)
        #expect(places[0].title == nil)
    }

    @Test func testCoordinatesInRomeBounds() throws {
        guard let url = Bundle.main.url(forResource: "Places", withExtension: "json") else {
            Issue.record("Places.json not found in Bundle.main")
            return
        }
        let data = try Data(contentsOf: url)
        let places = try JSONDecoder().decode([Place].self, from: data)
        for place in places {
            #expect((41.0...42.0).contains(place.lat), "lat \(place.lat) out of Rome bounds")
            #expect((12.0...13.0).contains(place.lon), "lon \(place.lon) out of Rome bounds")
        }
    }
}
```

- [ ] **Step 2: Run tests — expect compile failure (Place not defined yet)**

```bash
xcodebuild test \
  -project thirstyinrome.xcodeproj \
  -scheme thirstyinrome \
  -destination 'platform=iOS Simulator,OS=latest,name=iPhone 16' \
  2>&1 | grep -E "(error:|Build FAILED|Test Suite)"
```

Expected: compile error — `cannot find type 'Place' in scope`

### Step 2 — Implement Place to make tests pass

- [ ] **Step 3: Create Place.swift**

Create `thirstyinrome/Place.swift`:

```swift
import Foundation

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

- [ ] **Step 4: Run tests — expect all 3 to pass**

```bash
xcodebuild test \
  -project thirstyinrome.xcodeproj \
  -scheme thirstyinrome \
  -destination 'platform=iOS Simulator,OS=latest,name=iPhone 16' \
  2>&1 | grep -E "(error:|Build FAILED|Test Suite|passed|failed)"
```

Expected: `Test Suite 'PlaceTests' passed` with 3 tests passing.

- [ ] **Step 5: Commit**

```bash
git add thirstyinrome/Place.swift thirstyinromeTests/PlaceTests.swift
git commit -m "feat: add Place model with TDD — 3 tests passing"
```

---

## Task 4: Create PlaceViewModel

**Files:**
- Create: `thirstyinrome/PlaceViewModel.swift`

`PlaceViewModel` subclasses `NSObject` to conform to `CLLocationManagerDelegate`. It is implicitly `@MainActor` (project-wide default). JSON is decoded synchronously in `init()` from `Bundle.main` — fast and safe for a bundled file. Location updates start only after authorization is granted.

- [ ] **Step 1: Create PlaceViewModel.swift**

Create `thirstyinrome/PlaceViewModel.swift`:

```swift
import Foundation
import CoreLocation
import Observation

@Observable
final class PlaceViewModel: NSObject, CLLocationManagerDelegate {
    var places: [Place] = []
    var userLocation: CLLocation?

    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        loadPlaces()
        setupLocationManager()
    }

    // MARK: - Private

    private func loadPlaces() {
        guard let url = Bundle.main.url(forResource: "Places", withExtension: "json") else {
            print("ThirstyInRome: Places.json not found in bundle")
            return
        }
        do {
            let data = try Data(contentsOf: url)
            places = try JSONDecoder().decode([Place].self, from: data)
        } catch {
            print("ThirstyInRome: Failed to decode Places.json: \(error)")
        }
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.last
    }
}
```

- [ ] **Step 2: Verify build succeeds**

```bash
xcodebuild build \
  -project thirstyinrome.xcodeproj \
  -scheme thirstyinrome \
  -destination 'platform=iOS Simulator,OS=latest,name=iPhone 16' \
  2>&1 | grep -E "(error:|Build FAILED|Build SUCCEEDED)"
```

Expected: `Build SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add thirstyinrome/PlaceViewModel.swift
git commit -m "feat: add PlaceViewModel with JSON loading and CoreLocation"
```

---

## Task 5: Update ContentView

**Files:**
- Modify: `thirstyinrome/ContentView.swift`

`ContentView` reads `PlaceViewModel` from the environment. Camera starts at Rome center. On the first non-nil `userLocation` update, the camera jumps to the user — tracked with a local `hasJumpedToUserLocation` flag so subsequent location updates don't fight with the user's panning. `UserAnnotation()` renders the native blue location dot.

- [ ] **Step 1: Replace ContentView.swift**

```swift
import SwiftUI
import MapKit

struct ContentView: View {
    @Environment(PlaceViewModel.self) private var viewModel
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 41.899159, longitude: 12.473065),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    )
    @State private var hasJumpedToUserLocation = false

    var body: some View {
        Map(position: $cameraPosition) {
            ForEach(viewModel.places) { place in
                Marker(
                    place.title ?? "Fontanella",
                    coordinate: CLLocationCoordinate2D(latitude: place.lat, longitude: place.lon)
                )
            }
            UserAnnotation()
        }
        .mapStyle(.standard)
        .ignoresSafeArea()
        .onChange(of: viewModel.userLocation) { _, newLocation in
            guard !hasJumpedToUserLocation, let location = newLocation else { return }
            hasJumpedToUserLocation = true
            cameraPosition = .region(MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        }
    }
}

#Preview {
    ContentView()
        .environment(PlaceViewModel())
}
```

- [ ] **Step 2: Verify build succeeds**

```bash
xcodebuild build \
  -project thirstyinrome.xcodeproj \
  -scheme thirstyinrome \
  -destination 'platform=iOS Simulator,OS=latest,name=iPhone 16' \
  2>&1 | grep -E "(error:|Build FAILED|Build SUCCEEDED)"
```

Expected: `Build SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add thirstyinrome/ContentView.swift
git commit -m "feat: implement full-screen map view with fountain markers and user location"
```

---

## Task 6: Wire up App entry point

**Files:**
- Modify: `thirstyinrome/thirstyinromeApp.swift`

`PlaceViewModel` is instantiated once here as `@State` and injected into the SwiftUI environment via `.environment()`. `@State` on the App struct keeps the ViewModel alive for the app's lifetime.

- [ ] **Step 1: Update thirstyinromeApp.swift**

```swift
import SwiftUI

@main
struct thirstyinromeApp: App {
    @State private var viewModel = PlaceViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
        }
    }
}
```

- [ ] **Step 2: Run full build + tests**

```bash
xcodebuild test \
  -project thirstyinrome.xcodeproj \
  -scheme thirstyinrome \
  -destination 'platform=iOS Simulator,OS=latest,name=iPhone 16' \
  2>&1 | grep -E "(error:|Build FAILED|Build SUCCEEDED|Test Suite|passed|failed)"
```

Expected: `Build SUCCEEDED`, `Test Suite 'PlaceTests' passed` (3 tests).

- [ ] **Step 3: Commit**

```bash
git add thirstyinrome/thirstyinromeApp.swift
git commit -m "feat: inject PlaceViewModel into SwiftUI environment at app root"
```
