# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

**Build:**
```bash
xcodebuild build -project thirstyinrome.xcodeproj -scheme thirstyinrome -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17'
```

**Run all tests:**
```bash
xcodebuild test -project thirstyinrome.xcodeproj -scheme thirstyinrome -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17' 2>&1 | grep -E "error:|warning:|Test Suite|Test Case|PASSED|FAILED|BUILD SUCCEEDED|BUILD FAILED|TEST SUCCEEDED|TEST FAILED"
```

**Run a single test:**
```bash
xcodebuild test -project thirstyinrome.xcodeproj -scheme thirstyinrome -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17' -only-testing:thirstyinromeTests/PlaceTests/testPlacesJSONLoads 2>&1 | grep -E "error:|warning:|Test Suite|Test Case|PASSED|FAILED|BUILD SUCCEEDED|BUILD FAILED|TEST SUCCEEDED|TEST FAILED"
```

## Architecture

Single-screen SwiftUI app (iOS 17+, Xcode 26). No navigation stack, no tabs.

**Data flow:**
- `thirstyinromeApp` creates one `PlaceViewModel` as `@State` and injects it via `.environment(viewModel)`
- `ContentView` reads it with `@Environment(PlaceViewModel.self)` — this is the `@Observable` pattern, not `@EnvironmentObject`
- `PlaceViewModel` loads `Places.json` synchronously in `init()` and owns all location state

**`PlaceViewModel`** (`@Observable`, `NSObject`, `CLLocationManagerDelegate`):
- Decodes `thirstyinrome/Places.json` from `Bundle.main` at init into `var places: [Place]`
- Manages `CLLocationManager`: requests `whenInUse` auth only when status is `.notDetermined`, starts updates in the delegate callback after authorization
- Exposes `var userLocation: CLLocation?` updated on each GPS fix

**`ContentView`**:
- Full-screen `Map(position: $cameraPosition)` with a `Marker` per fountain and `UserAnnotation()` for the GPS dot
- Default camera: Rome center `(41.899159, 12.473065)`, span `0.01°`
- On first non-nil `userLocation`, jumps camera once to user position; `hasJumpedToUserLocation` prevents subsequent GPS updates from overriding user panning

**`Place`** — `Codable + Identifiable` struct with `title: String?`, `lat`, `lon`. `id = UUID()` is excluded from `CodingKeys` (no stable ID in the JSON). Two entries in the dataset have `nil` titles; these display as `"Fontanella"` on the map.

## Project Setup Notes

- **File System Synchronized Groups** (Xcode 16+): any `.swift` or resource file added to `thirstyinrome/` on disk is automatically included in the build — no `project.pbxproj` edit needed for new source files.
- **`GENERATE_INFOPLIST_FILE = YES`**: there is no separate `Info.plist`. Keys like `NSLocationWhenInUseUsageDescription` are set via `INFOPLIST_KEY_*` build settings in `project.pbxproj`.
- **`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`**: all types are implicitly `@MainActor`. No explicit annotations needed on the ViewModel or delegate methods.
- **Test bundle**: the test target uses `BUNDLE_LOADER`, so tests run inside the app process. `Bundle.main` in tests resolves to the app bundle — `Places.json` does not need to be separately added to the test target.

## Testing

Tests use **Swift Testing** (`import Testing`, `@Test`, `#expect`, `#require`) — not XCTest. The test suite is in `thirstyinromeTests/PlaceTests.swift`. SourceKit may show "No such module 'Testing'" spuriously; `xcodebuild` is the source of truth.

## Backlog

Planned features and bugs are tracked in `BACKLOG.md`. IDs follow the format `FEAT-001`, `BUG-001`, `REFACTOR-001`.

**Workflow for completing a backlog item:**
1. **Brainstorm** — invoke `superpowers:brainstorming`. Flesh out requirements with the user, get design approval, and save the spec to `docs/superpowers/specs/`.
2. **Plan** — `superpowers:brainstorming` hands off to `superpowers:writing-plans`, which saves an implementation plan to `docs/superpowers/plans/`.
3. **Execute** — invoke `superpowers:subagent-driven-development` to implement the plan task-by-task with spec and quality review gates.
4. **Finish** — invoke `superpowers:finishing-a-development-branch` to decide how to integrate the work.
