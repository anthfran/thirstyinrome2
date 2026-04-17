# Stable Place & Cluster IDs — BUG-001 + REFACTOR-003

## Problem

**BUG-001:** `Cluster.id` is `let id = UUID()`, assigned at struct init. `clusteringResult()` is called on every SwiftUI `body` render, creating new `Cluster` instances with new UUIDs each time. `ForEach` sees entirely new identities and tears down/recreates every annotation view unnecessarily.

**REFACTOR-003:** `Place.id` is `let id = UUID()`, generated on every decode. Safe today because places decode once at init, but any future reload would treat all `Marker` views as new.

Both bugs share the same root cause: runtime-generated IDs instead of stable, data-driven ones.

## Goals

- Each `Place` has a stable, pre-assigned ID baked into `Places.json` — consistent across all app installs and app versions.
- `Cluster.id` is derived from its member place IDs — same fountains always produce the same cluster ID.
- IDs are suitable for future cross-device features (reporting broken fountains, attaching photos, etc.).

## ID Format

**Place IDs:** 8-character base62 (`0-9A-Za-z`). ~218 trillion combinations — far more than enough for ~2,300 entries. Short enough to reference in a bug report.

**Cluster IDs:** Member place IDs sorted and concatenated (no separator). Each place ID is exactly 8 chars so the result is unambiguous. A 2-fountain cluster → 16-char ID, 3-fountain → 24-char, etc.

## Design

### 1. ID Generation Script — `scripts/assign_place_ids.py`

A one-time Python script that:
1. Reads `thirstyinrome/Places.json`
2. Generates a random 8-char base62 ID for each entry (collision-checked within the set)
3. Writes the `id` field into each JSON object
4. Writes the updated file back to disk

The script is committed to `scripts/` for auditability but **never run again** — IDs are frozen after the initial assignment.

### 2. `Place` Model

**Before:**
```swift
struct Place: Codable, Identifiable {
    let id = UUID()
    let title: String?
    let lat: Double
    let lon: Double

    enum CodingKeys: String, CodingKey {
        case title, lat, lon
    }
}
```

**After:**
```swift
struct Place: Codable, Identifiable {
    let id: String
    let title: String?
    let lat: Double
    let lon: Double
}
```

`CodingKeys` is removed — all four properties now map directly to JSON keys. `id` decodes from the `"id"` field in `Places.json`.

### 3. `Cluster` Model

**Before:**
```swift
struct Cluster: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let count: Int
    let places: [Place]
}
```

**After:**
```swift
struct Cluster: Identifiable {
    var id: String { places.map(\.id).sorted().joined() }
    let coordinate: CLLocationCoordinate2D
    let count: Int
    let places: [Place]
}
```

`id` is a computed property — no stored state, no UUID allocation. Sorting member IDs before joining ensures order-independence.

### 4. No changes to `PlaceViewModel` or `ContentView`

`clusteringResult()` and `groupByCell()` are unchanged. The stable ID comes for free from the `Place` values already stored in each cluster's `places` array.

## Testing

### Updated fixtures
All `Place` initializers in tests gain a required `id` parameter. Fixtures use simple hardcoded IDs: `"AAAAAAAA"`, `"BBBBBBBB"`, `"CCCCCCCC"`, etc.

### New tests in `ClusterTests`
1. **`testClusterIdIsStableAcrossCalls`** — call `clusteringResult()` twice on the same `PlaceViewModel`; assert cluster IDs are equal across both calls.
2. **`testClusterIdReflectsMembership`** — two clusters with different member sets produce different IDs.

## Branch

`bug/bug-001-refactor-003-stable-ids`

## Backlog Items Resolved

- **BUG-001:** Cluster annotations recreated on every render
- **REFACTOR-003:** Place.id is non-stable across decodes
