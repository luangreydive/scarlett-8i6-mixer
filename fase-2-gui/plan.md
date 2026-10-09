# Phase 2 — Native macOS GUI (10 days)

> Original planning notes from the upstream 6i6 project (translated to English).

Goal: a SwiftUI app that connects to the daemon and controls the Scarlett.

## Strategy: Option B (recommended)
Rewrite the GUI in SwiftUI while keeping the pure C logic:
- Routing/mixer logic (C, ~15k lines) compiles as-is on macOS
- Only replace:
  - GTK4 → SwiftUI/Cocoa
  - ALSA → daemon socket
  - inotify → FSEvents / IOKit notification

## Tasks

### 2.0 Socket client (days 1-2)
- [ ] Write `libscarlett-client.c/h` — C wrapper for the daemon protocol
- [ ] Swift → C bridge (modulemap or ObjC wrapper)
- [ ] Test the connection from a Swift playground

### 2.1 Basic mixer (days 3-5)
- [ ] Main window with faders (channel levels)
- [ ] Mute / Solo buttons
- [ ] Master volume slider
- [ ] Wire each control to the daemon SET command
- [ ] Meter polling (100 ms timer)

### 2.2 Routing grid (days 5-7)
- [ ] Routing matrix: sources → destinations (Matrix Mixer)
- [ ] Source selectors per output channel
- [ ] Show channel names from the hardware definitions

### 2.3 DSP (days 8-9)
- [ ] Effects panel if applicable
- [ ] Save/Load presets (store local state)

### 2.4 Levels (meters) (days 9-10)
- [ ] Real-time level bars
- [ ] Peak hold
- [ ] Glow effect (port from `glow.c`)

## Files to create
- `scarlett-app/` — SwiftUI Xcode project
- `libscarlett-client/` — C client for the socket
- `scarlett-app/Bridge/` — bridging headers

## Success criteria
- App launchable from Finder
- Shows levels in real time
- Impedance, gain, volume and routing can be changed
- Settings persist after closing

## Component specifications
See this phase's `SPECS.md`.
