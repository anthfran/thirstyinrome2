# BUG-002: authorizationStatus initializes to .notDetermined regardless of actual status

## Problem

`PlaceViewModel.authorizationStatus` is declared with `= .notDetermined` at the property level. On second launch (where the user has already granted location permission), iOS fires `locationManagerDidChangeAuthorization` synchronously when `locationManager.delegate = self` is set inside `setupLocationManager()`. This does update the property — but there is a brief window between object creation and the delegate callback where `authorizationStatus` holds the wrong value. If that window is ever observed (e.g. by the GPS button in `ContentView`), the button briefly shows grey instead of blue.

## Fix

After `setupLocationManager()` returns in `init()`, read the real status directly from `locationManager.authorizationStatus` and assign it to the property. This overwrites the `.notDetermined` default with the actual value before any view can observe it.

```swift
override init() {
    super.init()
    loadPlaces()
    setupLocationManager()
    authorizationStatus = locationManager.authorizationStatus
}
```

## Scope

- **File changed:** `thirstyinrome/PlaceViewModel.swift`
- **Lines changed:** one line added after `setupLocationManager()` call in `init()`
- **No other files change**

## Acceptance Criteria

- `authorizationStatus` reflects the real `CLLocationManager` status immediately after `PlaceViewModel.init()` returns, with no intermediate `.notDetermined` observable on second launch
- Existing tests continue to pass
