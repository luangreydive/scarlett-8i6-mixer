# GUI specifications — Port from alsa-scarlett-gui

> Original planning notes from the upstream 6i6 project (translated to English).

## alsa-scarlett-gui files and their equivalent

| C file (Linux) | Lines | Action on macOS |
|---|---|---|
| `alsa.c` | 1808 | Replace: daemon socket instead of ALSA |
| `alsa.h` | 461 | Reuse: struct alsa_card, alsa_elem |
| `scarlett2.h` | 54 | Reuse (ioctl defs) |
| `window-routing.c` | 2304 | Rewrite: SwiftUI RoutingView |
| `window-mixer.c` | 1538 | Rewrite: SwiftUI MixerView |
| `window-dsp.c` | 2164 | Rewrite: SwiftUI DSPView |
| `window-levels.c` | 448 | Rewrite: SwiftUI MetersView |
| `iface-mixer.c` | 1590 | Port logic (pure C, no GTK) |
| `stereo-link.c` | 2373 | Port logic (pure C) |
| `config-io.c` | 2100 | Port logic (pure C) |
| `gtkdial.c` | 1924 | Replace: SwiftUI Knob |
| `glow.c` | ~300 | Reimplement: glow effect in Metal/CoreImage |
| `hardware.c` | ~200 | Reuse: hardware definitions |
| 20+ small files | ~10k | Reuse: pure business logic |

## Client-daemon protocol

### Commands
```
GET <path>             → value
SET <path> <value>     → ok/error
GET_METERS             → [level1, level2, ...]
SAVE                   → ok
LIST                   → list of available controls
```

### Paths
```
/input/<n>/impedance
/input/<n>/pad
/input/<n>/gain
/output/<n>/volume
/output/<n>/mute
/master/volume
/master/mute
/clock/source
/clock/samplerate
/routing/matrix/<src>/<dst>
/meters
```

### Response format
```json
{"ok": true, "value": ...}
{"ok": false, "error": "message"}
```

## Proposed SwiftUI views
- `ContentView` — main container with tabs
- `MixerView` — per-channel faders, mute/solo
- `RoutingView` — routing matrix
- `DSPView` — effects panel
- `MetersView` — level bars
- `SettingsView` — clock source, sample rate

## CoreImage / Metal
- The `glow.c` glow effect can be reimplemented with a `CIFilter` or a Metal shader
- Alternative: an `NSView` with `CGShading` for minimum effort
