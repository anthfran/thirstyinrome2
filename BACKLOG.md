# Backlog

## Features


### FEAT-007: Compass/heading map mode
A toggle button lets the user switch between north-up (default) and heading-up mode. In heading-up mode the map rotates to keep the device's compass direction at the top, and the user location dot gains a heading cone to show which way the device is pointing.

**AC:**
- A compass/heading toggle button appears on the map (e.g. compass rose SF Symbol)
- Tapping the button enters heading-up mode: map pitch follows `CLLocationManager` heading updates
- The user location blue dot shows a directional cone (bearing wedge) in heading-up mode
- Tapping the button again returns to north-up mode and removes the cone
- Heading updates do not interfere with user panning or the existing Rome/GPS re-center buttons
- Build succeeds and all existing tests pass

---

## Bugs


## Refactors

