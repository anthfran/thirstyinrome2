# REFACTOR-005: Remove Dead Test Scaffolding — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Delete three assertion-free Xcode boilerplate test files and update the CLAUDE.md test command to skip the UI test target.

**Architecture:** Pure deletion — no new code. Remove three files from disk (File System Synchronized Groups means no project.pbxproj edits needed for the unit test file). Update one command in CLAUDE.md. Verify existing unit tests still pass.

**Tech Stack:** Swift, Xcode 26, xcodebuild

---

### Task 1: Add REFACTOR-005 to BACKLOG.md and create branch

**Files:**
- Modify: `BACKLOG.md`

- [ ] **Step 1: Add REFACTOR-005 entry to BACKLOG.md**

In `BACKLOG.md`, append the following under the `## Refactors` section (after REFACTOR-004):

```markdown
### REFACTOR-005: Remove dead test scaffolding
Three Xcode-generated test files contain no assertions and slow down every test run. `testLaunchPerformance()` boots the simulator multiple times; `runsForEachTargetApplicationUIConfiguration = true` multiplies launches further. Fix: delete the three files and add `-skip-testing:thirstyinromeUITests` to the CLAUDE.md test command.
```

- [ ] **Step 2: Create the branch**

```bash
git checkout -b refactor/refactor-005-remove-dead-tests
```

Expected: `Switched to a new branch 'refactor/refactor-005-remove-dead-tests'`

- [ ] **Step 3: Commit the backlog entry**

```bash
git add BACKLOG.md
git commit -m "chore: add REFACTOR-005 to backlog"
```

---

### Task 2: Delete the dead test files

**Files:**
- Delete: `thirstyinromeTests/thirstyinromeTests.swift`
- Delete: `thirstyinromeUITests/thirstyinromeUITests.swift`
- Delete: `thirstyinromeUITests/thirstyinromeUITestsLaunchTests.swift`

> Note: `thirstyinromeTests/thirstyinromeTests.swift` lives in the unit test target which uses File System Synchronized Groups — deleting it from disk is sufficient, no project.pbxproj edit needed. The `thirstyinromeUITests` target is NOT a synchronized group target; deleting its source files leaves the target intact with no sources, which is harmless.

- [ ] **Step 1: Delete the three files**

```bash
rm /Users/anthony/github/thirstyinrome/thirstyinromeTests/thirstyinromeTests.swift
rm /Users/anthony/github/thirstyinrome/thirstyinromeUITests/thirstyinromeUITests.swift
rm /Users/anthony/github/thirstyinrome/thirstyinromeUITests/thirstyinromeUITestsLaunchTests.swift
```

- [ ] **Step 2: Verify the files are gone**

```bash
ls thirstyinromeTests/
ls thirstyinromeUITests/
```

Expected: `thirstyinromeTests/thirstyinromeTests.swift` absent. `thirstyinromeUITests/` directory present but empty (or containing only non-Swift assets).

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "refactor: delete assertion-free Xcode test boilerplate"
```

---

### Task 3: Update CLAUDE.md test command

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Add `-skip-testing:thirstyinromeUITests` to the "Run all tests" command**

In `CLAUDE.md`, replace the **Run all tests** block:

Before:
```
xcodebuild test -project thirstyinrome.xcodeproj -scheme thirstyinrome -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17' 2>&1 | grep -E "error:|warning:|Test Suite|Test Case|PASSED|FAILED|BUILD SUCCEEDED|BUILD FAILED|TEST SUCCEEDED|TEST FAILED"
```

After:
```
xcodebuild test -project thirstyinrome.xcodeproj -scheme thirstyinrome -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17' -skip-testing:thirstyinromeUITests 2>&1 | grep -E "error:|warning:|Test Suite|Test Case|PASSED|FAILED|BUILD SUCCEEDED|BUILD FAILED|TEST SUCCEEDED|TEST FAILED"
```

> The single-test command already uses `-only-testing:thirstyinromeTests/...` so it implicitly targets the unit test target — no change needed there.

- [ ] **Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "chore: skip UI test target in CLAUDE.md test command"
```

---

### Task 4: Verify and finish

- [ ] **Step 1: Run the updated test command**

```bash
xcodebuild test -project thirstyinrome.xcodeproj -scheme thirstyinrome -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17' -skip-testing:thirstyinromeUITests 2>&1 | grep -E "error:|warning:|Test Suite|Test Case|PASSED|FAILED|BUILD SUCCEEDED|BUILD FAILED|TEST SUCCEEDED|TEST FAILED"
```

Expected output contains:
```
Test Suite 'PlaceTests' started
Test Case 'testPlacesJSONLoads' passed
Test Case 'testNilTitleHandled' passed
Test Case 'testCoordinatesInRomeBounds' passed
Test Case 'testPlaceIdDecodesFromJSON' passed
Test Case 'testPlaceIdIsStableAcrossDecodes' passed
Test Suite 'ClusterTests' started
...
TEST SUCCEEDED
```

Expected: no simulator launch for UI tests, fan stays quiet.

- [ ] **Step 2: Update BACKLOG.md to mark REFACTOR-005 complete**

Replace the REFACTOR-005 entry added in Task 1 with:

```markdown
### ~~REFACTOR-005: Remove dead test scaffolding~~ ✓ Done 2026-04-16
**Branch:** `refactor/refactor-005-remove-dead-tests`
**AC met:**
- `thirstyinromeTests/thirstyinromeTests.swift` deleted
- `thirstyinromeUITests/thirstyinromeUITests.swift` deleted
- `thirstyinromeUITests/thirstyinromeUITestsLaunchTests.swift` deleted
- CLAUDE.md "run all tests" command includes `-skip-testing:thirstyinromeUITests`
- All unit tests in `PlaceTests.swift` pass
```

- [ ] **Step 3: Commit backlog update**

```bash
git add BACKLOG.md
git commit -m "chore: mark REFACTOR-005 complete in backlog"
```

- [ ] **Step 4: Invoke superpowers:finishing-a-development-branch**
