import AppKit
import CoreAudio
import ApplicationServices

// 8i6: Mac keyboard volume / mute keys -> Scarlett Master.
//
// macOS can't use those keys with a 1st Gen Scarlett (it exposes no "master"
// volume control). Here the keys are intercepted (event tap, requires the
// Accessibility permission) only while the Scarlett is the macOS output device,
// and the device Master is changed the same way the app's fader does it.

private let kKeySoundUp: Int = 0     // NX_KEYTYPE_SOUND_UP
private let kKeySoundDown: Int = 1   // NX_KEYTYPE_SOUND_DOWN
private let kKeyMute: Int = 7        // NX_KEYTYPE_MUTE

/// Number of volume steps (same as macOS).
let kVolumeSteps = 16.0

/// The tap lives outside the actor so the callback can re-enable it.
private var gVolumeTap: CFMachPort?

/// Is the Scarlett the macOS output device? Cached and refreshed when the output
/// changes (and every 2 s) so the key callback never queries CoreAudio per key:
/// if the callback is slow, macOS disables the tap.
private var gScarlettIsDefault = false

/// Log to /tmp/scarlett-app-crash.log (the app's stderr).
func vkLog(_ msg: String) {
    let f = DateFormatter()
    f.dateFormat = "HH:mm:ss"
    fputs("\(f.string(from: Date())) keys: \(msg)\n", stderr)
}

// MARK: - Default output

/// Is the current macOS sound output the Scarlett?
func scarlettIsDefaultOutput() -> Bool {
    var addr = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDefaultOutputDevice,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain)
    var dev = AudioDeviceID(0)
    var size = UInt32(MemoryLayout<AudioDeviceID>.size)
    guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &size, &dev) == noErr,
          dev != 0 else { return false }

    var nameAddr = AudioObjectPropertyAddress(
        mSelector: kAudioObjectPropertyName,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain)
    var name: Unmanaged<CFString>?
    size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
    let status = withUnsafeMutablePointer(to: &name) { ptr in
        AudioObjectGetPropertyData(dev, &nameAddr, 0, nil, &size, ptr)
    }
    guard status == noErr, let cf = name?.takeRetainedValue() else { return false }
    return (cf as String).localizedCaseInsensitiveContains("Scarlett")
}

// MARK: - Event tap callback (C)

private func volumeTapCallback(proxy: CGEventTapProxy, type: CGEventType,
                               event: CGEvent, refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        vkLog(type == .tapDisabledByTimeout ? "macOS disabled the tap (timeout); re-enabling"
                                            : "macOS disabled the tap (secure input); re-enabling")
        if let tap = gVolumeTap { CGEvent.tapEnable(tap: tap, enable: true) }
        return Unmanaged.passUnretained(event)
    }
    // 14 = NSEventTypeSystemDefined; subtype 8 = special keys (volume, brightness, media)
    guard type.rawValue == 14,
          let ns = NSEvent(cgEvent: event),
          ns.subtype.rawValue == 8 else { return Unmanaged.passUnretained(event) }

    let data1 = ns.data1
    let keyCode = (data1 & 0xFFFF0000) >> 16
    let keyFlags = data1 & 0x0000FFFF
    let keyDown = ((keyFlags & 0xFF00) >> 8) == 0x0A

    guard keyCode == kKeySoundUp || keyCode == kKeySoundDown || keyCode == kKeyMute else {
        return Unmanaged.passUnretained(event)
    }
    guard gScarlettIsDefault else {
        if keyDown { vkLog("key \(keyCode) ignored: the macOS output is not the Scarlett") }
        return Unmanaged.passUnretained(event)   // other output: let macOS handle it
    }
    if keyDown {
        let flags = event.flags
        Task { @MainActor in VolumeKeys.shared.handle(keyCode: keyCode, flags: flags) }
    }
    return nil   // swallow the key (down and up)
}

// MARK: - Controller

@MainActor
final class VolumeKeys: ObservableObject {
    static let shared = VolumeKeys()

    /// true when the Accessibility permission is granted and the keys are active.
    @Published private(set) var active = false

    private let hud = VolumeHUD()
    private var permTimer: Timer?
    private var healthTimer: Timer?
    private var napActivity: NSObjectProtocol?
    private var lastStep: Double?
    private var lastDB: Float?

    /// Same as macOS: 16 steps. Step 16 = 0 dB; logarithmic curve
    /// (8 = -12 dB, 4 = -24 dB, 2 = -36 dB, 1 = -48 dB, 0 = silence).
    nonisolated static func stepToDB(_ step: Double) -> Int {
        if step <= 0.001 { return -128 }
        return max(-127, Int((40 * log10(step / kVolumeSteps)).rounded()))
    }

    nonisolated static func dbToStep(_ db: Double) -> Double {
        if db <= -127.5 { return 0 }
        let step = kVolumeSteps * pow(10, db / 40)
        return min(kVolumeSteps, max(0, (step * 4).rounded() / 4))
    }

    func start() {
        // Keep macOS from napping the app (App Nap) when there is no window:
        // a napping app answers the callback late and macOS disables the tap.
        if napActivity == nil {
            napActivity = ProcessInfo.processInfo.beginActivity(
                options: [.userInitiatedAllowingIdleSystemSleep, .latencyCritical],
                reason: "Scarlett volume keys")
        }
        watchOutputChanges()
        startHealthCheck()

        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let trusted = AXIsProcessTrustedWithOptions([promptKey: true] as CFDictionary)
        if trusted && createTap() {
            active = true
            vkLog("startup: keys active")
            return
        }
        vkLog(trusted ? "startup: permission granted but macOS refused the event tap"
                      : "startup: Accessibility permission missing; waiting for it")
        // Wait for the user to grant the permission in System Settings
        permTimer?.invalidate()
        permTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { timer in
            Task { @MainActor in
                let keys = VolumeKeys.shared
                guard AXIsProcessTrusted(), keys.createTap() else { return }
                timer.invalidate()
                keys.active = true
                vkLog("permission granted: keys active")
                let vm = ScarlettViewModel.shared
                keys.hud.show(step: keys.currentStep(vm), muted: vm.state.masterMute,
                              db: Int(vm.state.masterVolume), message: "Volume keys enabled")
            }
        }
    }

    /// CoreAudio notifications when the default output changes.
    private func watchOutputChanges() {
        gScarlettIsDefault = scarlettIsDefaultOutput()
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &addr, DispatchQueue.main) { _, _ in
            gScarlettIsDefault = scarlettIsDefaultOutput()
            vkLog("macOS output changed; is it the Scarlett? \(gScarlettIsDefault)")
        }
    }

    /// Every 2 s: re-enable the tap if macOS disabled it, refresh the output
    /// and check the permission.
    private func startHealthCheck() {
        healthTimer?.invalidate()
        healthTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
            Task { @MainActor in VolumeKeys.shared.checkHealth() }
        }
    }

    private func checkHealth() {
        gScarlettIsDefault = scarlettIsDefaultOutput()
        if let tap = gVolumeTap, !CGEvent.tapIsEnabled(tap: tap) {
            vkLog("the tap was disabled; re-enabling")
            CGEvent.tapEnable(tap: tap, enable: true)
        }
        let ok = gVolumeTap != nil && AXIsProcessTrusted()
        if active != ok {
            vkLog(ok ? "keys active" : "Accessibility permission missing")
            active = ok
        }
    }

    func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    private func createTap() -> Bool {
        if gVolumeTap != nil { return true }
        let mask = CGEventMask(1 << 14)   // NSEventTypeSystemDefined
        guard let tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap,
                                          options: .defaultTap, eventsOfInterest: mask,
                                          callback: volumeTapCallback, userInfo: nil) else { return false }
        gVolumeTap = tap
        let src = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), src, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    /// Current step: the one left by the keys, unless the Master was moved elsewhere
    /// (the app's fader), in which case it is derived from the value.
    private func currentStep(_ vm: ScarlettViewModel) -> Double {
        if let s = lastStep, let d = lastDB, d == vm.state.masterVolume { return s }
        return Self.dbToStep(Double(vm.state.masterVolume))
    }

    func handle(keyCode: Int, flags: CGEventFlags) {
        let vm = ScarlettViewModel.shared
        guard vm.isConnected else {
            vkLog("key \(keyCode): device not connected; reconnecting")
            hud.show(step: currentStep(vm), muted: vm.state.masterMute,
                     db: Int(vm.state.masterVolume), message: "Scarlett not connected")
            Task { await vm.connect() }
            return
        }

        if keyCode == kKeyMute {
            vm.setMute(!vm.state.masterMute)
            vkLog("mute key -> \(vm.state.masterMute ? "muted" : "unmuted")")
        } else {
            let fine = flags.contains(.maskShift) && flags.contains(.maskAlternate)
            let inc = fine ? 0.25 : 1.0
            var step = currentStep(vm) + (keyCode == kKeySoundUp ? inc : -inc)
            step = min(kVolumeSteps, max(0, (step * 4).rounded() / 4))
            let db = Self.stepToDB(step)
            if vm.state.masterMute { vm.setMute(false) }
            vm.setVolume(db)
            lastStep = step
            lastDB = Float(db)
            vkLog("\(keyCode == kKeySoundUp ? "volume up" : "volume down") -> Master \(db) dB")
        }
        hud.show(step: currentStep(vm), muted: vm.state.masterMute, db: Int(vm.state.masterVolume))
    }
}

// MARK: - On-screen volume HUD

private final class HUDBar: NSView {
    var fraction: Double = 0
    var muted = false

    override func draw(_ dirtyRect: NSRect) {
        let n = 16
        let gap: CGFloat = 3
        let w = (bounds.width - gap * CGFloat(n - 1)) / CGFloat(n)
        let filled = fraction * Double(n)
        for i in 0..<n {
            let r = NSRect(x: CGFloat(i) * (w + gap), y: 0, width: w, height: bounds.height)
            NSColor(white: 1, alpha: 0.18).setFill()
            NSBezierPath(roundedRect: r, xRadius: 1.5, yRadius: 1.5).fill()
            let part = min(1, max(0, filled - Double(i)))
            if part > 0 && !muted {
                var f = r
                f.size.width = w * CGFloat(part)
                NSColor(white: 1, alpha: 0.92).setFill()
                NSBezierPath(roundedRect: f, xRadius: 1.5, yRadius: 1.5).fill()
            }
        }
    }
}

@MainActor
final class VolumeHUD {
    private let panel: NSPanel
    private let icon = NSImageView()
    private let label = NSTextField(labelWithString: "Scarlett")
    private let bar = HUDBar()
    private var hideTask: Task<Void, Never>?

    init() {
        let frame = NSRect(x: 0, y: 0, width: 300, height: 64)
        panel = NSPanel(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel],
                        backing: .buffered, defer: false)
        panel.level = .statusBar
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.ignoresMouseEvents = true
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.isReleasedWhenClosed = false

        let bg = NSVisualEffectView(frame: frame)
        bg.material = .hudWindow
        bg.blendingMode = .behindWindow
        bg.state = .active
        bg.wantsLayer = true
        bg.layer?.cornerRadius = 16
        bg.layer?.masksToBounds = true
        bg.appearance = NSAppearance(named: .darkAqua)
        panel.contentView = bg

        icon.frame = NSRect(x: 16, y: 18, width: 28, height: 28)
        icon.contentTintColor = .white
        icon.imageScaling = .scaleProportionallyUpOrDown
        bg.addSubview(icon)

        label.frame = NSRect(x: 56, y: 36, width: 228, height: 16)
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = NSColor(white: 1, alpha: 0.85)
        bg.addSubview(label)

        bar.frame = NSRect(x: 56, y: 16, width: 228, height: 8)
        bg.addSubview(bar)
    }

    func show(step: Double, muted: Bool, db: Int, message: String? = nil) {
        let symbol: String
        if muted || step <= 0.001 { symbol = "speaker.slash.fill" }
        else if step < kVolumeSteps / 3 { symbol = "speaker.wave.1.fill" }
        else if step < kVolumeSteps * 2 / 3 { symbol = "speaker.wave.2.fill" }
        else { symbol = "speaker.wave.3.fill" }
        icon.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)

        if let message {
            label.stringValue = message
        } else if muted {
            label.stringValue = "Scarlett · muted"
        } else if db <= -128 {
            label.stringValue = "Scarlett · −∞ dB"
        } else {
            label.stringValue = "Scarlett · \(db == 0 ? "0" : "−\(abs(db))") dB"
        }
        bar.fraction = step / kVolumeSteps
        bar.muted = muted
        bar.needsDisplay = true

        if let screen = NSScreen.main ?? NSScreen.screens.first {
            let vf = screen.visibleFrame
            var f = panel.frame
            f.origin.x = vf.midX - f.width / 2
            f.origin.y = vf.minY + 120
            panel.setFrame(f, display: true)
        }
        // Cancel an ongoing fade-out and show at 100%
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0
            self.panel.animator().alphaValue = 1
        }, completionHandler: nil)
        panel.orderFrontRegardless()

        hideTask?.cancel()
        hideTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            guard let self, !Task.isCancelled else { return }
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.35
                self.panel.animator().alphaValue = 0
            }, completionHandler: nil)
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            self.panel.orderOut(nil)
        }
    }
}
