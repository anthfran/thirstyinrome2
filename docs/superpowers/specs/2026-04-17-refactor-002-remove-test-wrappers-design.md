# REFACTOR-002: Remove `clusters()` and `singlePlaces()` test-only wrappers

## Summary

`PlaceViewModel` exposes two methods — `clusters()` and `singlePlaces()` — that each call `clusteringResult()` and discard half the returned tuple. Production code uses `clusteringResult()` directly. These wrappers exist only because tests were written against them before `clusteringResult()` was the primary call site. Removing them eliminates redundant API surface and prevents tests from accidentally calling the clustering algorithm twice per assertion.

## Changes

### `thirstyinrome/PlaceViewModel.swift`

Delete lines 109–115 (the `clusters()` and `singlePlaces()` methods). No other production changes are needed — `ContentView` already calls `clusteringResult()` directly.

### `thirstyinromeTests/PlaceTests.swift`

Four call sites across three tests use the wrappers. Each is updated to call `clusteringResult()` once and bind both halves:

```swift
let result = vm.clusteringResult()
// result.clusters replaces the old `clusters` local
// result.singles replaces the old `singles` local
```

Affected tests (5, not 3 as the backlog states — the backlog was written before additional tests were added):
- `testTwoPlacesInSameCellFormOneCluster`
- `testTwoPlacesInDifferentCellsAreEachSingles`
- `testOnePlaceIsASingle`
- `testEmptyPlacesReturnEmpty`
- `testClusterCentroidIsAverage` (reads `clusters` only — still binds via `result` for consistency)

## Acceptance Criteria

- `clusters(` and `singlePlaces(` do not appear anywhere in the codebase after the change
- Build succeeds
- All tests pass
