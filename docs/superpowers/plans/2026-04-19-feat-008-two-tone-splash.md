# FEAT-008: Two-Tone Splash Screen Background Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the white launch screen background with a vertical 50/50 split — left half RGB(112,12,20) dark red, right half RGB(243,138,21) amber — while keeping the centered LaunchIcon.

**Architecture:** Single storyboard XML edit. Two `UIView` subviews (one per color half) are added before the existing `imageView` so the icon renders on top. Auto Layout pins each half to the superview edges; the split is enforced by a `multiplier="0.5"` width constraint on the left view and a leading-to-trailing constraint chaining the right view to it. Colors use `customColorSpace="sRGB"` with explicit normalized floats — no system color references, so they are identical in light and dark mode.

**Tech Stack:** Xcode 26, iOS 17+, Interface Builder storyboard XML (no Swift changes)

---

### Task 1: Create feature branch

**Files:**
- No file changes

- [ ] **Step 1: Create and check out branch**

```bash
git checkout -b feat/feat-008-two-tone-splash
```

Expected: `Switched to a new branch 'feat/feat-008-two-tone-splash'`

---

### Task 2: Verify baseline — existing tests pass before any changes

**Files:**
- No file changes

- [ ] **Step 1: Run existing test suite**

```bash
xcodebuild test \
  -project thirstyinrome.xcodeproj \
  -scheme thirstyinrome \
  -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17' \
  -skip-testing:thirstyinromeUITests \
  2>&1 | grep -E "error:|warning:|Test Suite|Test Case|PASSED|FAILED|BUILD SUCCEEDED|BUILD FAILED|TEST SUCCEEDED|TEST FAILED"
```

Expected: `TEST SUCCEEDED` and no `FAILED` lines.

---

### Task 3: Replace LaunchScreen.storyboard with two-tone split

**Files:**
- Modify: `thirstyinrome/LaunchScreen.storyboard`

This is a full file replacement. The changes are:
1. Root view `backgroundColor` changed from the system white color to transparent (clear).
2. Two new `<view>` subviews added before the `<imageView>` (so the icon renders on top in z-order).
3. Eight new Auto Layout constraints — four per color half.

RGB float values:
- Dark red RGB(112, 12, 20) → red=0.43921568627450981 green=0.047058823529411764 blue=0.07843137254901961
- Amber RGB(243, 138, 21) → red=0.95294117647058824 green=0.54117647058823529 blue=0.08235294117647059

- [ ] **Step 1: Replace file content**

Write the following as the complete contents of `thirstyinrome/LaunchScreen.storyboard`:

```xml
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<document type="com.apple.InterfaceBuilder3.CocoaTouch.Storyboard.XIB" version="3.0" toolsVersion="13122.16" targetRuntime="iOS.CocoaTouch" propertyAccessControl="none" useAutolayout="YES" launchScreen="YES" useTraitCollections="YES" useSafeAreas="YES" colorMatched="YES" initialViewController="01J-lp-oVM">
    <dependencies>
        <plugIn identifier="com.apple.InterfaceBuilder.IBCocoaTouchPlugin" version="13104.12"/>
        <capability name="Safe area layout guides" minToolsVersion="9.0"/>
        <capability name="documents saved in the Xcode 8 format" minToolsVersion="8.0"/>
    </dependencies>
    <scenes>
        <scene sceneID="EHf-IW-A2E">
            <objects>
                <viewController id="01J-lp-oVM" sceneMemberID="viewController">
                    <view key="view" contentMode="scaleToFill" id="Ze5-6b-2t3">
                        <rect key="frame" x="0.0" y="0.0" width="393" height="852"/>
                        <autoresizingMask key="autoresizingMask" widthSizable="YES" heightSizable="YES"/>
                        <subviews>
                            <view contentMode="scaleToFill" translatesAutoresizingMaskIntoConstraints="NO" id="Lft-1h-ALf">
                                <rect key="frame" x="0.0" y="0.0" width="196.5" height="852"/>
                                <color key="backgroundColor" red="0.43921568627450981" green="0.047058823529411764" blue="0.07843137254901961" alpha="1" colorSpace="custom" customColorSpace="sRGB"/>
                            </view>
                            <view contentMode="scaleToFill" translatesAutoresizingMaskIntoConstraints="NO" id="Rgt-2h-BRg">
                                <rect key="frame" x="196.5" y="0.0" width="196.5" height="852"/>
                                <color key="backgroundColor" red="0.95294117647058824" green="0.54117647058823529" blue="0.08235294117647059" alpha="1" colorSpace="custom" customColorSpace="sRGB"/>
                            </view>
                            <imageView clipsSubviews="YES" userInteractionEnabled="NO" contentMode="scaleAspectFit" horizontalHuggingPriority="251" verticalHuggingPriority="251" translatesAutoresizingMaskIntoConstraints="NO" id="UpW-cR-hLn">
                                <rect key="frame" x="96.5" y="326.0" width="200" height="200"/>
                                <imageReference key="image" image="LaunchIcon"/>
                            </imageView>
                        </subviews>
                        <color key="backgroundColor" red="0" green="0" blue="0" alpha="0" colorSpace="custom" customColorSpace="sRGB"/>
                        <constraints>
                            <constraint firstItem="Lft-1h-ALf" firstAttribute="leading" secondItem="Ze5-6b-2t3" secondAttribute="leading" id="LC1-3t-CLe"/>
                            <constraint firstItem="Lft-1h-ALf" firstAttribute="top" secondItem="Ze5-6b-2t3" secondAttribute="top" id="LC2-4p-CTp"/>
                            <constraint firstItem="Lft-1h-ALf" firstAttribute="bottom" secondItem="Ze5-6b-2t3" secondAttribute="bottom" id="LC3-5b-CBt"/>
                            <constraint firstItem="Lft-1h-ALf" firstAttribute="width" secondItem="Ze5-6b-2t3" secondAttribute="width" multiplier="0.5" id="LC4-6w-CWd"/>
                            <constraint firstItem="Rgt-2h-BRg" firstAttribute="leading" secondItem="Lft-1h-ALf" secondAttribute="trailing" id="RC1-7l-RLd"/>
                            <constraint firstItem="Rgt-2h-BRg" firstAttribute="top" secondItem="Ze5-6b-2t3" secondAttribute="top" id="RC2-8t-RTp"/>
                            <constraint firstItem="Rgt-2h-BRg" firstAttribute="bottom" secondItem="Ze5-6b-2t3" secondAttribute="bottom" id="RC3-9b-RBt"/>
                            <constraint firstItem="Rgt-2h-BRg" firstAttribute="trailing" secondItem="Ze5-6b-2t3" secondAttribute="trailing" id="RC4-0r-RTr"/>
                            <constraint firstItem="UpW-cR-hLn" firstAttribute="centerX" secondItem="Ze5-6b-2t3" secondAttribute="centerX" id="moa-c2-u7t"/>
                            <constraint firstItem="UpW-cR-hLn" firstAttribute="centerY" secondItem="Ze5-6b-2t3" secondAttribute="centerY" id="2pK-dR-hLn"/>
                            <constraint firstItem="UpW-cR-hLn" firstAttribute="width" constant="200" id="Xkm-2J-5dR"/>
                            <constraint firstItem="UpW-cR-hLn" firstAttribute="height" constant="200" id="Xkm-2J-6dR"/>
                        </constraints>
                        <viewLayoutGuide key="safeArea" id="6Tk-OE-BBY"/>
                    </view>
                </viewController>
                <placeholder placeholderIdentifier="IBFirstResponder" id="iYj-Kq-Ea1" userLabel="First Responder" sceneMemberID="firstResponder"/>
            </objects>
            <point key="canvasLocation" x="53" y="375"/>
        </scene>
    </scenes>
    <resources>
        <image name="LaunchIcon" width="1024" height="1024"/>
    </resources>
</document>
```

- [ ] **Step 2: Verify build succeeds**

```bash
xcodebuild build \
  -project thirstyinrome.xcodeproj \
  -scheme thirstyinrome \
  -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17' \
  2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED"
```

Expected: `BUILD SUCCEEDED` with no `error:` lines.

- [ ] **Step 3: Run full test suite**

```bash
xcodebuild test \
  -project thirstyinrome.xcodeproj \
  -scheme thirstyinrome \
  -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17' \
  -skip-testing:thirstyinromeUITests \
  2>&1 | grep -E "error:|warning:|Test Suite|Test Case|PASSED|FAILED|BUILD SUCCEEDED|BUILD FAILED|TEST SUCCEEDED|TEST FAILED"
```

Expected: `TEST SUCCEEDED` and no `FAILED` lines.

- [ ] **Step 4: Commit**

```bash
git add thirstyinrome/LaunchScreen.storyboard
git commit -m "feat: two-tone splash screen — dark red left, amber right (FEAT-008)"
```

---

### Task 4: Open PR

**Files:**
- No file changes

- [ ] **Step 1: Push branch**

```bash
git push -u origin feat/feat-008-two-tone-splash
```

- [ ] **Step 2: Create PR**

```bash
gh pr create \
  --title "feat: two-tone splash screen background (FEAT-008)" \
  --body "$(cat <<'EOF'
## Summary
- Replaces plain white launch screen with vertical 50/50 split: left dark red RGB(112,12,20), right amber RGB(243,138,21)
- Colors use explicit sRGB floats — non-adaptive (identical in light and dark mode)
- Centered LaunchIcon unchanged; z-order keeps it above both color halves

## Test plan
- [ ] Build succeeds
- [ ] All existing unit tests pass
- [ ] Launch screen visually shows correct two-tone split on simulator

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```
