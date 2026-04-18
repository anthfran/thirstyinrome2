# REFACTOR-004: Extract LocationButton Subview — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extract the GPS location button, its state machine, toast, and settings alert from `ContentView` into a self-contained `LocationButton` subview.

**Architecture:** A new `LocationButton.swift` file contains the `LocationButtonState` enum and `LocationButton` view. `LocationButton` reads `PlaceViewModel` from `@Environment`, owns all GPS-specific state, and exposes one callback `onCenterOnUser: (CLLocation) -> Void` that `ContentView` uses to move the camera. `ContentView` replaces ~50 lines of GPS code with a single `LocationButton { ... }` call.

**Tech Stack:** Swift, SwiftUI, CoreLocation, Xcode 26, iOS 17+, Swift Testing

---

### Task 1: Create `LocationButton.swift`

**Files:**
- Create: `thirstyinrome/LocationButton.swift`

This task moves all GPS-specific code out of `ContentView` into a new self-contained view. No changes to `ContentView` yet.

- [ ] **Step 1: Create the file**

Create `thirstyinrome/LocationButton.swift` with this exact content:

```swift
import SwiftUI
import CoreLocation

private enum LocationButtonState {
    case ready, noFix, unauthorized
}

struct LocationButton: View {
    @Environment(PlaceViewModel.self) private var viewModel
    @State private var showGPSWaitToast = false
    @State private var showSettingsAlert = false
    @State private var toastDismissTask: Task<Void, Never>?

    let onCenterOnUser: (CLLocation) -> Void

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
        case .ready:        return .blue
        case .noFix:        return Color(red: 0.83, green: 0.18, blue: 0.18)
        case .unauthorized: return Color(UIColor.systemGray)
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            if showGPSWaitToast {
                Text("Waiting for GPS signal\u{2026}")
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.regularMaterial, in: Capsule())
                    .transition(.opacity)
            }
            Button {
                handleLocationButtonTap()
            } label: {
                Label("My Location", systemImage: locationButtonIcon)
            }
            .buttonStyle(.borderedProminent)
            .tint(locationButtonColor)
            .clipShape(.capsule)
            .shadow(radius: 4)
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
    }

    private func handleLocationButtonTap() {
        switch locationButtonState {
        case .ready:
            guard let location = viewModel.userLocation else { return }
            onCenterOnUser(location)
        case .noFix:
            showGPSWaitToast = true
            toastDismissTask?.cancel()
            toastDismissTask = Task {
                do {
                    try await Task.sleep(for: .seconds(2))
                    showGPSWaitToast = false
                } catch {}
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
}
```

- [ ] **Step 2: Verify it builds (ContentView still has the old GPS code — that's fine for now, both files will compile)**

```bash
xcodebuild build -project thirstyinrome.xcodeproj -scheme thirstyinrome -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17' 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED"
```

Expected: `BUILD SUCCEEDED` (no errors; `LocationButtonState` will be defined in two places temporarily, which is fine because it is `private` in both files)

---

### Task 2: Update `ContentView.swift` to use `LocationButton`

**Files:**
- Modify: `thirstyinrome/ContentView.swift`

Replace the entire file with the version below. This removes the `LocationButtonState` enum, all GPS-specific `@State` vars, the three computed props, `handleLocationButtonTap()`, the two GPS overlays, and the settings alert, then adds a single `LocationButton` overlay in their place.

- [ ] **Step 1: Replace `ContentView.swift`**

Replace the entire contents of `thirstyinrome/ContentView.swift` with:

```swift
import SwiftUI
import MapKit

struct ContentView: View {
    private static let romeCenter = CLLocationCoordinate2D(latitude: 41.899159, longitude: 12.473065)
    // Intentionally matches romeRegion span so clustering switches exactly when zoomed in enough to see individual markers
    private static let clusteringThreshold: Double = 0.027
    private static let zoomedInSpan: Double = 0.01

    @Environment(PlaceViewModel.self) private var viewModel
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: ContentView.romeCenter,
            span: MKCoordinateSpan(latitudeDelta: ContentView.zoomedInSpan, longitudeDelta: ContentView.zoomedInSpan)
        )
    )
    @State private var hasJumpedToUserLocation = false
    @State private var mapSpan: Double = ContentView.zoomedInSpan

    private let romeRegion = MKCoordinateRegion(
        center: ContentView.romeCenter,
        span: MKCoordinateSpan(latitudeDelta: ContentView.clusteringThreshold, longitudeDelta: ContentView.clusteringThreshold)
    )

    var body: some View {
        let result = viewModel.clusteringResult()
        Map(position: $cameraPosition) {
            if mapSpan > ContentView.clusteringThreshold {
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
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 0.75, green: 0.22, blue: 0.17))
            .clipShape(.capsule)
            .shadow(radius: 4)
            .safeAreaPadding(.bottom)
            .padding(.leading, 16)
        }
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
        .onMapCameraChange(frequency: .onEnd) { context in
            mapSpan = context.region.span.latitudeDelta
        }
        .onChange(of: viewModel.userLocation) { _, newLocation in
            guard !hasJumpedToUserLocation, let location = newLocation else { return }
            hasJumpedToUserLocation = true
            cameraPosition = .region(MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: ContentView.zoomedInSpan, longitudeDelta: ContentView.zoomedInSpan)
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

- [ ] **Step 2: Build and run all tests**

```bash
xcodebuild test -project thirstyinrome.xcodeproj -scheme thirstyinrome -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17' -skip-testing:thirstyinromeUITests 2>&1 | grep -E "error:|warning:|Test Suite|Test Case|PASSED|FAILED|BUILD SUCCEEDED|BUILD FAILED|TEST SUCCEEDED|TEST FAILED"
```

Expected: `BUILD SUCCEEDED` and `TEST SUCCEEDED`. All existing tests pass — this refactor moves no logic, only restructures view code.

- [ ] **Step 3: Commit**

```bash
git add thirstyinrome/LocationButton.swift thirstyinrome/ContentView.swift
git commit -m "refactor: extract LocationButton subview from ContentView"
```

---

### Task 3: Update backlog and CLAUDE.md

**Files:**
- Modify: `BACKLOG.md`
- Modify: `CLAUDE.md` (only if a new non-obvious design decision was introduced)

- [ ] **Step 1: Mark REFACTOR-004 done in BACKLOG.md**

Move the REFACTOR-004 entry to the `## Completed` section and format it like the other completed items:

```markdown
### ~~REFACTOR-004: ContentView is doing too much~~ ✓ Done 2026-04-17
**Branch:** `main`
**AC met:**
- `LocationButtonState` enum lives in `LocationButton.swift`, not `ContentView.swift`
- `ContentView` contains no GPS-specific state vars, computed props, or methods
- GPS button, toast, and settings alert behavior unchanged (toast now appears above GPS button in bottom-trailing area)
- Build succeeds and all existing tests pass
```

- [ ] **Step 2: Update CLAUDE.md Architecture section**

Add one bullet under the Architecture section's non-obvious decisions list:

```markdown
- `LocationButton` is a self-contained subview that owns all GPS state (`showGPSWaitToast`, `showSettingsAlert`, `toastDismissTask`). It receives an `onCenterOnUser: (CLLocation) -> Void` callback from `ContentView` to move the camera — it never holds a reference to `cameraPosition`.
```

- [ ] **Step 3: Commit**

```bash
git add BACKLOG.md CLAUDE.md
git commit -m "chore: mark REFACTOR-004 complete in backlog"
```
