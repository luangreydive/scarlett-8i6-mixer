# Scarlett macOS Port — Overview

> Original planning notes from the upstream 6i6 project (translated to English).

Port the Focusrite Scarlett 6i6 controller from Linux to macOS,
removing the dependency on ALSA and GTK4.

## Current architecture (Linux)
```
kernel driver (mixer_scarlett.c) ←→ USB ←→ Scarlett 6i6
       ↓ (exposes ALSA controls)
alsa-scarlett-gui (GTK4, 35k lines)
```

## Target architecture (macOS)
```
scarlett-daemon (C/IOKit) ←→ USB ←→ Scarlett 6i6
       ↓ (Unix socket)
scarlett-app (SwiftUI)
```

Or a monolithic app that talks USB directly.

## Phases
1. **USB daemon** — IOKit access, USB communication, socket protocol
2. **Native GUI** — SwiftUI replacing GTK4; pure C logic is reused
3. **6i6 features** — Impedance, pad, gain, routing, meters

## Estimate
20 working days (~1 month).

## Existing code
- `fcp.c` — Focusrite Control Protocol driver (Linux kernel, 1129 lines)
- `mixer_scarlett.c` — 1st gen driver (1456 lines)
- `alsa-scarlett-gui/` — full GUI in GTK4 + C (~35k lines)
- `scarlett-gen2/` — kernel driver for 2nd gen+

See each phase folder for details.
