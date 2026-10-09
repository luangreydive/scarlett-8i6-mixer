import Foundation
import SwiftUI
import AppKit
import ServiceManagement
import Combine

/// Redirect stderr to a file for crash diagnostics.
func setupCrashLog() {
    let logPath = "/tmp/scarlett-app-crash.log"
    if let f = fopen(logPath, "w") {
        dup2(fileno(f), STDERR_FILENO)
    }
    // Try to not die on SIGPIPE if stdout/stderr is a closed pipe
    signal(SIGPIPE, SIG_IGN)
}

// 8i6: launch at login (System Settings › General › Login Items)
enum LoginItem {
    static var isEnabled: Bool { SMAppService.mainApp.status == .enabled }

    static func set(_ on: Bool) {
        do {
            if on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
        } catch {
            let a = NSAlert()
            a.messageText = "Could not change Launch at Login"
            a.informativeText = "Add it manually in System Settings › General › Login Items.\n\n(\(error.localizedDescription))"
            NSApp.activate(ignoringOtherApps: true)
            a.runModal()
        }
    }
}

/// 8i6: shows the main window (with a Dock icon) or hides it (menu bar only).
@MainActor
enum WindowPresence {
    static func isMainWindow(_ w: NSWindow) -> Bool {
        w.styleMask.contains(.titled) && !(w is NSPanel)
    }

    static func didShowWindow() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        ScarlettViewModel.shared.setMetersActive(true)
    }

    static func hideAllWindows() {
        for w in NSApp.windows where isMainWindow(w) { w.close() }
        NSApp.setActivationPolicy(.accessory)
        ScarlettViewModel.shared.setMetersActive(false)
    }
}

final class ScarlettAppDelegate: NSObject, NSApplicationDelegate {
    private var keyMonitor: Any?
    private var closeObserver: NSObjectProtocol?

    @MainActor
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 8i6: launched at login? Then start without a window.
        let ev = NSAppleEventManager.shared().currentAppleEvent
        let launchedAtLogin = ev?.eventID == AEEventID(kAEOpenApplication) &&
            ev?.paramDescriptor(forKeyword: AEKeyword(keyAEPropData))?.enumCodeValue == OSType(keyAELaunchedAsLogInItem)

        if launchedAtLogin {
            NSApplication.shared.setActivationPolicy(.accessory)
            // SwiftUI creates the window a moment later: close it as soon as it appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                MainActor.assumeIsolated { WindowPresence.hideAllWindows() }
            }
        } else {
            NSApplication.shared.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
        }

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            fputs("keyEvent chars=\(event.charactersIgnoringModifiers ?? "-")\n", stderr)
            return event
        }

        // 8i6: when the window closes, the app stays in the menu bar (no Dock icon)
        closeObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification, object: nil, queue: .main
        ) { note in
            guard let closing = note.object as? NSWindow else { return }
            DispatchQueue.main.async {
                MainActor.assumeIsolated {
                    guard WindowPresence.isMainWindow(closing) else { return }
                    let others = NSApp.windows.filter {
                        $0 !== closing && $0.isVisible && WindowPresence.isMainWindow($0)
                    }
                    if others.isEmpty {
                        NSApp.setActivationPolicy(.accessory)
                        ScarlettViewModel.shared.setMetersActive(false)
                    }
                }
            }
        }

        // 8i6: connect to the device and enable the volume keys, with or without a window
        Task { @MainActor in
            await ScarlettViewModel.shared.connect()
        }
        VolumeKeys.shared.start()
    }

    /// Clean up the daemon we spawned on quit (Cmd+Q / "Quit" in the menu).
    func applicationWillTerminate(_ notification: Notification) {
        MainActor.assumeIsolated { DaemonManager.shared.shutdown() }
    }

    /// 8i6: closing the window does NOT quit the app (the volume keys keep working).
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    /// 8i6: double-clicking the app (or clicking the Dock icon) with the window closed shows it again.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { NSApp.setActivationPolicy(.regular) }
        return true
    }
}

/// 8i6: menu bar menu state. Updated only when the Master, mute, connection or
/// permission change (not 10 times per second with the meters), and the
/// "Launch at Login" status is queried once. Previously the menu redrew
/// constantly and kept the main thread busy, which is the same thread that
/// handles the volume keys.
@MainActor
final class MenuModel: ObservableObject {
    static let shared = MenuModel()

    @Published private(set) var masterText = "Scarlett disconnected"
    @Published private(set) var keysActive = false
    @Published private(set) var loginEnabled = false
    private var bag = Set<AnyCancellable>()

    private init() {
        loginEnabled = LoginItem.isEnabled
        let vm = ScarlettViewModel.shared
        vm.$state
            .map { ($0.masterVolume, $0.masterMute) }
            .combineLatest(vm.$isConnected)
            .map { values, connected -> String in
                let (volume, muted) = values
                guard connected else { return "Scarlett disconnected" }
                if muted { return "Master: muted" }
                let db = Int(volume.rounded())
                if db <= -128 { return "Master: −∞ dB" }
                return "Master: \(db == 0 ? "0" : "−\(abs(db))") dB"
            }
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] text in self?.masterText = text }
            .store(in: &bag)
        VolumeKeys.shared.$active
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] active in self?.keysActive = active }
            .store(in: &bag)
    }

    func setLogin(_ on: Bool) {
        LoginItem.set(on)
        loginEnabled = LoginItem.isEnabled
    }
}

/// 8i6: menu bar menu (speaker icon).
struct StatusMenu: View {
    @ObservedObject var menu: MenuModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Text(menu.masterText)
        if !menu.keysActive {
            Button("⚠︎ Enable volume keys (Accessibility permission)…") {
                VolumeKeys.shared.openAccessibilitySettings()
            }
        }
        Divider()
        Button("Open Scarlett 8i6 Mixer") {
            NSApp.setActivationPolicy(.regular)
            openWindow(id: "main")
            NSApp.activate(ignoringOtherApps: true)
        }
        Button("Volume to maximum (0 dB)") {
            let vm = ScarlettViewModel.shared
            vm.setMute(false)
            vm.setVolume(0)
        }
        Toggle("Launch at Login", isOn: Binding(
            get: { menu.loginEnabled },
            set: { menu.setLogin($0) }
        ))
        Divider()
        Button("Quit Scarlett 8i6 Mixer") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }
}

@main
struct ScarlettApp: App {
    @NSApplicationDelegateAdaptor(ScarlettAppDelegate.self) private var appDelegate
    // 8i6: no @ObservedObject: the App must not re-render on every model change
    private let vm = ScarlettViewModel.shared

    init() {
        setupCrashLog()
    }

    var body: some Scene {
        // 8i6: a single window (not WindowGroup) so "Open" never duplicates windows
        Window("Scarlett 8i6 Mixer", id: "main") {
            ContentView()
                .environmentObject(vm)
                .preferredColorScheme(.dark)
                .frame(minWidth: 800, minHeight: 500)
                .onAppear { WindowPresence.didShowWindow() }
        }
        .windowResizability(.contentSize)

        MenuBarExtra("Scarlett 8i6", systemImage: "hifispeaker.fill") {
            StatusMenu(menu: MenuModel.shared)
        }
    }
}
