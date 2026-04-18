# FEAT-006: Migrate App Identity from Legacy Repo

**Date:** 2026-04-18
**Status:** Approved

## Goal

Transfer the App Store app identity from the legacy repo (`thirstyinrome-legacy/ThirstyInRome`) into this repo so the new codebase can replace the existing App Store listing without creating a new listing.

## Scope

| Item | Action |
|---|---|
| Bundle ID | `com.anthonyf.thirstyinrome` → `com.anthonyf.ThirstyInRome` |
| App icon | Copy `ThirstyInRome_1024.png` into the asset catalog |
| Entitlements | Nothing to migrate (neither repo has any) |
| `MKDirectionsApplicationSupportedModes` | Deferred — tracked as a separate backlog item |

## Changes

### 1. Bundle ID (`project.pbxproj`)

Replace three bundle ID values in `thirstyinrome.xcodeproj/project.pbxproj` via string substitution:

| Target | Old | New |
|---|---|---|
| App | `com.anthonyf.thirstyinrome` | `com.anthonyf.ThirstyInRome` |
| Unit tests | `com.anthonyf.thirstyinromeTests` | `com.anthonyf.ThirstyInRomeTests` |
| UI tests | `com.anthonyf.thirstyinromeUITests` | `com.anthonyf.ThirstyInRomeUITests` |

These are value-only substitutions on known lines — no structural pbxproj change.

### 2. App Icon (`Assets.xcassets/AppIcon.appiconset/`)

- Copy `ThirstyInRome_1024.png` from the repo root into `thirstyinrome/Assets.xcassets/AppIcon.appiconset/`
- Update `Contents.json` to reference it in the `universal` / `ios` / `1024x1024` slot
- Dark and tinted appearance slots remain empty (Xcode falls back to universal)
- Delete `ThirstyInRome_1024.png` from the repo root after it is placed in the asset catalog

### 3. Verification

Run `xcodebuild build` and confirm `BUILD SUCCEEDED`. No test changes are required — tests do not reference the bundle ID.

## Out of Scope

- Walking directions capability (`MKDirectionsApplicationSupportedModes`) — deferred to future backlog item
- App Store Connect submission setup — separate from this identity migration
- Dark/tinted icon variants — not designed yet
