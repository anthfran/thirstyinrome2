# FEAT-003: Re-center on Rome Button — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a bottom-left overlay button to the map that instantly resets the camera to Rome city center at the clustering zoom level.

**Architecture:** Single `.overlay(alignment: .bottomLeading)` modifier added to the `Map` in `ContentView.swift`. A private `romeRegion` constant defines the target region (41.899159, 12.473065, span 0.027°). Button action directly assigns to `cameraPosition` — no animation.

**Tech Stack:** SwiftUI, MapKit. Swift Testing for tests. `xcodebuild` is the build/test command — never use Xcode GUI.

---

## File Map

| File | Change |
|------|--------|
| `thirstyinrome/ContentView.swift` | Add `romeRegion` constant + `.overlay` with button |
| `thirstyinromeTests/PlaceTests.swift` | No change — no new business logic |

> **Note on testing:** This feature adds no business logic — the button is pure UI wired to a `@State` variable. There is nothing to unit test. Verification is a passing build + existing test suite still green.

---

### Task 1: Create feature branch

- [ ] **Step 1: Create and check out the branch**

```bash
git checkout -b feat/feat-003-recenter-rome
```

Expected: `Switched to a new branch 'feat/feat-003-recenter-rome'`

---

### Task 2: Add `romeRegion` constant and button overlay to `ContentView`

**Files:**
- Modify: `thirstyinrome/ContentView.swift`

The current `ContentView.swift` looks like this (shown in full for context):

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
        let result = viewModel.clusteringResult()
        Map(position: $cameraPosition) {
            // ... markers ...
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

    private func zoomToCluster(_ cluster: Cluster) { ... }
}
```

- [ ] **Step 1: Add the `romeRegion` constant**

Add the following `let` immediately after the `@State private var mapSpan` line (before `var body`):

```swift
    private let romeRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.899159, longitude: 12.473065),
        span: MKCoordinateSpan(latitudeDelta: 0.027, longitudeDelta: 0.027)
    )
```

- [ ] **Step 2: Add the `.overlay` button modifier**

Add `.overlay(alignment: .bottomLeading)` to the `Map` modifier chain, after `.ignoresSafeArea()` and before `.onMapCameraChange`. The full modifier chain should read:

```swift
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
            .padding(.leading, 16)
            .safeAreaPadding(.bottom)
        }
        .onMapCameraChange(frequency: .onEnd) { context in
```

`.safeAreaPadding(.bottom)` pushes the button above the home indicator. It is available on iOS 17+ (which this app requires).

---

### Task 3: Build and verify existing tests still pass

- [ ] **Step 1: Build the app**

```bash
xcodebuild build -project thirstyinrome.xcodeproj -scheme thirstyinrome -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17' 2>&1 | tail -5
```

Expected output ends with:
```
** BUILD SUCCEEDED **
```

If it fails, read the full output (`remove 2>&1 | tail -5`) and fix the compile error before continuing.

- [ ] **Step 2: Run the test suite**

```bash
xcodebuild test -project thirstyinrome.xcodeproj -scheme thirstyinrome -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17' 2>&1 | tail -10
```

Expected output ends with:
```
** TEST SUCCEEDED **
```

---

### Task 4: Commit

- [ ] **Step 1: Stage and commit**

```bash
git add thirstyinrome/ContentView.swift
git commit -m "feat: add re-center on Rome button (FEAT-003)"
```

---

### Task 5: Update backlog

- [ ] **Step 1: Mark FEAT-003 complete in `BACKLOG.md`**

In `BACKLOG.md`, strike through the FEAT-003 heading and add completion metadata below it:

```markdown
### ~~FEAT-003: Re-center on Rome button~~ ✓ Done 2026-04-16
**Branch:** `feat/feat-003-recenter-rome`
**AC met:**
- White capsule button (building.columns SF Symbol + "Rome" label) overlaid bottom-left on the map
- Tapping instantly resets camera to Rome center (41.899159, 12.473065), span 0.027°
- Button respects safe area (stays above home indicator)
```

- [ ] **Step 2: Commit the backlog update**

```bash
git add BACKLOG.md
git commit -m "chore: mark FEAT-003 complete in backlog"
```
