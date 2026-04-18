# BUG-003: GPS Wait Toast Timer Leak — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace `DispatchQueue.main.asyncAfter` in the `.noFix` GPS button tap handler with a cancellable `Task`, so rapid taps don't stack independent timers.

**Architecture:** Add one `@State Task<Void, Never>?` property to `ContentView`. On each `.noFix` tap, cancel the previous task and start a new one that sleeps 2 seconds then dismisses the toast. Only one timer is ever live.

**Tech Stack:** SwiftUI, Swift Concurrency (`Task`, `Task.sleep`)

**Spec:** `docs/superpowers/specs/2026-04-17-bug-003-toast-timer-leak-design.md`

---

## File Map

| File | Change |
|------|--------|
| `thirstyinrome/ContentView.swift` | Add `@State private var toastDismissTask`; replace `.noFix` case body |

---

### Task 1: Create feature branch

- [ ] **Step 1: Create and switch to bug branch**

```bash
git checkout -b bug/bug-003-toast-timer-leak
```

Expected: `Switched to a new branch 'bug/bug-003-toast-timer-leak'`

---

### Task 2: Add the cancellable task state property

**Files:**
- Modify: `thirstyinrome/ContentView.swift:20-22`

- [ ] **Step 1: Add `toastDismissTask` after `showGPSWaitToast`**

In `ContentView`, the current `@State` block (lines 18–21):
```swift
@State private var hasJumpedToUserLocation = false
@State private var mapSpan: Double = 0.01
@State private var showGPSWaitToast = false
@State private var showSettingsAlert = false
```

Replace with:
```swift
@State private var hasJumpedToUserLocation = false
@State private var mapSpan: Double = 0.01
@State private var showGPSWaitToast = false
@State private var showSettingsAlert = false
@State private var toastDismissTask: Task<Void, Never>?
```

- [ ] **Step 2: Build to confirm no errors**

```bash
xcodebuild build -project thirstyinrome.xcodeproj -scheme thirstyinrome -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17' 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED"
```

Expected: `BUILD SUCCEEDED`

---

### Task 3: Replace the `.noFix` case in `handleLocationButtonTap`

**Files:**
- Modify: `thirstyinrome/ContentView.swift:156-160`

- [ ] **Step 1: Replace the `.noFix` case body**

Current code (lines 156–160):
```swift
case .noFix:
    showGPSWaitToast = true
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
        showGPSWaitToast = false
    }
```

Replace with:
```swift
case .noFix:
    showGPSWaitToast = true
    toastDismissTask?.cancel()
    toastDismissTask = Task {
        try? await Task.sleep(for: .seconds(2))
        if !Task.isCancelled {
            showGPSWaitToast = false
        }
    }
```

- [ ] **Step 2: Build to confirm no errors**

```bash
xcodebuild build -project thirstyinrome.xcodeproj -scheme thirstyinrome -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17' 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED"
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Run all tests to confirm no regressions**

```bash
xcodebuild test -project thirstyinrome.xcodeproj -scheme thirstyinrome -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17' -skip-testing:thirstyinromeUITests 2>&1 | grep -E "error:|warning:|Test Suite|Test Case|PASSED|FAILED|BUILD SUCCEEDED|BUILD FAILED|TEST SUCCEEDED|TEST FAILED"
```

Expected: All tests pass, `TEST SUCCEEDED`

- [ ] **Step 4: Commit**

```bash
git add thirstyinrome/ContentView.swift
git commit -m "fix: cancel previous toast task on rapid GPS button taps"
```

---

### Task 4: Update backlog and finish

**Files:**
- Modify: `BACKLOG.md`

- [ ] **Step 1: Mark BUG-003 complete in BACKLOG.md**

Move the `BUG-003` entry from `## Bugs` to `## Completed`, formatted as:

```markdown
### ~~BUG-003: GPS wait toast timer leaks on rapid taps~~ ✓ Done 2026-04-17
**Branch:** `bug/bug-003-toast-timer-leak`
**AC met:**
- No `DispatchQueue.main.asyncAfter` in `handleLocationButtonTap`
- `toastDismissTask` is a `@State Task<Void, Never>?` on `ContentView`
- Rapid taps result in a single dismiss 2 seconds after the last tap
- All existing tests pass
```

- [ ] **Step 2: Commit backlog update**

```bash
git add BACKLOG.md
git commit -m "chore: mark BUG-003 complete in backlog"
```

- [ ] **Step 3: Invoke finishing-a-development-branch skill**
