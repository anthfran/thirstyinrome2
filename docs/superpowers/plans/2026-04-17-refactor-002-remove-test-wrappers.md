# REFACTOR-002: Remove Test-Only Wrappers Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove `clusters()` and `singlePlaces()` from `PlaceViewModel` and update the 5 tests that call them to use `clusteringResult()` directly.

**Architecture:** Update tests first (they remain green), then delete the wrappers, then verify. No new behavior — pure removal of redundant API surface.

**Tech Stack:** Swift, Swift Testing (`import Testing`), Xcode 26

---

### Task 1: Create branch

**Files:**
- (none — git only)

- [ ] **Step 1: Create and switch to branch**

```bash
git checkout -b refactor/refactor-002-remove-test-wrappers
```

Expected: `Switched to a new branch 'refactor/refactor-002-remove-test-wrappers'`

---

### Task 2: Update tests to call `clusteringResult()` directly

**Files:**
- Modify: `thirstyinromeTests/PlaceTests.swift:56-109`

Update all 5 tests in `ClusterTests` that currently call `vm.clusters()` or `vm.singlePlaces()`. Each test binds a single `let result = vm.clusteringResult()` and reads `result.clusters` / `result.singles`.

- [ ] **Step 1: Replace `testTwoPlacesInSameCellFormOneCluster`**

Old lines 62-66:
```swift
        let clusters = vm.clusters()
        let singles = vm.singlePlaces()
        try #require(clusters.count == 1)
        #expect(clusters[0].count == 2)
        #expect(singles.isEmpty)
```

New:
```swift
        let result = vm.clusteringResult()
        try #require(result.clusters.count == 1)
        #expect(result.clusters[0].count == 2)
        #expect(result.singles.isEmpty)
```

- [ ] **Step 2: Replace `testTwoPlacesInDifferentCellsAreEachSingles`**

Old lines 76-79:
```swift
        let clusters = vm.clusters()
        let singles = vm.singlePlaces()
        #expect(clusters.isEmpty)
        #expect(singles.count == 2)
```

New:
```swift
        let result = vm.clusteringResult()
        #expect(result.clusters.isEmpty)
        #expect(result.singles.count == 2)
```

- [ ] **Step 3: Replace `testOnePlaceIsASingle`**

Old lines 86-87:
```swift
        #expect(vm.clusters().isEmpty)
        #expect(vm.singlePlaces().count == 1)
```

New:
```swift
        let result = vm.clusteringResult()
        #expect(result.clusters.isEmpty)
        #expect(result.singles.count == 1)
```

- [ ] **Step 4: Replace `testEmptyPlacesReturnEmpty`**

Old lines 94-95:
```swift
        #expect(vm.clusters().isEmpty)
        #expect(vm.singlePlaces().isEmpty)
```

New:
```swift
        let result = vm.clusteringResult()
        #expect(result.clusters.isEmpty)
        #expect(result.singles.isEmpty)
```

- [ ] **Step 5: Replace `testClusterCentroidIsAverage`**

Old lines 105-108:
```swift
        let clusters = vm.clusters()
        try #require(clusters.count == 1)
        #expect(abs(clusters[0].coordinate.latitude  - 41.901) < 0.0001)
        #expect(abs(clusters[0].coordinate.longitude - 12.4705) < 0.0001)
```

New:
```swift
        let result = vm.clusteringResult()
        try #require(result.clusters.count == 1)
        #expect(abs(result.clusters[0].coordinate.latitude  - 41.901) < 0.0001)
        #expect(abs(result.clusters[0].coordinate.longitude - 12.4705) < 0.0001)
```

- [ ] **Step 6: Run tests to verify all pass (wrappers still exist — tests must be green)**

```bash
xcodebuild test -project thirstyinrome.xcodeproj -scheme thirstyinrome -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17' -skip-testing:thirstyinromeUITests 2>&1 | grep -E "error:|warning:|Test Suite|Test Case|PASSED|FAILED|BUILD SUCCEEDED|BUILD FAILED|TEST SUCCEEDED|TEST FAILED"
```

Expected: `TEST SUCCEEDED` with no `FAILED` lines.

---

### Task 3: Remove wrapper methods from `PlaceViewModel`

**Files:**
- Modify: `thirstyinrome/PlaceViewModel.swift:109-116`

- [ ] **Step 1: Delete `clusters()` and `singlePlaces()`**

Remove these lines entirely from `PlaceViewModel.swift`:

```swift
    func clusters(gridSize: Double = defaultGridSize) -> [Cluster] {
        clusteringResult(gridSize: gridSize).clusters
    }

    func singlePlaces(gridSize: Double = defaultGridSize) -> [Place] {
        clusteringResult(gridSize: gridSize).singles
    }
```

The file should end after the closing brace of `clusteringResult()` (the `}` on line 107), followed by the closing `}` of the extension/class.

- [ ] **Step 2: Run tests to verify all pass**

```bash
xcodebuild test -project thirstyinrome.xcodeproj -scheme thirstyinrome -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17' -skip-testing:thirstyinromeUITests 2>&1 | grep -E "error:|warning:|Test Suite|Test Case|PASSED|FAILED|BUILD SUCCEEDED|BUILD FAILED|TEST SUCCEEDED|TEST FAILED"
```

Expected: `TEST SUCCEEDED` with no `FAILED` lines.

- [ ] **Step 3: Verify no remaining usages**

```bash
grep -rn "\.clusters()\|\.singlePlaces()" thirstyinrome/ thirstyinromeTests/
```

Expected: no output.

- [ ] **Step 4: Commit**

```bash
git add thirstyinrome/PlaceViewModel.swift thirstyinromeTests/PlaceTests.swift
git commit -m "refactor: remove clusters() and singlePlaces() test-only wrappers"
```

---

### Task 4: Open PR

- [ ] **Step 1: Invoke finishing-a-development-branch skill**

Invoke `superpowers:finishing-a-development-branch` to decide how to integrate the work.
