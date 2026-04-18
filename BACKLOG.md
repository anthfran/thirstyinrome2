# Backlog

## Features

### FEAT-002: Navigate to fountain via Maps
Tapping a fountain marker shows an action sheet or callout with options to open directions in Apple Maps or Google Maps (falling back to Apple Maps if Google Maps is not installed).

## Bugs

## Refactors

### REFACTOR-004: ContentView is doing too much
At 190 lines, `ContentView` handles map rendering, clustering branch logic, Rome button, GPS button state machine, toast, and settings alert. The GPS button and `handleLocationButtonTap` are a natural seam to extract into a `LocationButton` subview, making each unit easier to read and test independently.

---

## Completed

### ~~REFACTOR-002: clusters() and singlePlaces() are test-only wrappers~~ ✓ Done 2026-04-17
**Branch:** `refactor/refactor-002-remove-test-wrappers`
**AC met:**
- `clusters()` and `singlePlaces()` removed from `PlaceViewModel`
- 5 tests updated to call `clusteringResult()` once per test, binding `result.clusters` / `result.singles`
- No `clusters(` or `singlePlaces(` remain outside docs/history
- All tests pass

### ~~REFACTOR-001: Magic numbers not shared between files~~ ✓ Done 2026-04-17
**Branch:** `refactor/refactor-001-named-constants`
**AC met:**
- `clusteringThreshold` and `zoomedInSpan` defined as `private static let` on `ContentView`
- No bare `0.027` or `0.01` literals remain outside the constant definitions
- Build succeeds

### ~~BUG-003: GPS wait toast timer leaks on rapid taps~~ ✓ Done 2026-04-17
**Branch:** `bug/bug-003-toast-timer-leak`
**AC met:**
- No `DispatchQueue.main.asyncAfter` in `handleLocationButtonTap`
- `toastDismissTask` is a `@State Task<Void, Never>?` on `ContentView`
- Rapid taps result in a single dismiss 2 seconds after the last tap
- All existing tests pass

### ~~FEAT-001: Marker clustering when zoomed out~~ ✓ Done 2026-04-16
**Branch:** `feat/feat-001-marker-clustering`
**AC met:**
- Markers group into blue circle cluster annotations (count label) when map span > 0.027° (~3km)
- Single-marker grid cells render as individual `Marker`s even when zoomed out
- Tapping a cluster zooms camera to the cluster's bounding region
- All individual markers visible when zoomed in past 0.027°

### ~~FEAT-003: Re-center on Rome button~~ ✓ Done 2026-04-16
**Branch:** `feat/feat-003-recenter-rome`
**AC met:**
- White capsule button (building.columns SF Symbol + "Rome" label) overlaid bottom-left on the map
- Tapping instantly resets camera to Rome center (41.899159, 12.473065), span 0.027°
- Button respects safe area (stays above home indicator)

### ~~FEAT-004: Re-center on GPS button~~ ✓ Done 2026-04-16
**Branch:** `feat/feat-004-recenter-gps`
**AC met:**
- Filled capsule button (location.fill SF Symbol + "My Location" label) overlaid bottom-right on the map
- Blue when authorized + GPS fix available — tapping re-centers camera on user position
- Red (location.slash.fill) when authorized but no fix — tapping shows "Waiting for GPS signal…" toast
- Grey when unauthorized — tapping requests permission if not determined, or shows Settings alert if denied
- Settings alert includes "Open Settings" deep link
- Button state updates automatically as authorization and GPS fix change
- distanceFilter set to 10m to avoid redundant updates

### ~~BUG-001: Cluster annotations recreated on every render~~ ✓ Done 2026-04-16
**Branch:** `bug/bug-001-refactor-003-stable-ids`
**AC met:**
- `Place.id` decoded from `Places.json` — stable across all decodes and app installs, suitable for cross-device reporting
- `Cluster.id` derived from sorted member place IDs — same fountains always produce the same ID
- No `UUID()` allocated at runtime for `Place` or `Cluster`

### ~~REFACTOR-003: Place.id is non-stable across decodes~~ ✓ Done 2026-04-16
**Branch:** `bug/bug-001-refactor-003-stable-ids`
**AC met:**
- `Place.id` is a stable `String` decoded from `Places.json`, not a runtime `UUID()`
- `CodingKeys` removed — all `Place` properties map directly to JSON keys

### ~~BUG-002: authorizationStatus initializes to .notDetermined regardless of actual status~~ ✓ Done 2026-04-16
**Branch:** `bug/bug-002-authorization-status-init`
**AC met:**
- `authorizationStatus` reflects the real `CLLocationManager` status immediately after `PlaceViewModel.init()` returns
- No intermediate `.notDetermined` observable on second launch
- Regression test `testAuthorizationStatusMatchesSystemAfterInit` documents the invariant

### ~~REFACTOR-005: Remove dead test scaffolding~~ ✓ Done 2026-04-16
**Branch:** `refactor/refactor-005-remove-dead-tests`
**AC met:**
- `thirstyinromeTests/thirstyinromeTests.swift` deleted
- `thirstyinromeUITests/thirstyinromeUITests.swift` deleted
- `thirstyinromeUITests/thirstyinromeUITestsLaunchTests.swift` deleted
- CLAUDE.md "run all tests" command includes `-skip-testing:thirstyinromeUITests`
- All unit tests in `PlaceTests.swift` pass
