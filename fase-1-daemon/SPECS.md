# USB specifications — Scarlett 6i6

> Original notes from the upstream 6i6 project (translated to English).
> The 8i6 uses USB ID `0x1235:0x8002` and the same control messages; see the README for its differences.

## Identification
- USB ID: `0x1235:0x8012`
- 2 USB interfaces:
  - Interface 0: Audio class-compliant (handled by macOS automatically)
  - Interface 1: Vendor-specific (class 255) — control endpoint

## Control messages (URB)
From the Linux driver `mixer_scarlett.c`:

### bRequest values
- `0x01` = `UAC2_CS_CUR` (read/write a control)
- `0x03` = `UAC2_CS_MEM` (meters/sync, different bmRequestType)

### General format
```c
snd_usb_ctl_msg(dev, pipe, bRequest, bmRequestType, wValue, wIndex, &data, size);
```

### bmRequestType
- Direction: `USB_DIR_OUT` (0x00) / `USB_DIR_IN` (0x80)
- Type: `USB_TYPE_CLASS` (0x20)
- Recipient: `USB_RECIP_INTERFACE` (0x01)
- Combined: `USB_RECIP_INTERFACE | USB_TYPE_CLASS | USB_DIR_OUT` = `0x21`
            `USB_RECIP_INTERFACE | USB_TYPE_CLASS | USB_DIR_IN`  = `0xA1`

For MEM: `USB_DIR_IN | USB_TYPE_VENDOR | USB_RECIP_OTHER` = `0xC1`

## Control table (6i6)

| Function | wIndex | wValue | Data | bRequest |
|---------|--------|--------|------|----------|
| Impedance (Line/Hi-Z) | 0x01 | 0x0901+ch | 2B | 0x01 |
| Pad (-10dB) | 0x01 | 0x0b01+ch | 2B | 0x01 |
| Gain switch (Lo/Hi) | 0x01 | 0x0801+ch | 2B | 0x01 |
| Master Volume | 0x0a | 0x0200+bus | 2B | 0x01 |
| Master Mute | 0x0a | 0x0100+bus | 2B | 0x01 |
| Clock Source | 0x28 | 0x0100 | 1B | 0x01 |
| Sample Rate | 0x29 | 0x0100 | 4B | 0x01 |
| Matrix Mux (routing) | 0x32 | 0x0600+ch | 2B | 0x01 |
| Output Mux | 0x33 | bus | 2B | 0x01 |
| Capture Mux | 0x34 | 0-18 | 2B | 0x01 |
| Matrix Mixer Gains | 0x3c | mixer-node | 2B | 0x01 |
| Level Meters | 0x3c (MEM) | 0x0000/1/3 | 2B*N | 0x03 |
| Sync Status | 0x3c (MEM) | 0x0002 | 1B | 0x03 |
| Save to hardware | 0x3c (MEM) | 0x005a | 0xa5 | 0x03 |

### Example: change the impedance of Input 1
```c
// wValue = (0x09 << 8) | channel
// wIndex = interface | (control_group << 8)
snd_usb_ctl_msg(dev, usb_sndctrlpipe(dev, 0),
    UAC2_CS_CUR,
    USB_RECIP_INTERFACE | USB_TYPE_CLASS | USB_DIR_OUT,
    0x0901,       // wValue: control 0x09, channel 1
    interface | (0x01 << 8),  // wIndex: interface, control group 0x01
    &value, 2);   // data: Line(0) / Hi-Z(1)
```

## FCP protocol (Focusrite Control Protocol, 2nd gen+)
`fcp.c` implements the protocol for Scarlett 2nd gen+ / Clarett / Vocaster.
It uses opcodes instead of direct URBs:

- `FCP_USB_REQ_STEP0` = 0 (init step 0)
- `FCP_USB_REQ_CMD_TX` = 2 (send command)
- `FCP_USB_REQ_CMD_RX` = 3 (receive response)

FCP packet structure:
```c
struct fcp_usb_packet {
    __le32 opcode;
    __le16 size;
    __le16 seq;
    __le32 error;
    __le32 pad;
    u8 data[];
};
```

It does not apply to the 6i6 (1st gen), which uses direct URBs with wIndex/wValue.
Documented here in case the daemon is extended to 2nd gen+.

## IOKit API (macOS)
```c
// Open the device
IOServiceGetMatchingServices(kIOMasterPortDefault,
    IOServiceMatching("IOUSBHostDevice"), &iterator);

// Send a control request
IOReturn err = USBDeviceSendControlRequest(device,
    &controlRequest, timeout_ms);

// Read the interrupt pipe (notifications)
IOReturn err = USBDeviceReadPipe(device, endpointRef,
    data, &length, timeout_ms);
```

Reference: `IOUSBHostFamily` / `IOKitLib`.
