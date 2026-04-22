# FEAT-007: Compass/Heading-Up Map Mode — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a top-right compass toggle button that rotates the map to match device heading, with a directional cone always shown on the user dot when heading data is available.

**Architecture:** `PlaceViewModel` starts heading updates whenever location is authorized and publishes `userHeading`; `UserAnnotation()` renders the cone automatically. `ContentView` gains `isHeadingUp: Bool` state and a compass button overlay; toggling on sets `cameraPosition = .userLocation(followsHeading: true, fallback:)`; panning is detected via `onChange(of: cameraPosition)` checking `positionedByUser`; Rome and GPS buttons explicitly reset `isHeadingUp = false`.

**Tech Stack:** SwiftUI, MapKit (SwiftUI, iOS 17+), CoreLocation, Swift Testing

---

## Files

- Modify: `thirstyinrome/PlaceViewModel.swift` — add `userHeading`, `startUpdatingHeading()` call, heading delegate
- Modify: `thirstyinrome/ContentView.swift` — add `isHeadingUp` state, compass button overlay, pan-exit detection, Rome/GPS exit wiring

---

### Task 1: Create feature branch

- [ ] **Create and check out the feature branch**

```bash
git checkout -b feat/feat-007-compass-heading
```

Expected: `Switched to a new branch 'feat/feat-007-compass-heading'`

---

### Task 2: Add heading tracking to PlaceViewModel

**Files:**
- Modify: `thirstyinrome/PlaceViewModel.swift`

- [ ] **Step 1: Add `userHeading` published property**

In `thirstyinrome/PlaceViewModel.swift`, add `var userHeading: CLHeading?` directly below `var authorizationStatus`:

```swift
var authorizationStatus: CLAuthorizationStatus = .notDetermined
var userHeading: CLHeading?
```

- [ ] **Step 2: Start heading updates alongside location updates**

In `locationManagerDidChangeAuthorization`, add `manager.startUpdatingHeading()` on the line after `manager.startUpdatingLocation()`:

```swift
case .authorizedWhenInUse, .authorizedAlways:
    if !isUpdatingLocation {
        isUpdatingLocation = true
        manager.startUpdatingLocation()
        manager.startUpdatingHeading()
    }
```

- [ ] **Step 3: Implement the heading delegate method**

Add this method in the `// MARK: - CLLocationManagerDelegate` section, directly below `locationManager(_:didFailWithError:)`:

```swift
func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
    guard newHeading.headingAccuracy >= 0 else { return }
    userHeading = newHeading
}
```

- [ ] **Step 4: Build to confirm no errors**

```bash
xcodebuild build -project thirstyinrome.xcodeproj -scheme thirstyinrome -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17' 2>&1 | grep -E "error:|warning:|BUILD SUCCEEDED|BUILD FAILED"
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 5: Run existing tests to confirm no regressions**

```bash
xcodebuild test -project thirstyinrome.xcodeproj -scheme thirstyinrome -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17' -skip-testing:thirstyinromeUITests 2>&1 | grep -E "error:|warning:|Test Suite|Test Case|PASSED|FAILED|BUILD SUCCEEDED|BUILD FAILED|TEST SUCCEEDED|TEST FAILED"
```

Expected: `TEST SUCCEEDED`, all existing tests PASSED.

- [ ] **Step 6: Commit**

```bash
git add thirstyinrome/PlaceViewModel.swift
git commit -m "feat: add heading tracking to PlaceViewModel"
```

---

### Task 3: Add compass button and heading-up logic to ContentView

**Files:**
- Modify: `thirstyinrome/ContentView.swift`

This task adds:
1. `isHeadingUp` state
2. Compass button overlay (top-right)
3. `isHeadingUp = false` resets in Rome button and GPS callback (explicit — programmatic camera changes don't set `positionedByUser`, so they can't be inferred from `onChange`)
4. `onChange(of: cameraPosition)` pan-exit detection

- [ ] **Step 1: Add `isHeadingUp` state**

In `thirstyinrome/ContentView.swift`, add `@State private var isHeadingUp = false` directly below `@State private var selectedPlace: Place?`:

```swift
@State private var selectedPlace: Place?
@State private var isHeadingUp = false
```

- [ ] **Step 2: Add the compass button overlay**

After the closing brace of the existing `.overlay(alignment: .bottomTrailing)` block (the one containing `LocationButton`), add:

```swift
.overlay(alignment: .topTrailing) {
    Button {
        isHeadingUp.toggle()
        if isHeadingUp {
            cameraPosition = .userLocation(followsHeading: true, fallback: cameraPosition)
        }
    } label: {
        Label("Heading Up", systemImage: "safari")
    }
    .buttonStyle(.borderedProminent)
    .tint(isHeadingUp ? .blue : Color(UIColor.systemGray))
    .clipShape(.capsule)
    .shadow(radius: 4)
    .safeAreaPadding(.top)
    .padding(.trailing, 16)
}
```

- [ ] **Step 3: Reset `isHeadingUp` in the Rome button action**

The Rome button currently reads:

```swift
Button {
    cameraPosition = .region(romeRegion)
} label: {
    Label("Rome", systemImage: "building.columns")
}
```

Update its action to reset heading-up first:

```swift
Button {
    isHeadingUp = false
    cameraPosition = .region(romeRegion)
} label: {
    Label("Rome", systemImage: "building.columns")
}
```

- [ ] **Step 4: Reset `isHeadingUp` in the GPS callback**

The `LocationButton` closure currently reads:

```swift
LocationButton { location in
    cameraPosition = .region(MKCoordinateRegion(
        center: location.coordinate,
        span: MKCoordinateSpan(latitudeDelta: Self.zoomedInSpan, longitudeDelta: Self.zoomedInSpan)
    ))
}
```

Update it:

```swift
LocationButton { location in
    isHeadingUp = false
    cameraPosition = .region(MKCoordinateRegion(
        center: location.coordinate,
        span: MKCoordinateSpan(latitudeDelta: Self.zoomedInSpan, longitudeDelta: Self.zoomedInSpan)
    ))
}
```

- [ ] **Step 5: Add pan-exit detection**

After the existing `.onChange(of: viewModel.userLocation)` modifier, add:

```swift
.onChange(of: cameraPosition) { _, newPosition in
    guard isHeadingUp, newPosition.positionedByUser else { return }
    isHeadingUp = false
}
```

`positionedByUser` is `true` only when MapKit updates `cameraPosition` in response to a user gesture (pan/pinch). Programmatic sets (Rome button, GPS callback, heading-up toggle) leave it `false`, so those paths are covered by the explicit resets in Steps 3 and 4 above.

- [ ] **Step 6: Build to confirm no errors**

```bash
xcodebuild build -project thirstyinrome.xcodeproj -scheme thirstyinrome -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17' 2>&1 | grep -E "error:|warning:|BUILD SUCCEEDED|BUILD FAILED"
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 7: Run full test suite**

```bash
xcodebuild test -project thirstyinrome.xcodeproj -scheme thirstyinrome -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17' -skip-testing:thirstyinromeUITests 2>&1 | grep -E "error:|warning:|Test Suite|Test Case|PASSED|FAILED|BUILD SUCCEEDED|BUILD FAILED|TEST SUCCEEDED|TEST FAILED"
```

Expected: `TEST SUCCEEDED`, all tests PASSED.

- [ ] **Step 8: Commit**

```bash
git add thirstyinrome/ContentView.swift
git commit -m "feat: add compass heading-up toggle to map"
```

---

## Self-Review Checklist (completed inline)

**Spec coverage:**
- [x] Compass button appears top-right with `safari` symbol — Task 3 Step 2
- [x] Tapping enters heading-up: `cameraPosition = .userLocation(followsHeading: true, fallback:)` — Task 3 Step 2
- [x] Directional cone in both modes — handled by `startUpdatingHeading()` always-on in Task 2; `UserAnnotation()` renders automatically
- [x] Tapping again exits heading-up — `isHeadingUp.toggle()` + no camera change — Task 3 Step 2
- [x] Pan exits heading-up — Task 3 Step 5
- [x] Rome button exits heading-up — Task 3 Step 3
- [x] GPS button exits heading-up — Task 3 Step 4
- [x] Build succeeds + existing tests pass — Task 2 Steps 4-5, Task 3 Steps 6-7

**Placeholder scan:** No TBDs, TODOs, or vague steps.

**Type consistency:** `isHeadingUp: Bool` used consistently across all steps. `cameraPosition` binding name matches existing ContentView. `userHeading: CLHeading?` property name used only in PlaceViewModel and not referenced from ContentView (UserAnnotation renders it implicitly via MapKit).
