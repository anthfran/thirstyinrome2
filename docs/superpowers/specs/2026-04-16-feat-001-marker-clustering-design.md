# FEAT-001: Marker Clustering Design

**Date:** 2026-04-16
**Feature:** Marker clustering when zoomed out

## Summary

When the map is zoomed out past a span of `0.02°`, nearby fountain markers are grouped into cluster annotations showing a count. Zooming in past `0.02°` reveals all individual markers. Tapping a cluster zooms the camera into its bounding region.

## Behavior

- **Threshold:** `latitudeDelta > 0.02°` → cluster mode; `≤ 0.02°` → individual marker mode
- **Clustering algorithm:** Grid-based. Each place snaps to a grid cell of size `0.008°` (~800m at Rome's latitude). Places sharing a cell are grouped into one cluster.
- **Cluster visual:** Blue circle with white count label, rendered via `Annotation` (not `Marker`) to allow custom styling.
- **Single-marker cells:** A cell containing exactly one place renders as an individual `Marker` (no count badge), even in cluster mode.
- **Tap to expand:** Tapping a cluster sets the camera to fit the cluster's bounding box with padding. If all markers in the cluster share the same coordinate, falls back to a span of `0.005°`.

## Architecture

### New: `Cluster` struct

```swift
struct Cluster: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let count: Int
    let places: [Place]
}
```

### Modified: `PlaceViewModel`

Adds one method:

```swift
func clusters(gridSize: Double = 0.008) -> [Cluster]
```

Groups `places` by `(floor(lat / gridSize), floor(lon / gridSize))` cell key. Each cell's cluster coordinate is the centroid of its constituent places. Returns one `Cluster` per cell that contains 2+ places; single-place cells are excluded (the caller renders them as individual markers).

### Modified: `ContentView`

- Adds `@State private var mapSpan: Double = 0.01`
- Attaches `.onMapCameraChange(frequency: .onEnd) { context in mapSpan = context.region.span.latitudeDelta }` to the `Map`
- In the `Map` content closure:
  - If `mapSpan > 0.02`: render `viewModel.clusters()` as `Annotation` views (blue circle + count), plus individual `Marker`s for single-place cells
  - If `mapSpan ≤ 0.02`: render `viewModel.places` as individual `Marker`s (existing behavior)
- Adds `func zoomToCluster(_ cluster: Cluster)` that computes the cluster's bounding box and updates `cameraPosition`

## Data Flow

```
PlaceViewModel.places (static, loaded at init)
    ↓ clusters(gridSize:) — called in view body
[Cluster] + [Place] (singles)
    ↓ rendered conditionally on mapSpan
Map annotations
```

## Edge Cases

- **Empty cluster:** `guard !places.isEmpty` in `clusters(gridSize:)` — unreachable by construction.
- **All markers at same coordinate:** `zoomToCluster` falls back to `span = 0.005°` when bounding box has zero area.
- **Grid size:** Hardcoded at `0.008°`. Not configurable — YAGNI.

## Testing

- Unit test `clusters(gridSize:)` with a known set of places spanning multiple cells — verify correct grouping, centroid calculation, and that single-place cells are excluded from the result.
- Unit test `clusters(gridSize:)` with all places in one cell — verify one cluster returned.
- Unit test with zero places — verify empty array returned.
