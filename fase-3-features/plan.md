# Phase 3 — 6i6-specific features (5 days)

> Original planning notes from the upstream 6i6 project (translated to English).
> For the 8i6 differences, see the README.

Goal: implement every hardware feature of the Scarlett 6i6.

## Tasks

### 3.0 Impedance, Pad, Gain (day 1)
- [ ] Input impedance: Line(0) / Hi-Z(1) — wIndex 0x01, wValue 0x0901+ch
- [ ] Pad: -10dB on/off — wIndex 0x01, wValue 0x0b01+ch
- [ ] Gain switch: Lo(0) / Hi(1) — wIndex 0x01, wValue 0x0801+ch
- [ ] UI: toggle button per input channel

### 3.1 Master Volume & Mute (day 1)
- [ ] Master volume — wIndex 0x0a, wValue 0x0200+bus
- [ ] Master mute — wIndex 0x0a, wValue 0x0100+bus

### 3.2 Clock & Sample Rate (day 2)
- [ ] Clock source: Internal / S/PDIF / ADAT — wIndex 0x28
- [ ] Sample rate: 44.1 / 48 / 88.2 / 96 kHz — wIndex 0x29
- [ ] Sync status polling — wIndex 0x3c MEM, wValue 0x0002

### 3.3 Routing Matrix (days 2-3)
- [ ] Matrix Mux — wIndex 0x32, wValue 0x0600+channel
- [ ] Output Mux — wIndex 0x33
- [ ] Capture Mux — wIndex 0x34
- [ ] Matrix Mixer Gains — wIndex 0x3c

### 3.4 Level Meters (days 3-4)
- [ ] Periodic read — wIndex 0x3c MEM, wValue 0x0000/1/3
- [ ] Map physical channels to meter slots
- [ ] Peak hold and decay

### 3.5 Save to hardware (day 4)
- [ ] Save command — wIndex 0x3c MEM, wValue 0x005a, data 0xa5
- [ ] Confirm it persists after unplugging USB

### 3.6 Polishing (day 5)
- [ ] Edge cases: device disconnected, USB errors
- [ ] Automatic reconnect to the daemon
- [ ] Tests with the physical 6i6

## Success criteria
Every function in the USB table (phase 1 `SPECS.md`) implemented
and verifiable from the GUI.
