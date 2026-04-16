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

### FEAT-004: Re-center on GPS button
A button overlaid on the map that re-centers the camera on the user's current location (if location permission has been granted and a fix is available).
