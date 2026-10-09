import SwiftUI

struct ClockPanelView: View {
    @EnvironmentObject var vm: ScarlettViewModel
    var onSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionTitle(text: "SYNC & HARDWARE")

            HStack {
                Text("Sample Rate")
                    .font(ScarlettUI.title(10))
                    .foregroundStyle(ScarlettUI.textSecondary)
                Spacer()
                Picker("", selection: Binding(
                    get: { "\(vm.state.rate)" },
                    set: { vm.setSampleRate(Int($0) ?? 44100) }
                )) {
                    Text("44.1 kHz").tag("44100")
                    Text("48.0 kHz").tag("48000")
                    Text("88.2 kHz").tag("88200")
                    Text("96.0 kHz").tag("96000")
                }
                .pickerStyle(.menu)
                .controlSize(.mini)
                .fixedSize()
                .chipStyle()
            }

            HStack {
                Text("Clock Source")
                    .font(ScarlettUI.title(10))
                    .foregroundStyle(ScarlettUI.textSecondary)
                Spacer()
                Picker("", selection: Binding(
                    get: { vm.state.clock },
                    set: { vm.setClockSource($0) }
                )) {
                    Text("Internal").tag("Internal")
                    Text("S/PDIF").tag("S/PDIF")
                    Text("ADAT").tag("ADAT")
                }
                .pickerStyle(.menu)
                .controlSize(.mini)
                .fixedSize()
                .chipStyle()
            }

            clockRow("Clock Lock", vm.state.sync, dot: vm.state.sync == "Locked" ? ScarlettUI.emerald : Color.red)
            clockRow("Interface", "USB 2.0 Audio", accent: ScarlettUI.emerald)
            clockRow("Hardware", "Scarlett 8i6")

            Spacer()

            Button {
                onSettings()
            } label: {
                Text("Device Info…")
                    .font(ScarlettUI.title(9, .medium))
                    .foregroundStyle(ScarlettUI.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 18)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.06))
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.white.opacity(0.08), lineWidth: 0.5))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .cardStyle(radius: 6)
    }

    private func clockRow(_ label: String, _ value: String, dot: Color? = nil, accent: Color? = nil) -> some View {
        HStack {
            Text(label)
                .font(ScarlettUI.title(10))
                .foregroundStyle(ScarlettUI.secondaryText)
            Spacer()
            if let d = dot {
                Circle().fill(d).frame(width: 5, height: 5)
            }
            Text(value)
                .font(ScarlettUI.mono(11))
                .foregroundStyle(accent ?? .white)
        }
    }
}
