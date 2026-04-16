# FEAT-001: Marker Clustering Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Group nearby fountain markers into cluster annotations when the map is zoomed out past a span of `0.02°`, and show all individual markers when zoomed in.

**Architecture:** Grid-based clustering in `PlaceViewModel` groups places into `0.008°` cells. `ContentView` tracks the map's span via `.onMapCameraChange` and conditionally renders clusters (blue circle + count via `Annotation`) or individual markers (`Marker`). Tapping a cluster zooms the camera to its bounding region.

**Tech Stack:** SwiftUI, MapKit (SwiftUI `Map`, `Annotation`, `Marker`, `.onMapCameraChange`), Swift Testing

---

### Task 1: Write failing clustering tests

**Files:**
- Modify: `thirstyinromeTests/PlaceTests.swift`

- [ ] **Step 1: Add clustering tests to `PlaceTests.swift`**

Add a new `struct ClusterTests` at the bottom of `thirstyinromeTests/PlaceTests.swift` (after the closing `}` of `PlaceTests`):

```swift
struct ClusterTests {

    // Two places in the same 0.008° cell → one cluster, no singles
    @Test func testTwoPlacesInSameCellFormOneCluster() {
        let vm = PlaceViewModel()
        vm.places = [
            Place(title: "A", lat: 41.900, lon: 12.470),
            Place(title: "B", lat: 41.901, lon: 12.471)
        ]
        let clusters = vm.clusters()
        let singles = vm.singlePlaces()
        #expect(clusters.count == 1)
        #expect(clusters[0].count == 2)
        #expect(singles.isEmpty)
    }

    // Two places in different 0.008° cells → two singles, no clusters
    @Test func testTwoPlacesInDifferentCellsAreEachSingles() {
        let vm = PlaceViewModel()
        vm.places = [
            Place(title: "A", lat: 41.900, lon: 12.470),
            Place(title: "B", lat: 41.950, lon: 12.520)
        ]
        let clusters = vm.clusters()
        let singles = vm.singlePlaces()
        #expect(clusters.isEmpty)
        #expect(singles.count == 2)
    }

    // One place alone → not in clusters, appears in singlePlaces
    @Test func testOnePlaceIsASingle() {
        let vm = PlaceViewModel()
        vm.places = [Place(title: "A", lat: 41.900, lon: 12.470)]
        #expect(vm.clusters().isEmpty)
        #expect(vm.singlePlaces().count == 1)
    }

    // Empty places → empty results
    @Test func testEmptyPlacesReturnEmpty() {
        let vm = PlaceViewModel()
        vm.places = []
        #expect(vm.clusters().isEmpty)
        #expect(vm.singlePlaces().isEmpty)
    }

    // Cluster centroid is the average of its member coordinates
    @Test func testClusterCentroidIsAverage() {
        let vm = PlaceViewModel()
        vm.places = [
            Place(title: "A", lat: 41.900, lon: 12.470),
            Place(title: "B", lat: 41.902, lon: 12.472)
        ]
        let clusters = vm.clusters()
        #expect(clusters.count == 1)
        #expect(abs(clusters[0].coordinate.latitude  - 41.901) < 0.0001)
        #expect(abs(clusters[0].coordinate.longitude - 12.471) < 0.0001)
    }
}
```

Note: `Place` needs a memberwise-style initializer. The current struct uses `Codable` with custom `CodingKeys` but Swift auto-synthesizes a memberwise init — this should work as-is.

- [ ] **Step 2: Run tests to confirm they fail**

```bash
cd /Users/anthony/github/thirstyinrome && xcodebuild test -project thirstyinrome.xcodeproj -scheme thirstyinrome -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17' 2>&1 | grep -E "(error:|FAILED|passed|failed)"
```

Expected: compile errors — `PlaceViewModel` has no `clusters()` or `singlePlaces()` methods, `Cluster` type does not exist.

---

### Task 2: Create `Cluster` struct and implement clustering in `PlaceViewModel`

**Files:**
- Create: `thirstyinrome/Cluster.swift`
- Modify: `thirstyinrome/PlaceViewModel.swift`

- [ ] **Step 1: Create `thirstyinrome/Cluster.swift`**

```swift
import Foundation
import CoreLocation

struct Cluster: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let count: Int
    let places: [Place]
}
```

- [ ] **Step 2: Add clustering methods to `PlaceViewModel`**

Add the following methods inside `PlaceViewModel`, after the existing `locationManager(_:didUpdateLocations:)` method:

```swift
// MARK: - Clustering

private func groupByCell(gridSize: Double) -> [[Place]] {
    var cells: [String: [Place]] = [:]
    for place in places {
        let row = Int(floor(place.lat / gridSize))
        let col = Int(floor(place.lon / gridSize))
        let key = "\(row)_\(col)"
        cells[key, default: []].append(place)
    }
    return Array(cells.values)
}

func clusters(gridSize: Double = 0.008) -> [Cluster] {
    groupByCell(gridSize: gridSize).compactMap { group in
        guard group.count >= 2 else { return nil }
        let avgLat = group.map(\.lat).reduce(0, +) / Double(group.count)
        let avgLon = group.map(\.lon).reduce(0, +) / Double(group.count)
        return Cluster(
            coordinate: CLLocationCoordinate2D(latitude: avgLat, longitude: avgLon),
            count: group.count,
            places: group
        )
    }
}

func singlePlaces(gridSize: Double = 0.008) -> [Place] {
    groupByCell(gridSize: gridSize).compactMap { group in
        group.count == 1 ? group.first : nil
    }
}
```

- [ ] **Step 3: Run tests to confirm they pass**

```bash
cd /Users/anthony/github/thirstyinrome && xcodebuild test -project thirstyinrome.xcodeproj -scheme thirstyinrome -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17' 2>&1 | grep -E "(error:|FAILED|passed|failed)"
```

Expected: all tests pass, no failures.

- [ ] **Step 4: Commit**

```bash
cd /Users/anthony/github/thirstyinrome && git add thirstyinrome/Cluster.swift thirstyinrome/PlaceViewModel.swift thirstyinromeTests/PlaceTests.swift && git commit -m "feat: add grid-based clustering to PlaceViewModel"
```

---

### Task 3: Update `ContentView` to render clusters when zoomed out

**Files:**
- Modify: `thirstyinrome/ContentView.swift`

- [ ] **Step 1: Add span tracking and cluster rendering to `ContentView`**

Replace the entire contents of `thirstyinrome/ContentView.swift` with:

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
    @State private var mapSpan: Double = 0.01

    var body: some View {
        Map(position: $cameraPosition) {
            if mapSpan > 0.02 {
                ForEach(viewModel.clusters()) { cluster in
                    Annotation("", coordinate: cluster.coordinate) {
                        Button {
                            zoomToCluster(cluster)
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(.blue)
                                    .frame(width: 36, height: 36)
                                Text("\(cluster.count)")
                                    .foregroundStyle(.white)
                                    .font(.system(size: 14, weight: .bold))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                ForEach(viewModel.singlePlaces()) { place in
                    Marker(
                        place.title ?? "Fontanella",
                        coordinate: CLLocationCoordinate2D(latitude: place.lat, longitude: place.lon)
                    )
                }
            } else {
                ForEach(viewModel.places) { place in
                    Marker(
                        place.title ?? "Fontanella",
                        coordinate: CLLocationCoordinate2D(latitude: place.lat, longitude: place.lon)
                    )
                }
            }
            UserAnnotation()
        }
        .mapStyle(.standard)
        .ignoresSafeArea()
        .onMapCameraChange(frequency: .onEnd) { context in
            mapSpan = context.region.span.latitudeDelta
        }
        .onChange(of: viewModel.userLocation) { _, newLocation in
            guard !hasJumpedToUserLocation, let location = newLocation else { return }
            hasJumpedToUserLocation = true
            cameraPosition = .region(MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        }
    }

    private func zoomToCluster(_ cluster: Cluster) {
        let lats = cluster.places.map(\.lat)
        let lons = cluster.places.map(\.lon)
        let minLat = lats.min()!
        let maxLat = lats.max()!
        let minLon = lons.min()!
        let maxLon = lons.max()!
        let latDelta = max(maxLat - minLat, 0.005) * 1.3
        let lonDelta = max(maxLon - minLon, 0.005) * 1.3
        cameraPosition = .region(MKCoordinateRegion(
            center: cluster.coordinate,
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        ))
    }
}

#Preview {
    ContentView()
        .environment(PlaceViewModel())
}
```

- [ ] **Step 2: Build to confirm no compile errors**

```bash
cd /Users/anthony/github/thirstyinrome && xcodebuild build -project thirstyinrome.xcodeproj -scheme thirstyinrome -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17' 2>&1 | grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)"
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Run full test suite**

```bash
cd /Users/anthony/github/thirstyinrome && xcodebuild test -project thirstyinrome.xcodeproj -scheme thirstyinrome -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17' 2>&1 | grep -E "(error:|FAILED|passed|failed)"
```

Expected: all tests pass.

- [ ] **Step 4: Commit**

```bash
cd /Users/anthony/github/thirstyinrome && git add thirstyinrome/ContentView.swift && git commit -m "feat: render cluster annotations when map is zoomed out"
```
