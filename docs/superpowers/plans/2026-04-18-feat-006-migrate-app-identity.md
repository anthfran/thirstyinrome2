# FEAT-006: Migrate App Identity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Update the new codebase's bundle ID and app icon to match the existing App Store listing so it can be submitted as an update rather than a new app.

**Architecture:** Three file-level changes with no new Swift code: a string substitution in `project.pbxproj`, a PNG copy + `Contents.json` update in the asset catalog, and deletion of the source PNG from the repo root. Each change is independently verifiable with `xcodebuild build`.

**Tech Stack:** Xcode 26, iOS 17+, SwiftUI. No new dependencies.

---

### Task 1: Create feature branch

**Files:**
- No file changes — git operation only

- [ ] **Step 1: Create and switch to feature branch**

```bash
git checkout -b feat/feat-006-migrate-app-identity
```

Expected output: `Switched to a new branch 'feat/feat-006-migrate-app-identity'`

---

### Task 2: Update Bundle ID in project.pbxproj

**Files:**
- Modify: `thirstyinrome.xcodeproj/project.pbxproj` (lines 432, 477, 504, 530, 555, 580)

The pbxproj has six `PRODUCT_BUNDLE_IDENTIFIER` lines across three targets. All six need updating. The app target lines appear twice each (Debug and Release build configurations).

- [ ] **Step 1: Replace app target bundle ID (2 occurrences)**

Open `thirstyinrome.xcodeproj/project.pbxproj` and replace both occurrences of:
```
PRODUCT_BUNDLE_IDENTIFIER = com.anthonyf.thirstyinrome;
```
with:
```
PRODUCT_BUNDLE_IDENTIFIER = com.anthonyf.ThirstyInRome;
```

Verify with:
```bash
grep "PRODUCT_BUNDLE_IDENTIFIER" thirstyinrome.xcodeproj/project.pbxproj
```
Expected: lines 432 and 477 now show `com.anthonyf.ThirstyInRome`

- [ ] **Step 2: Replace unit test target bundle ID (2 occurrences)**

Replace both occurrences of:
```
PRODUCT_BUNDLE_IDENTIFIER = com.anthonyf.thirstyinromeTests;
```
with:
```
PRODUCT_BUNDLE_IDENTIFIER = com.anthonyf.ThirstyInRomeTests;
```

- [ ] **Step 3: Replace UI test target bundle ID (2 occurrences)**

Replace both occurrences of:
```
PRODUCT_BUNDLE_IDENTIFIER = com.anthonyf.thirstyinromeUITests;
```
with:
```
PRODUCT_BUNDLE_IDENTIFIER = com.anthonyf.ThirstyInRomeUITests;
```

- [ ] **Step 4: Verify all six lines updated**

```bash
grep "PRODUCT_BUNDLE_IDENTIFIER" thirstyinrome.xcodeproj/project.pbxproj
```

Expected output (6 lines total):
```
PRODUCT_BUNDLE_IDENTIFIER = com.anthonyf.ThirstyInRome;
PRODUCT_BUNDLE_IDENTIFIER = com.anthonyf.ThirstyInRome;
PRODUCT_BUNDLE_IDENTIFIER = com.anthonyf.ThirstyInRomeTests;
PRODUCT_BUNDLE_IDENTIFIER = com.anthonyf.ThirstyInRomeTests;
PRODUCT_BUNDLE_IDENTIFIER = com.anthonyf.ThirstyInRomeUITests;
PRODUCT_BUNDLE_IDENTIFIER = com.anthonyf.ThirstyInRomeUITests;
```

- [ ] **Step 5: Verify build succeeds**

```bash
xcodebuild build -project thirstyinrome.xcodeproj -scheme thirstyinrome -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17' 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED"
```

Expected: `BUILD SUCCEEDED` with no errors.

- [ ] **Step 6: Commit**

```bash
git add thirstyinrome.xcodeproj/project.pbxproj
git commit -m "feat: update bundle ID to com.anthonyf.ThirstyInRome to match App Store listing"
```

---

### Task 3: Add app icon to asset catalog

**Files:**
- Add: `thirstyinrome/Assets.xcassets/AppIcon.appiconset/ThirstyInRome_1024.png`
- Modify: `thirstyinrome/Assets.xcassets/AppIcon.appiconset/Contents.json`
- Delete: `ThirstyInRome_1024.png` (repo root)

- [ ] **Step 1: Copy the icon into the asset catalog**

```bash
cp ThirstyInRome_1024.png thirstyinrome/Assets.xcassets/AppIcon.appiconset/ThirstyInRome_1024.png
```

- [ ] **Step 2: Update Contents.json to reference the icon**

Replace the entire contents of `thirstyinrome/Assets.xcassets/AppIcon.appiconset/Contents.json` with:

```json
{
  "images" : [
    {
      "filename" : "ThirstyInRome_1024.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "tinted"
        }
      ],
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    },
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "16x16"
    },
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "32x32"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "32x32"
    },
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "128x128"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "128x128"
    },
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "256x256"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "256x256"
    },
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

- [ ] **Step 3: Delete the source PNG from the repo root**

```bash
rm ThirstyInRome_1024.png
```

- [ ] **Step 4: Verify build succeeds**

```bash
xcodebuild build -project thirstyinrome.xcodeproj -scheme thirstyinrome -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17' 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED"
```

Expected: `BUILD SUCCEEDED` with no errors.

- [ ] **Step 5: Commit**

```bash
git add thirstyinrome/Assets.xcassets/AppIcon.appiconset/ThirstyInRome_1024.png
git add thirstyinrome/Assets.xcassets/AppIcon.appiconset/Contents.json
git rm ThirstyInRome_1024.png
git commit -m "feat: add 1024x1024 app icon to asset catalog"
```

---

### Task 4: Run tests and update backlog

**Files:**
- Modify: `BACKLOG.md`

- [ ] **Step 1: Run the full test suite**

```bash
xcodebuild test -project thirstyinrome.xcodeproj -scheme thirstyinrome -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17' -skip-testing:thirstyinromeUITests 2>&1 | grep -E "error:|warning:|Test Suite|Test Case|PASSED|FAILED|BUILD SUCCEEDED|BUILD FAILED|TEST SUCCEEDED|TEST FAILED"
```

Expected: `TEST SUCCEEDED` — all existing tests pass.

- [ ] **Step 2: Mark FEAT-006 complete in BACKLOG.md**

In `BACKLOG.md`, find the `### FEAT-006` section and:
- Strike through the title: `~~FEAT-006: Migrate app identity from legacy repo~~`
- Add below the title: `✓ Done 2026-04-18 | Branch: feat/feat-006-migrate-app-identity | AC met`
- Move the entire entry to the `## Completed` section at the bottom of the file

- [ ] **Step 3: Commit backlog update**

```bash
git add BACKLOG.md
git commit -m "chore: mark FEAT-006 complete in backlog"
```
