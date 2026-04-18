# BUG-004: Cluster Pinch-to-Zoom Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix cluster annotation intercepting pinch-to-zoom by replacing `Button` with `.onTapGesture` in the cluster `Annotation` content.

**Architecture:** Single line-level change in `ContentView.swift`. The `Button`/`.buttonStyle(.plain)` is removed; the `ZStack` label content is kept as-is and gains `.onTapGesture`. No new files. No structural changes.

**Tech Stack:** SwiftUI, MapKit (iOS 17+), Xcode 26

---

### Task 1: Create feature branch

**Files:**
- No file changes — git only

- [ ] **Step 1: Create and switch to feature branch**

```bash
git checkout -b fix/bug-004-cluster-pinch-gesture
```

Expected: `Switched to a new branch 'fix/bug-004-cluster-pinch-gesture'`

---

### Task 2: Replace Button with .onTapGesture in cluster annotation

**Files:**
- Modify: `thirstyinrome/ContentView.swift:29-44`

- [ ] **Step 1: Open `thirstyinrome/ContentView.swift` and locate the cluster annotation block (around line 29)**

The current code looks like this:

```swift
ForEach(result.clusters) { cluster in
    Annotation("", coordinate: cluster.coordinate) {
        Button {
            zoomToCluster(cluster)
        } label: {
            ZStack {
                Circle()
                    .fill(.blue)
                    .frame(width: 36, height: 36)
                Text("\(cluster.count)")
                    .foregroundStyle(.white)
                    .font(.system(size: 14, weight: .bold))
            }
        }
        .buttonStyle(.plain)
    }
}
```

- [ ] **Step 2: Replace the Button with .onTapGesture**

Replace the entire `Annotation` content with:

```swift
ForEach(result.clusters) { cluster in
    Annotation("", coordinate: cluster.coordinate) {
        ZStack {
            Circle()
                .fill(.blue)
                .frame(width: 36, height: 36)
            Text("\(cluster.count)")
                .foregroundStyle(.white)
                .font(.system(size: 14, weight: .bold))
        }
        .onTapGesture {
            zoomToCluster(cluster)
        }
    }
}
```

- [ ] **Step 3: Build to verify compilation**

```bash
xcodebuild build -project thirstyinrome.xcodeproj -scheme thirstyinrome -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17' 2>&1 | grep -E "error:|warning:|BUILD SUCCEEDED|BUILD FAILED"
```

Expected: `BUILD SUCCEEDED` with no errors.

- [ ] **Step 4: Run the test suite to verify no regression**

```bash
xcodebuild test -project thirstyinrome.xcodeproj -scheme thirstyinrome -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17' -skip-testing:thirstyinromeUITests 2>&1 | grep -E "error:|warning:|Test Suite|Test Case|PASSED|FAILED|BUILD SUCCEEDED|BUILD FAILED|TEST SUCCEEDED|TEST FAILED"
```

Expected: `TEST SUCCEEDED`, all existing tests pass.

- [ ] **Step 5: Commit**

```bash
git add thirstyinrome/ContentView.swift
git commit -m "fix: replace Button with onTapGesture in cluster annotation to fix pinch-to-zoom"
```

---

### Task 3: Device verification and backlog update

**Files:**
- Modify: `BACKLOG.md`

- [ ] **Step 1: Build and run on a physical iPhone**

Use Xcode to archive or run on the connected device. Test:
1. Zoom out until cluster markers appear (span > 0.027°)
2. Place one finger on a cluster marker and bring a second finger down — pinch to zoom in
3. Verify the map zooms in (not the cluster tap handler)
4. Single-tap a cluster — verify the camera zooms to the cluster's bounding region
5. Zoom in until individual fountain markers appear — verify tapping them still works

- [ ] **Step 2: If device test passes — update BACKLOG.md**

Mark BUG-004 complete. Find the `### BUG-004` entry and replace it with:

```markdown
### ~~BUG-004: Cluster marker intercepts pinch-to-zoom gesture~~ ✓ Done 2026-04-18
**Branch:** `fix/bug-004-cluster-pinch-gesture`
**AC met:**
- Pinch-to-zoom succeeds regardless of whether a finger starts on a cluster annotation
- Single-finger tap on a cluster still zooms the camera to the cluster's bounding region
- No regression on individual fountain marker tap behavior
```

Then move the entry to the `## Completed` section at the bottom of `BACKLOG.md`.

- [ ] **Step 3: Commit backlog update**

```bash
git add BACKLOG.md
git commit -m "chore: mark BUG-004 complete in backlog"
```

- [ ] **Step 4: If device test FAILS — revert and note fallback**

```bash
git revert HEAD
```

Then implement the `UIViewRepresentable` fallback described in the spec at `docs/superpowers/specs/2026-04-18-bug-004-cluster-pinch-design.md`.
