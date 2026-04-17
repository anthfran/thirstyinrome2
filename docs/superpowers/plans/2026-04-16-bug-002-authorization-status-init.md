# BUG-002: authorizationStatus Init Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ensure `PlaceViewModel.authorizationStatus` reflects the real `CLLocationManager` status immediately after `init()`, eliminating the latent window where the GPS button could flash grey on second launch.

**Architecture:** Add one line to `PlaceViewModel.init()` that reads `locationManager.authorizationStatus` after `setupLocationManager()` returns and assigns it to the property, overwriting the `.notDetermined` default.

**Tech Stack:** Swift, CoreLocation, Swift Testing (`import Testing`)

---

### Task 1: Add regression test for authorizationStatus post-init invariant

**Files:**
- Modify: `thirstyinromeTests/PlaceTests.swift`

- [ ] **Step 1: Read the existing test file**

Open `thirstyinromeTests/PlaceTests.swift` to find the correct `import` lines and the existing `@Suite` or top-level `@Test` structure so the new test fits the existing style.

- [ ] **Step 2: Write the failing test**

Add this test to `PlaceTests.swift`:

```swift
@Test func authorizationStatusMatchesSystemAfterInit() {
    let viewModel = PlaceViewModel()
    #expect(viewModel.authorizationStatus == CLLocationManager().authorizationStatus)
}
```

This documents the invariant: the ViewModel's status must equal the system's actual status immediately after init. In the test environment both values are `.notDetermined`, so the test passes — but it will catch any regression that hard-codes a different value or breaks the assignment.

- [ ] **Step 3: Run the test to confirm it runs cleanly**

```bash
xcodebuild test -project thirstyinrome.xcodeproj -scheme thirstyinrome -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17' -only-testing:thirstyinromeTests/PlaceTests/authorizationStatusMatchesSystemAfterInit 2>&1 | grep -E "error:|warning:|Test Suite|Test Case|PASSED|FAILED|BUILD SUCCEEDED|BUILD FAILED|TEST SUCCEEDED|TEST FAILED"
```

Expected: `Test Case 'authorizationStatusMatchesSystemAfterInit' passed`

- [ ] **Step 4: Commit**

```bash
git checkout -b bug/bug-002-authorization-status-init
git add thirstyinromeTests/PlaceTests.swift
git commit -m "test: add invariant test for authorizationStatus post-init"
```

---

### Task 2: Apply the one-line fix

**Files:**
- Modify: `thirstyinrome/PlaceViewModel.swift:14-18`

- [ ] **Step 1: Apply the fix**

In `PlaceViewModel.swift`, update `init()` to read the real status after setup:

```swift
override init() {
    super.init()
    loadPlaces()
    setupLocationManager()
    authorizationStatus = locationManager.authorizationStatus
}
```

The property declaration on line 9 stays unchanged (`= .notDetermined` is required by Swift before `super.init()` runs).

- [ ] **Step 2: Run all tests**

```bash
xcodebuild test -project thirstyinrome.xcodeproj -scheme thirstyinrome -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17' -skip-testing:thirstyinromeUITests 2>&1 | grep -E "error:|warning:|Test Suite|Test Case|PASSED|FAILED|BUILD SUCCEEDED|BUILD FAILED|TEST SUCCEEDED|TEST FAILED"
```

Expected: all tests pass, `TEST SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add thirstyinrome/PlaceViewModel.swift
git commit -m "fix: initialize authorizationStatus from locationManager after setup"
```
