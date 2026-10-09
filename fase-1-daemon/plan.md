# Phase 1 — USB daemon (5 days)

> Original planning notes from the upstream 6i6 project (translated to English).

Goal: a macOS CLI that talks to the Scarlett 6i6 over USB.

## Tasks

### 1.0 Detect and open the USB device (day 1)
- [ ] Use `ioreg -p IOUSB -w0 | grep -i scarlett`
- [ ] Write a small C program that opens the device with IOKit
- [ ] Check USB ID 0x1235:0x8012
- [ ] Read the vendor-specific interface descriptor (class 255)

### 1.1 Basic USB communication (days 2-3)
- [ ] Implement `usb_ctl_msg` with IOKit (`USBSendControlRequest`)
- [ ] Try a simple command: read the Sample Clock Source
- [ ] Try a write command: change the impedance of Input 1
- [ ] Check the responses against the hardware

Reference: the initialization lines and the `snd_usb_ctl_msg` functions in
`mixer_scarlett.c`. IOKit uses `USBDeviceReadPipe` / `USBSendControlRequest`.

### 1.2 Port of mixer_scarlett.c (days 3-4)
- [ ] Copy the hardware structures: `s6i6_info`, `s8i6_info`, etc. (~260 lines)
- [ ] Copy the wIndex/wValue/channel mapping
- [ ] Copy the sample rate initialization
- [ ] Ignore the `forte_*` sections (Focusrite Forte, ~400 lines)
- [ ] Replace the ALSA callbacks with a function that sends data to the socket

### 1.3 Socket daemon (day 5)
- [ ] Unix socket at `/tmp/scarlett-6i6.sock`
- [ ] Protocol: `GET <port>` / `SET <port> <value>` / `GET_METERS` / `SAVE`
- [ ] Format: JSON or simple binary
- [ ] Handle multiple connections (thread pool or dispatch)

### 1.4 USB notifications (day 5)
- [ ] Implement the notification URB with IOKit (interrupt pipe)
- [ ] Send events to connected clients over the socket

## Files to create
- `scarlett-daemon.c` — entry point, main loop
- `usb-io.c` + `usb-io.h` — IOKit wrappers
- `scarlett-protocol.c` + `scarlett-protocol.h` — Scarlett-specific USB commands
- `socket-server.c` + `socket-server.h` — Unix socket server
- `Makefile`

## Success criteria
```bash
scarlett-daemon &
scarlett-client get impedance:1
# → Line
scarlett-client set impedance:1 hi-z
scarlett-client get impedance:1
# → Hi-Z
```
