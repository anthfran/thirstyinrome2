# Backlog

## Features

### ~~FEAT-001: Marker clustering when zoomed out~~ ✓ Done 2026-04-16
**Branch:** `feat/feat-001-marker-clustering`
**AC met:**
- Markers group into blue circle cluster annotations (count label) when map span > 0.027° (~3km)
- Single-marker grid cells render as individual `Marker`s even when zoomed out
- Tapping a cluster zooms camera to the cluster's bounding region
- All individual markers visible when zoomed in past 0.027°

### FEAT-002: Navigate to fountain via Maps
Tapping a fountain marker shows an action sheet or callout with options to open directions in Apple Maps or Google Maps (falling back to Apple Maps if Google Maps is not installed).

### ~~FEAT-003: Re-center on Rome button~~ ✓ Done 2026-04-16
**Branch:** `feat/feat-003-recenter-rome`
**AC met:**
- White capsule button (building.columns SF Symbol + "Rome" label) overlaid bottom-left on the map
- Tapping instantly resets camera to Rome center (41.899159, 12.473065), span 0.027°
- Button respects safe area (stays above home indicator)

## Bugs

### ~~BUG-001: Cluster annotations recreated on every render~~ ✓ Done 2026-04-16
**Branch:** `bug/bug-001-refactor-003-stable-ids`
**AC met:**
- `Place.id` decoded from `Places.json` — stable across all decodes and app installs, suitable for cross-device reporting
- `Cluster.id` derived from sorted member place IDs — same fountains always produce the same ID
- No `UUID()` allocated at runtime for `Place` or `Cluster`

### BUG-002: authorizationStatus initializes to .notDetermined regardless of actual status
`PlaceViewModel.swift:9` — The property is declared as `.notDetermined` before `setupLocationManager()` runs. On second launch (where permission is already granted) the delegate fires synchronously when `locationManager.delegate = self` is set, so the window is tiny — but it is a latent bug. If timing ever shifts (e.g. background thread), the GPS button would briefly flash grey. Fix: initialize from `locationManager.authorizationStatus` directly in `init()` after calling `setupLocationManager()`.

### BUG-003: GPS wait toast timer leaks on rapid taps
`ContentView.swift:158-160` — Each tap while in `.noFix` state queues a new `DispatchQueue.main.asyncAfter` closure. Rapid taps stack multiple deferred `showGPSWaitToast = false` calls. Harmless now but will cause subtle bugs if toast logic grows. Fix: use a `Task` stored in a `@State` variable, cancelling the previous one on each tap.

## Refactors

### REFACTOR-001: Magic numbers not shared between files
`0.027` (clustering/zoom threshold) and `0.01` (default camera span) appear hardcoded in multiple places across `ContentView.swift` and `PlaceViewModel.swift`. A change to the clustering threshold requires hunting down every occurrence. Fix: define named constants in a shared location (e.g. a `Constants` enum or as `static let` on `PlaceViewModel`).

### REFACTOR-002: clusters() and singlePlaces() are test-only wrappers
`PlaceViewModel.swift:108-114` — Both methods call `clusteringResult()` and discard half the result. Production code only uses `clusteringResult()`. Fix: remove them from production code and update the three tests that use them to call `clusteringResult()` directly.

### ~~REFACTOR-003: Place.id is non-stable across decodes~~ ✓ Done 2026-04-16
**Branch:** `bug/bug-001-refactor-003-stable-ids`
**AC met:**
- `Place.id` is a stable `String` decoded from `Places.json`, not a runtime `UUID()`
- `CodingKeys` removed — all `Place` properties map directly to JSON keys

### REFACTOR-004: ContentView is doing too much
At 190 lines, `ContentView` handles map rendering, clustering branch logic, Rome button, GPS button state machine, toast, and settings alert. The GPS button and `handleLocationButtonTap` are a natural seam to extract into a `LocationButton` subview, making each unit easier to read and test independently.

### REFACTOR-005: Remove dead test scaffolding
Three Xcode-generated test files contain no assertions and slow down every test run. `testLaunchPerformance()` boots the simulator multiple times; `runsForEachTargetApplicationUIConfiguration = true` multiplies launches further. Fix: delete the three files and add `-skip-testing:thirstyinromeUITests` to the CLAUDE.md test command.

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
