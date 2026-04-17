---
id: REFACTOR-005
title: Remove dead test scaffolding
date: 2026-04-16
status: approved
---

## Problem

Three Xcode-generated test files exist in the repo with no meaningful assertions. They slow down test runs significantly — `testLaunchPerformance()` boots the simulator multiple times to collect timing samples, and `runsForEachTargetApplicationUIConfiguration = true` multiplies launches further. The noise obscures real test results and spins up the fan on every run.

## Files to Delete

| File | Why |
|------|-----|
| `thirstyinromeTests/thirstyinromeTests.swift` | Empty `example()` test — pure Xcode boilerplate, asserts nothing |
| `thirstyinromeUITests/thirstyinromeUITests.swift` | Launches app but asserts nothing; `testLaunchPerformance()` is the fan-spin culprit |
| `thirstyinromeUITests/thirstyinromeUITestsLaunchTests.swift` | Takes a screenshot with no assertions; runs per UI configuration |

## CLAUDE.md Change

Add `-skip-testing:thirstyinromeUITests` to the "run all tests" command so the UI simulator target never runs unless explicitly requested.

Before:
```
xcodebuild test -project thirstyinrome.xcodeproj -scheme thirstyinrome -destination '...'
```

After:
```
xcodebuild test -project thirstyinrome.xcodeproj -scheme thirstyinrome -destination '...' -skip-testing:thirstyinromeUITests
```

## Out of Scope

Removing the `thirstyinromeUITests` Xcode target from `project.pbxproj`. The target will have no source files but remains harmless. Editing `pbxproj` directly risks corrupting the project for zero practical gain.

## Acceptance Criteria

- The three files are deleted from disk
- `CLAUDE.md` test commands include `-skip-testing:thirstyinromeUITests`
- All tests in `thirstyinromeTests/PlaceTests.swift` continue to pass
