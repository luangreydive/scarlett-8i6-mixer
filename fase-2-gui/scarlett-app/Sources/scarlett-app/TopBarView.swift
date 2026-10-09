import SwiftUI

struct TopBarView: View {
    @EnvironmentObject var vm: ScarlettViewModel
    var onPresets: () -> Void
    @LocalState private var flashBusy = false
    @LocalState private var flashOK: Bool?

    var body: some View {
        HStack(spacing: 14) {
            // Focusrite Scarlett Brand Badge
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(ScarlettUI.scarlettRed)
                    .frame(width: 4, height: 16)

                Text("SCARLETT")
                    .font(.system(size: 11, weight: .black, design: .default))
                    .foregroundStyle(ScarlettUI.textPrimary)
                    .tracking(1.5)

                Text("8i6")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(ScarlettUI.scarlettRed)

                // Connection & Rate Pill
                HStack(spacing: 5) {
                    Circle()
                        .fill(vm.isConnected ? ScarlettUI.emerald : Color.red)
                        .frame(width: 7, height: 7)
                        .shadow(color: (vm.isConnected ? ScarlettUI.emerald : Color.red).opacity(0.6), radius: 3)

                    Text(vm.isConnected ? "CONNECTED" : "OFFLINE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(vm.isConnected ? ScarlettUI.emerald : Color.red.opacity(0.8))
                        .tracking(0.5)

                    if vm.isConnected {
                        Text("•")
                            .font(.system(size: 9))
                            .foregroundStyle(ScarlettUI.textMuted)

                        Text("\(vm.state.rate / 1000) kHz")
                            .font(ScarlettUI.mono(9, .semibold))
                            .foregroundStyle(ScarlettUI.textSecondary)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(red: 0.06, green: 0.07, blue: 0.09))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08), lineWidth: 0.5))
                )
            }
            .help(vm.lastError ?? "")

            Spacer()

            // Presets Button
            Button {
                onPresets()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 9, weight: .bold))
                    Text("Presets")
                        .font(ScarlettUI.title(10, .semibold))
                }
                .foregroundStyle(ScarlettUI.textPrimary)
                .padding(.horizontal, 8)
                .frame(height: 22)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(red: 0.15, green: 0.16, blue: 0.19))
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.white.opacity(0.10), lineWidth: 0.8))
                )
            }
            .buttonStyle(.plain)

            // Save to Hardware Button
            Button {
                flashBusy = true
                Task { @MainActor in
                    flashOK = await vm.saveToHardware()
                    flashBusy = false
                    // 8i6: show the result (ok or error) for a few seconds
                    try? await Task.sleep(nanoseconds: flashOK == true ? 2_000_000_000 : 4_000_000_000)
                    flashOK = nil
                }
            } label: {
                HStack(spacing: 4) {
                    if flashBusy {
                        ProgressView().controlSize(.small).scaleEffect(0.6)
                    } else {
                        Image(systemName: flashOK == true ? "checkmark.circle.fill"
                                          : (flashOK == false ? "xmark.octagon.fill" : "memorychip"))
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(flashOK == true ? ScarlettUI.emerald : ScarlettUI.scarlettRed)
                    }

                    Text(flashOK == true ? "Saved" : (flashOK == false ? "Save failed" : "Save to Hardware"))
                        .font(ScarlettUI.title(10, .semibold))
                        .foregroundStyle(ScarlettUI.textPrimary)
                }
                .padding(.horizontal, 8)
                .frame(height: 22)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(red: 0.15, green: 0.16, blue: 0.19))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(flashOK == true ? ScarlettUI.emerald.opacity(0.6)
                                        : (flashOK == false ? ScarlettUI.scarlettRed.opacity(0.8) : Color.white.opacity(0.10)),
                                        lineWidth: 0.8)
                        )
                )
            }
            .buttonStyle(.plain)
            .disabled(flashBusy)
            .help("Persist current mixer settings to the device flash")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            LinearGradient(
                colors: [Color(red: 0.13, green: 0.14, blue: 0.17), Color(red: 0.08, green: 0.09, blue: 0.11)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(Divider().background(Color.white.opacity(0.08)), alignment: .bottom)
    }
}