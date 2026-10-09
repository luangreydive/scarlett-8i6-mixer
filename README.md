# Scarlett 8i6 Mixer (macOS)

Native macOS control panel for the **Focusrite Scarlett 8i6 (1st Gen)**.

This is a fork of [**scarlett-6i6-mixer**](https://github.com/Vumet3r/scarlett-6i6-mixer) by
[@Vumet3r](https://github.com/Vumet3r) (built for the 6i6 1st Gen), adapted to the **8i6** and with a
few new features. The SwiftUI app and the C daemon come from the original project.

> **Why it exists:** Scarlett MixControl no longer works reliably on recent macOS versions,
> and Focusrite Control 2 does not support 1st generation devices.

## Features

From the original project:
- Matrix mixer and routing, level meters, preamps, clock and sample rate.
- Presets (save, load, export) and **Save to hardware** (stores the configuration in the device's
  memory, so it survives unplugging it).

New in this fork:
- **Scarlett 8i6 support** (see the differences below).
- **Keyboard volume keys**: while the Scarlett is the macOS sound output, the volume up / down / mute
  keys change the device **Master**, with an on-screen HUD (macOS cannot do this with 1st Gen
  Scarletts). `Shift + Option` + key = fine steps.
- **Menu bar mode**: closing the window keeps the app in the menu bar (the volume keys keep working).
  From there: open the window, set the volume to maximum, **Launch at Login**, and quit.
- Starts with the computer audio routed **straight to the monitors** (DAW mode).
- Remembers the last Master / Mute and re-applies it on connect.

## Installation

### Download the app

Download the `.zip` from [Releases](https://github.com/luangreydive/scarlett-8i6-mixer/releases),
unzip it and move **Scarlett 8i6 Mixer.app** to **Applications**.

The app is not notarized by Apple. The first time, macOS will say it cannot verify it: go to
**System Settings › Privacy & Security**, scroll down to the "Scarlett 8i6 Mixer" notice and click
**Open Anyway**. (Terminal alternative: `xattr -cr "/Applications/Scarlett 8i6 Mixer.app"`.)

### Build from source

You need the **Xcode Command Line Tools** (`xcode-select --install`); full Xcode is not required.

```bash
git clone https://github.com/luangreydive/scarlett-8i6-mixer.git
cd scarlett-8i6-mixer
./setup_signing.sh   # optional, once (see below)
./build_8i6.sh       # builds "Scarlett 8i6 Mixer.app" into this folder
```

`setup_signing.sh` creates a local certificate (in your login keychain only) so the app is always
signed with the same identity. Without it, every rebuild changes the signature and macOS stops
applying the Accessibility permission (the volume keys stop working until you grant it again).

## Usage

- **Accessibility permission**: requested on first launch; it is needed to intercept the volume keys.
  It lives in System Settings › Privacy & Security › Accessibility.
- **Full volume on the monitors**: the app starts in **DAW / GarageBand** mode (computer audio
  straight to Monitor L/R). On the 8i6, **Mix 1** mode (through the internal mixer) leaves the
  monitors silent.
- **Brightness / external display apps** (MonitorControl, BetterDisplay, Lunar, etc.): if they also
  intercept the volume keys, they take them (especially after the Mac wakes from sleep).
  Configure them to use the keyboard for brightness only.

## Differences from the 6i6 version

Every change is marked with `8i6:` in the code.

| Change | Why |
|---|---|
| Product ID `0x8012` → `0x8002` | USB ID of the 8i6 |
| Output volume in 1/256 dB (signed 16-bit), like the Linux driver | With `dB+128` the 8i6 does not lower the volume |
| 3 mix pairs (A–F) instead of 8 | The 8i6 has 6 mixes |
| Line/Inst on inputs 1–2, Pad on 3–4, no Lo/Hi switch | 8i6 controls according to `mixer_scarlett.c` |
| On connect: monitors straight from the computer (PCM 1/2), Mix 1 not forced | Mix 1 leaves the monitors silent on the 8i6 |
| DAW channel at 0 dB by default (was −12/−14 dB) | The original attenuated the computer by 12 dB |
| `@State` replaced by `@LocalState` | Builds with the Command Line Tools only on the macOS 27 SDK |
| Volume keys, menu bar mode, Launch at Login | New features |
| 3 s timeout on the daemon socket; the menu does not redraw with the meters | Robustness |
| Socket `/tmp/scarlett-8i6.sock` | Avoids clashing with a 6i6 install |

## Known limitations

- Tested on a single 8i6 (1st Gen) with macOS 27 (Apple Silicon).
- This device **does not reliably report** its routing, mixes or volumes: the app shows the last
  values it wrote, not values read back from the hardware.
- If it cannot claim the device, the daemon restarts the macOS MIDI service (`MIDIServer`).

## Credits and license

- Original project: [scarlett-6i6-mixer](https://github.com/Vumet3r/scarlett-6i6-mixer) by
  [@Vumet3r](https://github.com/Vumet3r).
- Register map and gain scaling: the Linux ALSA driver (`sound/usb/mixer_scarlett.c`).
- Licensed under **GPL-2.0** (see [LICENSE](LICENSE)), same as the original.

Not affiliated with or endorsed by Focusrite.
