# BUG-004: Cluster Marker Intercepts Pinch-to-Zoom — Design

## Problem

When one finger of a two-finger pinch lands on a cluster annotation, the cluster tap handler fires instead of the map's pinch-to-zoom gesture being recognized.

**Root cause:** The cluster annotation uses a SwiftUI `Button` with `.buttonStyle(.plain)`. `Button` uses SwiftUI's `_ButtonGesture`, which is aggressive about claiming touches (it tracks highlight and press states). When the first pinch finger lands on the button, the button claims that touch before the map's `UIPinchGestureRecognizer` can see both fingers together.

## Fix

Replace `Button { zoomToCluster(cluster) } label: { ZStack { ... } }.buttonStyle(.plain)` with the same `ZStack` content using `.onTapGesture { zoomToCluster(cluster) }`.

`.onTapGesture` maps to a `UITapGestureRecognizer` configured for exactly 1 touch. When a second finger arrives, the tap recognizer fails — which should allow the map's pinch recognizer to win. Single-tap behavior and visual appearance are unchanged.

**File:** `thirstyinrome/ContentView.swift`, cluster `Annotation` content (lines 31–44).

## Fallback

If device testing shows the pinch still does not work, revert this change and implement a `UIViewRepresentable` wrapper that overrides `hitTest(_:with:)` to return `nil` when `event.allTouches?.count ?? 0 > 1`. This is the reliable UIKit-layer fix.

## Acceptance Criteria

- Pinch-to-zoom succeeds regardless of whether a finger starts on a cluster annotation
- Single-finger tap on a cluster still zooms the camera to the cluster's bounding region
- No regression on individual fountain marker tap behavior
