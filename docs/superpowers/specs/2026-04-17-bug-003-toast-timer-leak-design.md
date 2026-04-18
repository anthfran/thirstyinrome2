# BUG-003: GPS Wait Toast Timer Leak — Design Spec

## Problem

`ContentView.handleLocationButtonTap()` (lines 157–160) schedules a `DispatchQueue.main.asyncAfter` closure every time the user taps the GPS button while in the `.noFix` state. These closures cannot be cancelled. Rapid taps stack independent 2-second timers; each one fires and sets `showGPSWaitToast = false` independently. Harmless today, but will cause subtle race conditions if toast logic grows.

## Fix

Replace `DispatchQueue.main.asyncAfter` with a stored `Task<Void, Never>?` that is cancelled on each new tap.

### State change

Add one property to `ContentView`:

```swift
@State private var toastDismissTask: Task<Void, Never>?
```

### Handler change

Replace the `.noFix` case in `handleLocationButtonTap()`:

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

## Behaviour

- Each tap cancels the in-flight timer and starts a fresh 2-second countdown.
- Only one `Task` is ever live at a time.
- The toast disappears exactly 2 seconds after the *last* tap, not after each individual tap.

## Scope

- **File changed:** `thirstyinrome/ContentView.swift` only.
- No new types, protocols, or files.
- No test changes required (the bug is in UI tap handling, not testable logic).

## Acceptance Criteria

- No `DispatchQueue.main.asyncAfter` call remains in `handleLocationButtonTap`.
- `toastDismissTask` is a `@State Task<Void, Never>?` property on `ContentView`.
- Rapid taps in `.noFix` state result in a single dismiss firing 2 seconds after the last tap.
- All existing tests pass.
