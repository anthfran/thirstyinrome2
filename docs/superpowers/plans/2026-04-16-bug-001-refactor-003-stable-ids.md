# Stable Place & Cluster IDs — BUG-001 + REFACTOR-003 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Assign stable 8-char base62 IDs to every place in Places.json, decode them into the Place model, and derive Cluster.id from sorted member IDs — fixing BUG-001 (cluster annotation view churn on every render) and REFACTOR-003 (unstable Place.id across decodes).

**Architecture:** A one-time Python script stamps permanent IDs into Places.json. `Place` decodes `id` as a `String` directly from JSON — no runtime UUID generation. `Cluster.id` is a computed property: member place IDs sorted and concatenated, requiring no stored state.

**Tech Stack:** Python 3 (one-time script), Swift 5.9+, Swift Testing framework, SwiftUI/MapKit (iOS 17+), Xcode 26

---

### Task 1: Create the feature branch

**Files:** none

- [ ] **Step 1: Create and switch to the feature branch**

```bash
git checkout -b bug/bug-001-refactor-003-stable-ids
```
Expected: `Switched to a new branch 'bug/bug-001-refactor-003-stable-ids'`

---

### Task 2: Write and run the ID generation script

**Files:**
- Create: `scripts/assign_place_ids.py`
- Modify: `thirstyinrome/Places.json` (by running the script)

- [ ] **Step 1: Create the scripts directory and write the script**

```bash
mkdir scripts
```

Create `scripts/assign_place_ids.py`:

```python
import json
import random
import string

CHARS = string.digits + string.ascii_letters  # 0–9 A–Z a–z (base62, 62 chars)
ID_LEN = 8


def assign_ids():
    path = 'thirstyinrome/Places.json'
    with open(path, encoding='utf-8') as f:
        places = json.load(f)

    seen = set()
    updated = []
    for place in places:
        while True:
            new_id = ''.join(random.choices(CHARS, k=ID_LEN))
            if new_id not in seen:
                seen.add(new_id)
                break
        updated.append({'id': new_id, **place})

    with open(path, 'w', encoding='utf-8') as f:
        json.dump(updated, f, indent=2, ensure_ascii=False)
        f.write('\n')

    print(f'Assigned stable IDs to {len(updated)} places.')


if __name__ == '__main__':
    assign_ids()
```

- [ ] **Step 2: Run the script from the repo root**

```bash
python3 scripts/assign_place_ids.py
```
Expected output: `Assigned stable IDs to 2300 places.` (exact count may differ slightly)

- [ ] **Step 3: Verify the output**

```bash
head -8 thirstyinrome/Places.json
```
Expected: first entry has `"id"` as its first key, e.g.:
```json
[
  {
    "id": "aB3cD4eF",
    "title": "Fontanella a Valcanneto",
    "lat": 41.94851,
    "lon": 12.158408
  },
```

- [ ] **Step 4: Commit script and updated JSON**

```bash
git add scripts/assign_place_ids.py thirstyinrome/Places.json
git commit -m "chore: assign stable base62 IDs to all places in Places.json"
```

---

### Task 3: Write failing tests for Place.id

**Files:**
- Modify: `thirstyinromeTests/PlaceTests.swift`

These tests **will not compile** with the current `Place` model. `Place.id` is currently `UUID`; comparing it to a `String` literal is a Swift type error. The build failure is the failing test.

- [ ] **Step 1: Add two new tests at the end of `struct PlaceTests`, before its closing `}`**

```swift
@Test func testPlaceIdDecodesFromJSON() throws {
    let json = Data("""
    [{"id": "AAAAAAAA", "title": "Test", "lat": 41.9, "lon": 12.5}]
    """.utf8)
    let places = try JSONDecoder().decode([Place].self, from: json)
    #expect(places[0].id == "AAAAAAAA")
}

@Test func testPlaceIdIsStableAcrossDecodes() throws {
    let json = Data("""
    [{"id": "BBBBBBBB", "lat": 41.9, "lon": 12.5}]
    """.utf8)
    let a = try JSONDecoder().decode([Place].self, from: json)
    let b = try JSONDecoder().decode([Place].self, from: json)
    #expect(a[0].id == b[0].id)
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
xcodebuild test -project thirstyinrome.xcodeproj -scheme thirstyinrome -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17' 2>&1 | grep -E "error:|warning:|Test Suite|Test Case|PASSED|FAILED|BUILD SUCCEEDED|BUILD FAILED|TEST SUCCEEDED|TEST FAILED"
```
Expected: `BUILD FAILED` — type error comparing `UUID` to `String` in the two new tests.

---

### Task 4: Update Place.swift and test fixtures

**Files:**
- Modify: `thirstyinrome/Place.swift`
- Modify: `thirstyinromeTests/PlaceTests.swift`

`Place.id` changes from `let id = UUID()` (excluded from decoding) to `let id: String` (decoded from JSON). The memberwise initializer gains a required `id: String` first parameter. This breaks every `Place(...)` call in the test file. Additionally, `testNilTitleHandled`'s inline JSON omits `"id"` which would now fail to decode since `id` is non-optional — it must be updated too.

- [ ] **Step 1: Replace Place.swift**

Replace the entire contents of `thirstyinrome/Place.swift` with:

```swift
import Foundation

struct Place: Codable, Identifiable {
    let id: String
    let title: String?
    let lat: Double
    let lon: Double
}
```

- [ ] **Step 2: Replace the entire PlaceTests.swift**

Replace the entire contents of `thirstyinromeTests/PlaceTests.swift` with:

```swift
import Testing
import Foundation
import CoreLocation
@testable import thirstyinrome

struct PlaceTests {

    @Test func testPlacesJSONLoads() throws {
        let places = try loadAllPlaces()
        #expect(!places.isEmpty)
    }

    @Test func testNilTitleHandled() throws {
        let json = Data("""
        [{"id": "CCCCCCCC", "lat": 41.9, "lon": 12.5}]
        """.utf8)
        let places = try JSONDecoder().decode([Place].self, from: json)
        #expect(places.count == 1)
        #expect(places[0].title == nil)
    }

    @Test func testCoordinatesInRomeBounds() throws {
        let places = try loadAllPlaces()
        for place in places {
            #expect((41.0...42.0).contains(place.lat), "lat \(place.lat) out of Rome bounds")
            #expect((12.0...13.0).contains(place.lon), "lon \(place.lon) out of Rome bounds")
        }
    }

    @Test func testPlaceIdDecodesFromJSON() throws {
        let json = Data("""
        [{"id": "AAAAAAAA", "title": "Test", "lat": 41.9, "lon": 12.5}]
        """.utf8)
        let places = try JSONDecoder().decode([Place].self, from: json)
        #expect(places[0].id == "AAAAAAAA")
    }

    @Test func testPlaceIdIsStableAcrossDecodes() throws {
        let json = Data("""
        [{"id": "BBBBBBBB", "lat": 41.9, "lon": 12.5}]
        """.utf8)
        let a = try JSONDecoder().decode([Place].self, from: json)
        let b = try JSONDecoder().decode([Place].self, from: json)
        #expect(a[0].id == b[0].id)
    }

    private func loadAllPlaces() throws -> [Place] {
        let url = try #require(Bundle.main.url(forResource: "Places", withExtension: "json"))
        return try JSONDecoder().decode([Place].self, from: Data(contentsOf: url))
    }
}

struct ClusterTests {

    // Two places in the same 0.008° cell → one cluster, no singles
    @Test func testTwoPlacesInSameCellFormOneCluster() throws {
        let vm = PlaceViewModel()
        vm.places = [
            Place(id: "AAAAAAAA", title: "A", lat: 41.900, lon: 12.470),
            Place(id: "BBBBBBBB", title: "B", lat: 41.901, lon: 12.471)
        ]
        let clusters = vm.clusters()
        let singles = vm.singlePlaces()
        try #require(clusters.count == 1)
        #expect(clusters[0].count == 2)
        #expect(singles.isEmpty)
    }

    // Two places in different 0.008° cells → two singles, no clusters
    @Test func testTwoPlacesInDifferentCellsAreEachSingles() {
        let vm = PlaceViewModel()
        vm.places = [
            Place(id: "AAAAAAAA", title: "A", lat: 41.900, lon: 12.470),
            Place(id: "BBBBBBBB", title: "B", lat: 41.950, lon: 12.520)
        ]
        let clusters = vm.clusters()
        let singles = vm.singlePlaces()
        #expect(clusters.isEmpty)
        #expect(singles.count == 2)
    }

    // One place alone → not in clusters, appears in singlePlaces
    @Test func testOnePlaceIsASingle() {
        let vm = PlaceViewModel()
        vm.places = [Place(id: "AAAAAAAA", title: "A", lat: 41.900, lon: 12.470)]
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
    @Test func testClusterCentroidIsAverage() throws {
        let vm = PlaceViewModel()
        vm.places = [
            Place(id: "AAAAAAAA", title: "A", lat: 41.900, lon: 12.470),
            Place(id: "BBBBBBBB", title: "B", lat: 41.902, lon: 12.471)
        ]
        let clusters = vm.clusters()
        try #require(clusters.count == 1)
        #expect(abs(clusters[0].coordinate.latitude  - 41.901) < 0.0001)
        #expect(abs(clusters[0].coordinate.longitude - 12.4705) < 0.0001)
    }
}

struct LocationViewModelTests {

    @Test func testAuthorizationStatusIsReadable() {
        let vm = PlaceViewModel()
        let _ = vm.authorizationStatus
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

- [ ] **Step 3: Run tests to verify they all pass**

```bash
xcodebuild test -project thirstyinrome.xcodeproj -scheme thirstyinrome -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17' 2>&1 | grep -E "error:|warning:|Test Suite|Test Case|PASSED|FAILED|BUILD SUCCEEDED|BUILD FAILED|TEST SUCCEEDED|TEST FAILED"
```
Expected: `TEST SUCCEEDED` — all tests pass including `testPlaceIdDecodesFromJSON` and `testPlaceIdIsStableAcrossDecodes`.

- [ ] **Step 4: Commit**

```bash
git add thirstyinrome/Place.swift thirstyinromeTests/PlaceTests.swift
git commit -m "fix: decode Place.id from JSON, remove runtime UUID — fixes REFACTOR-003"
```

---

### Task 5: Write failing tests for Cluster.id stability

**Files:**
- Modify: `thirstyinromeTests/PlaceTests.swift`

These tests compile (`Cluster.id` is `UUID` which supports `==`), but fail at runtime: `UUID()` allocates a new value on every `Cluster` init, so two calls to `clusteringResult()` produce clusters with different IDs even for identical places.

- [ ] **Step 1: Add two new tests at the end of `struct ClusterTests`, before its closing `}`**

```swift
@Test func testClusterIdIsStableAcrossCalls() throws {
    let vm = PlaceViewModel()
    vm.places = [
        Place(id: "AAAAAAAA", title: "A", lat: 41.900, lon: 12.470),
        Place(id: "BBBBBBBB", title: "B", lat: 41.901, lon: 12.471)
    ]
    let first = vm.clusteringResult().clusters
    let second = vm.clusteringResult().clusters
    try #require(first.count == 1)
    try #require(second.count == 1)
    #expect(first[0].id == second[0].id)
}

@Test func testClusterIdIsDeterministic() throws {
    let vm1 = PlaceViewModel()
    vm1.places = [
        Place(id: "AAAAAAAA", title: "A", lat: 41.900, lon: 12.470),
        Place(id: "BBBBBBBB", title: "B", lat: 41.901, lon: 12.471)
    ]
    let vm2 = PlaceViewModel()
    vm2.places = [
        Place(id: "AAAAAAAA", title: "A", lat: 41.900, lon: 12.470),
        Place(id: "BBBBBBBB", title: "B", lat: 41.901, lon: 12.471)
    ]
    let c1 = try #require(vm1.clusteringResult().clusters.first)
    let c2 = try #require(vm2.clusteringResult().clusters.first)
    #expect(c1.id == c2.id)
}
```

- [ ] **Step 2: Run tests to verify the new ones fail**

```bash
xcodebuild test -project thirstyinrome.xcodeproj -scheme thirstyinrome -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17' 2>&1 | grep -E "error:|warning:|Test Suite|Test Case|PASSED|FAILED|BUILD SUCCEEDED|BUILD FAILED|TEST SUCCEEDED|TEST FAILED"
```
Expected: `TEST FAILED` — `testClusterIdIsStableAcrossCalls` and `testClusterIdIsDeterministic` fail because each `clusteringResult()` call allocates new `UUID()` values for every `Cluster`.

---

### Task 6: Update Cluster.swift

**Files:**
- Modify: `thirstyinrome/Cluster.swift`

- [ ] **Step 1: Replace Cluster.swift**

Replace the entire contents of `thirstyinrome/Cluster.swift` with:

```swift
import Foundation
import CoreLocation

struct Cluster: Identifiable {
    var id: String { places.map(\.id).sorted().joined() }
    let coordinate: CLLocationCoordinate2D
    let count: Int
    let places: [Place]
}
```

`id` sorts member place IDs alphabetically before joining so the result is order-independent — the same set of fountains in any order produces the same ID. Each place ID is exactly 8 chars, so the concatenation is unambiguous without a separator.

- [ ] **Step 2: Run all tests**

```bash
xcodebuild test -project thirstyinrome.xcodeproj -scheme thirstyinrome -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17' 2>&1 | grep -E "error:|warning:|Test Suite|Test Case|PASSED|FAILED|BUILD SUCCEEDED|BUILD FAILED|TEST SUCCEEDED|TEST FAILED"
```
Expected: `TEST SUCCEEDED` — all tests pass.

- [ ] **Step 3: Commit**

```bash
git add thirstyinrome/Cluster.swift thirstyinromeTests/PlaceTests.swift
git commit -m "fix: derive stable Cluster.id from sorted member place IDs — fixes BUG-001"
```

---

### Task 7: Update BACKLOG.md

**Files:**
- Modify: `BACKLOG.md`

- [ ] **Step 1: Mark BUG-001 as done**

In `BACKLOG.md`, replace:

```markdown
### BUG-001: Cluster annotations recreated on every render
`Cluster.swift:5` — `let id = UUID()` generates a new UUID each time `clusteringResult()` is called. Since `clusteringResult()` runs on every `body` render, SwiftUI's `ForEach` sees entirely new cluster IDs each time and tears down/recreates every annotation. Causes unnecessary view churn and prevents smooth transitions. Fix: derive a stable ID from the grid cell key (e.g. `"\(row)_\(col)"`) or the coordinate.
```

With:

```markdown
### ~~BUG-001: Cluster annotations recreated on every render~~ ✓ Done 2026-04-16
**Branch:** `bug/bug-001-refactor-003-stable-ids`
**AC met:**
- `Place.id` decoded from `Places.json` — stable across all decodes and app installs, suitable for cross-device reporting
- `Cluster.id` derived from sorted member place IDs — same fountains always produce the same ID
- No `UUID()` allocated at runtime for `Place` or `Cluster`
```

- [ ] **Step 2: Mark REFACTOR-003 as done**

In `BACKLOG.md`, replace:

```markdown
### REFACTOR-003: Place.id is non-stable across decodes
`Place.swift:4` — `let id = UUID()` generates a new UUID on every decode. Currently safe because places decode once at init. If the dataset is ever refreshed or reloaded, all `Marker` views would be treated as new by SwiftUI's `ForEach`, causing full redraws. Fix: derive a stable ID from lat/lon (e.g. `"\(lat),\(lon)"`).
```

With:

```markdown
### ~~REFACTOR-003: Place.id is non-stable across decodes~~ ✓ Done 2026-04-16
**Branch:** `bug/bug-001-refactor-003-stable-ids`
**AC met:**
- `Place.id` is a stable `String` decoded from `Places.json`, not a runtime `UUID()`
- `CodingKeys` removed — all `Place` properties map directly to JSON keys
```

- [ ] **Step 3: Commit**

```bash
git add BACKLOG.md
git commit -m "chore: mark BUG-001 and REFACTOR-003 complete in backlog"
```
