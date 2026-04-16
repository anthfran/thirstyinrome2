# FEAT-004: Re-center on GPS Button — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a bottom-trailing GPS re-center button that reflects location authorization and fix state through color/icon, and re-centers the map camera on tap.

**Architecture:** Extend `PlaceViewModel` to expose `authorizationStatus` and `requestAuthorization()`, then add a state-driven button in `ContentView` with a toast and a settings alert for the two unavailable states.

**Tech Stack:** SwiftUI, MapKit, CoreLocation, Swift Testing (`import Testing`)

---

## File Map

| File | Change |
|------|--------|
| `thirstyinrome/PlaceViewModel.swift` | Add `authorizationStatus`, `requestAuthorization()`, `didFailWithError`, `distanceFilter = 10` |
| `thirstyinrome/ContentView.swift` | Add `LocationButtonState` enum, computed properties, GPS button overlay, toast overlay, settings alert |
| `thirstyinromeTests/PlaceTests.swift` | Add `LocationViewModelTests` struct with 3 new tests |

---

### Task 1: PlaceViewModel — expose authorizationStatus and handle GPS loss

**Files:**
- Modify: `thirstyinrome/PlaceViewModel.swift`
- Test: `thirstyinromeTests/PlaceTests.swift`

- [ ] **Step 1: Write the failing tests**

Append a new test struct to `thirstyinromeTests/PlaceTests.swift`:

```swift
struct LocationViewModelTests {

    @Test func testAuthorizationStatusIsReadable() {
        let vm = PlaceViewModel()
        let _ = vm.authorizationStatus // fails to compile until property added
    }

    @Test func testLocationUnknownErrorNilsUserLocation() {
        let vm = PlaceViewModel()
        vm.userLocation = CLLocation(latitude: 41.9, longitude: 12.5)
        vm.locationManager(CLLocationManager(), didFailWithError: CLError(.locationUnknown))
        #expect(vm.userLocation == nil)
    }

    @Test func testOtherLocationErrorPreservesUserLocation() {
        let vm = PlaceViewModel()
        vm.userLocation = CLLocation(latitude: 41.9, longitude: 12.5)
        vm.locationManager(CLLocationManager(), didFailWithError: CLError(.denied))
        #expect(vm.userLocation != nil)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
xcodebuild test -project thirstyinrome.xcodeproj -scheme thirstyinrome -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17' -only-testing:thirstyinromeTests/LocationViewModelTests 2>&1 | grep -E "error:|warning:|Test Suite|Test Case|PASSED|FAILED|BUILD SUCCEEDED|BUILD FAILED|TEST SUCCEEDED|TEST FAILED"
```

Expected: BUILD FAILED — `value of type 'PlaceViewModel' has no member 'authorizationStatus'`

- [ ] **Step 3: Implement the changes in PlaceViewModel**

Replace the contents of `thirstyinrome/PlaceViewModel.swift` with:

```swift
import Foundation
import CoreLocation
import Observation

@Observable
final class PlaceViewModel: NSObject, CLLocationManagerDelegate {
    var places: [Place] = []
    var userLocation: CLLocation?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let locationManager = CLLocationManager()
    private var isUpdatingLocation = false

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
        locationManager.distanceFilter = 10
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }

    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            if !isUpdatingLocation {
                isUpdatingLocation = true
                manager.startUpdatingLocation()
            }
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            userLocation = location
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if (error as? CLError)?.code == .locationUnknown {
            userLocation = nil
        }
    }

    // MARK: - Clustering

    private static let defaultGridSize: Double = 0.008

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

    /// Groups places into clusters and singles in a single pass.
    /// Use this from call sites that need both to avoid processing `places` twice.
    func clusteringResult(gridSize: Double = defaultGridSize) -> (clusters: [Cluster], singles: [Place]) {
        let groups = groupByCell(gridSize: gridSize)
        let clusters = groups.compactMap { group -> Cluster? in
            guard group.count >= 2 else { return nil }
            let avgLat = group.map(\.lat).reduce(0, +) / Double(group.count)
            let avgLon = group.map(\.lon).reduce(0, +) / Double(group.count)
            return Cluster(
                coordinate: CLLocationCoordinate2D(latitude: avgLat, longitude: avgLon),
                count: group.count,
                places: group
            )
        }
        let singles = groups.compactMap { $0.count == 1 ? $0.first : nil }
        return (clusters, singles)
    }

    func clusters(gridSize: Double = defaultGridSize) -> [Cluster] {
        clusteringResult(gridSize: gridSize).clusters
    }

    func singlePlaces(gridSize: Double = defaultGridSize) -> [Place] {
        clusteringResult(gridSize: gridSize).singles
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
xcodebuild test -project thirstyinrome.xcodeproj -scheme thirstyinrome -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17' -only-testing:thirstyinromeTests/LocationViewModelTests 2>&1 | grep -E "error:|warning:|Test Suite|Test Case|PASSED|FAILED|BUILD SUCCEEDED|BUILD FAILED|TEST SUCCEEDED|TEST FAILED"
```

Expected: TEST SUCCEEDED — all 3 tests pass.

- [ ] **Step 5: Run the full test suite to catch regressions**

```bash
xcodebuild test -project thirstyinrome.xcodeproj -scheme thirstyinrome -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17' 2>&1 | grep -E "error:|warning:|Test Suite|Test Case|PASSED|FAILED|BUILD SUCCEEDED|BUILD FAILED|TEST SUCCEEDED|TEST FAILED"
```

Expected: TEST SUCCEEDED — all existing tests still pass.

- [ ] **Step 6: Commit**

```bash
git add thirstyinrome/PlaceViewModel.swift thirstyinromeTests/PlaceTests.swift
git commit -m "feat: expose authorizationStatus and handle GPS loss in PlaceViewModel (FEAT-004)"
```

---

### Task 2: ContentView — GPS re-center button

**Files:**
- Modify: `thirstyinrome/ContentView.swift`

There are no unit tests for SwiftUI views in this codebase — correctness is verified by build success and manual device testing.

- [ ] **Step 1: Replace ContentView.swift with the updated implementation**

```swift
import SwiftUI
import MapKit

private enum LocationButtonState {
    case ready, noFix, unauthorized
}

struct ContentView: View {
    private static let romeCenter = CLLocationCoordinate2D(latitude: 41.899159, longitude: 12.473065)

    @Environment(PlaceViewModel.self) private var viewModel
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: ContentView.romeCenter,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    )
    @State private var hasJumpedToUserLocation = false
    @State private var mapSpan: Double = 0.01
    @State private var showGPSWaitToast = false
    @State private var showSettingsAlert = false

    private let romeRegion = MKCoordinateRegion(
        center: ContentView.romeCenter,
        span: MKCoordinateSpan(latitudeDelta: 0.027, longitudeDelta: 0.027)
    )

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

    private var locationButtonIcon: String {
        locationButtonState == .noFix ? "location.slash.fill" : "location.fill"
    }

    private var locationButtonColor: Color {
        switch locationButtonState {
        case .ready:       return .blue
        case .noFix:       return .red
        case .unauthorized: return .gray
        }
    }

    var body: some View {
        let result = viewModel.clusteringResult()
        Map(position: $cameraPosition) {
            if mapSpan > 0.027 {
                ForEach(result.clusters) { cluster in
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
                ForEach(result.singles) { place in
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
        .overlay(alignment: .bottomLeading) {
            Button {
                cameraPosition = .region(romeRegion)
            } label: {
                Label("Rome", systemImage: "building.columns")
            }
            .buttonStyle(.bordered)
            .tint(.white)
            .clipShape(.capsule)
            .shadow(radius: 4)
            .safeAreaPadding(.bottom)
            .padding(.leading, 16)
        }
        .overlay(alignment: .bottomTrailing) {
            Button {
                handleLocationButtonTap()
            } label: {
                Label("My Location", systemImage: locationButtonIcon)
            }
            .buttonStyle(.bordered)
            .tint(locationButtonColor)
            .clipShape(.capsule)
            .shadow(radius: 4)
            .safeAreaPadding(.bottom)
            .padding(.trailing, 16)
        }
        .overlay(alignment: .bottom) {
            if showGPSWaitToast {
                Text("Waiting for GPS signal\u{2026}")
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.regularMaterial, in: Capsule())
                    .transition(.opacity)
                    .padding(.bottom, 80)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showGPSWaitToast)
        .alert("Location Access Required", isPresented: $showSettingsAlert) {
            Button("Open Settings") {
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("To re-center on your position, enable Location in Settings.")
        }
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

    private func handleLocationButtonTap() {
        switch locationButtonState {
        case .ready:
            guard let location = viewModel.userLocation else { return }
            cameraPosition = .region(MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        case .noFix:
            showGPSWaitToast = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showGPSWaitToast = false
            }
        case .unauthorized:
            switch viewModel.authorizationStatus {
            case .notDetermined:
                viewModel.requestAuthorization()
            default:
                showSettingsAlert = true
            }
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

- [ ] **Step 2: Build to verify no compiler errors**

```bash
xcodebuild build -project thirstyinrome.xcodeproj -scheme thirstyinrome -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17' 2>&1 | grep -E "error:|warning:|BUILD SUCCEEDED|BUILD FAILED"
```

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Run full test suite**

```bash
xcodebuild test -project thirstyinrome.xcodeproj -scheme thirstyinrome -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17' 2>&1 | grep -E "error:|warning:|Test Suite|Test Case|PASSED|FAILED|BUILD SUCCEEDED|BUILD FAILED|TEST SUCCEEDED|TEST FAILED"
```

Expected: TEST SUCCEEDED — all tests pass.

- [ ] **Step 4: Commit**

```bash
git add thirstyinrome/ContentView.swift
git commit -m "feat: add GPS re-center button with state-driven color and icon (FEAT-004)"
```
