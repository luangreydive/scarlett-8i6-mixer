# Project status: Scarlett macOS Port

> Original development log from the upstream 6i6 project (translated to English).
> For the 8i6 changes, see the README.

## Last update
2026-08-08 — Phases 2 and 3 complete: real SET clock/rate, .app packaging, validated on hardware

## Overall status
| Phase | Status | % |
|------|--------|---|
| 1 — USB daemon | **Complete** | 100% |
| 2 — Native GUI | **Complete** | 100% |
| 3 — 6i6 features | **Complete** | 100% |

## Log (recent summary)

- [x] Phase 1 complete: USB daemon with every GET/SET verified (see below)
- [x] Native SwiftUI GUI (`fase-2-gui/scarlett-app`, Swift package, 600+ lines)
- [x] Dark UI redesign (red/maroon, ScarlettUI styles, meter bars, faders)
- [x] Studied the reference repo `Nas3nmann/scarlett-mixcontrol-1stgen` (MixControl CE, 1st gen)
  - Ported pattern: JSON snapshots (model + panel + export/import ⌘S/⌘O), held peaks (~4 dB/s),
    state auto-reconnect, save-to-hardware (flash)
  - Not applicable: 1st gen byte tables, direct USB access via `IOUSBDeviceInterface` (1st gen)
- [x] Presets: Codable `ScarlettPreset`, stored in UserDefaults + `.6i6.json` file; loading pushes routing + 64 matrix gains + preamp + master to the hardware
- [x] Held-peak meters: `meterHold` decays 4 dB/s; white line in `MeterBar`
- [x] Auto-reconnect: after 25 polling failures (2.5 s) → disconnected + retry every 1 s with a visible `lastError`
- [x] TopBar with connection status, Presets button (sheet) and Save to hardware
- [x] Raw `SET save` in the client (`saveToHardwareAsync`)
- [x] **Robust daemon v0.2.0** (fase-1-daemon/src/main.c):
  - SIGPIPE ignored — clients dying mid-response no longer kill the daemon
  - Watchdog thread: retries `scarlett_usb_open` every 1 s if there is no device; after 5+ consecutive USB failures it closes and reopens the handle
  - `cmd_handler` with a `g_dev_lock` mutex + failure counter (`ERR ctl` / `ERR no device`)
- [x] **Daemon embedded in the app** (DaemonManager.swift): the app launches the daemon as a subprocess if the socket does not answer
  - Lookup: env `SCARLETT_DAEMON` → path relative to the executable (dev) → bundle Resources → `~/.scarlett/`
  - Automatic respawn if it dies (max 3, 2 s cooldown); distinct "binary not found" vs "keeps crashing" messages
  - Clean quit: `applicationWillTerminate` + closing the window quits the app (`applicationShouldTerminateAfterLastWindowClosed`) → `daemon.shutdown()`
- [x] Verified without hardware: spawn on app launch (pid 98654→99530), respawn after `kill -9`, daemon survives rude clients (SIGPIPE)
- [x] **SET clock + SET rate** (daemon `cmd_set_clock`/`cmd_set_rate`): `SET clock internal|spdif|adat` (wValue 0x0100 wIdx 0x2800), `SET rate 44100|48000|88200|96000` (0x2900 LE32). **Tested on real hardware**: 44100→48000→44100 ✓ + LIST updated
- [x] **ClockPanelView UI**: pickers for Rate (44.1/48/88.2/96 kHz) and Clock (Internal/S/PDIF/ADAT) with refresh
- [x] **Hold reset by double-click** in MeterBar (channel + master)
- [x] **`.app` packaging**: `fase-2-gui/package.sh` → `dist/Scarlett 6i6 Mixer.app` (Info.plist, daemon in Resources, ad-hoc codesign). DaemonManager already looks in the bundle Resources
- [x] **Hardware reconnected during the session**: the daemon watchdog reopened it by itself and the app reconnected by itself

## Phase 1 — Commands verified against a real Scarlett 6i6

### GET
- `clock` → S/PDIF ✓ · `rate` → 44100 Hz ✓ · `sync` → Locked ✓
- `meters` → 4 active channels ✓ · `volume` → dB ✓ · `mute` ✓
- `impedance:N` ✓ · `pad:N` ✓ · `gain:N` ✓ · `matrix:N` ✓ · `matrix:N.M` ✓
- `output:N` ✓ · `capture:N` ✓

### SET
- `volume dB` ✓ · `mute on|off` ✓ · `impedance:N line|hi-z` (LED) ✓ · `pad:N` (LED blinks) ✓
- `gain:N lo|hi` ✓ · `matrix:N src` ✓ · `matrix:N.M gain` ✓ · `output:N src` ✓ · `capture:N src` ✓
- `save` → OK saved ✓

- [x] **MIDIServer auto-recovery in the daemon** (`usb-io.mm`): if `IOUSBHostDevice` fails to open with an exclusive lock, it kills `MIDIServer` automatically and retries right away.
- [x] **Matrix node formula fix in the daemon** (`main.c`): `(in << 3) | (mix & 7)`, matching the Scarlett 6i6 1st Gen hardware.
- [x] **Matrix gain encoded as signed 16-bit**: Scarlett Gen 1 requires `(int16_t)(dB * 256)` (dB in the high byte, fraction in the low byte). Fixed the bug where it was sent in the low byte and the hardware always stayed at 0 dB without muting.
- [x] **Daemon state cache for write-only registers**: the Scarlett Gen 1 firmware returns 0 on `GET_CUR` for output/capture muxes and matrix gains (same behavior as the Linux ALSA driver). The daemon now keeps `g_output_mux_cache`, `g_capture_mux_cache` and `g_matrix_gain_cache`.
- [x] **Physical protection against feedback loops**: capture muxes locked to physical analog and S/PDIF inputs (12..17). The Mac/DAW output can never be fed back into the recording input.
- [x] **Real, working Mute, Solo and faders**: the `M`, `S` buttons and per-channel faders (including Guitar on Input 1 and Mac/Spotify on DAW 1/2) apply mute (-128 dB) and safe headroom (-12 dB by default) directly in the hardware DSP matrix.
- [x] **Quick monitoring selector in the TopBar**: `DAW / GarageBand` (PCM 1-2), `Direct Guitar` (zero latency), `Mix 1 (DSP)`.
- [x] **Integrated playback strips**: unified stereo channel **`DAW 1-2`** with independent dual L/R meters, linked fader, stereo balance knob, Mute, Solo and PFL to control the Mac's music/playback with a single control.
- [x] **Routing menu with friendly names**: `DAW 1/2`, `Input 1..4`, `Mix 1..3 L/R` instead of raw indexes.

## Pending / known issues

- **Fixed: the keyboard did not type into TextFields** — the app was launched as a bare binary (no Info.plist) and macOS treated it as `.accessory`: windows never became key → mouse OK, keyboard dead. Fix: `setActivationPolicy(.regular)` in `applicationDidFinishLaunching` + `NSApp.activate(ignoringOtherApps:)`.
- **The Presets panel uses `NativeTextField`** (NSTextField via NSViewRepresentable) + a popover cached in ContentView state (the 10 Hz polling repaints neither recreate the panel nor steal focus).
- **Fixed: MIDIServer was locking the USB device** — `usb-io.mm` now kills `MIDIServer` automatically and reopens without manual intervention.

## How to launch

- Daemon: `fase-1-daemon/build/scarlett-daemon` (socket `/tmp/scarlett-6i6.sock` upstream, `/tmp/scarlett-8i6.sock` in this fork)
- App: `open "/Applications/Scarlett 6i6 Mixer.app"` (upstream) / `"/Applications/Scarlett 8i6 Mixer.app"` (this fork)
- App log: `/tmp/scarlett-app-crash.log`
