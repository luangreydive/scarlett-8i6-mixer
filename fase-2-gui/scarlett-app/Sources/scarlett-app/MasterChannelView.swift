import SwiftUI

struct MasterChannelView: View {
    @EnvironmentObject var vm: ScarlettViewModel
    var onCopyMix: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            VStack(spacing: 2) {
                Text("MASTER")
                    .font(ScarlettUI.title(11, .bold))
                    .foregroundStyle(ScarlettUI.scarlettRed)
                    .tracking(1.0)
                Rectangle()
                    .fill(ScarlettUI.scarlettRed.opacity(0.8))
                    .frame(width: 24, height: 2)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 2)

            Color.clear.frame(height: 42)

            HStack(spacing: 3) {
                HStack(spacing: 2) {
                    MeterBar(
                        level: masterMeterLeft,
                        hold: vm.meterHoldLevel(vm.meters.count >= 2 ? vm.meters.count - 2 : 0),
                        onResetHold: { vm.resetMeterHold(vm.meters.count >= 2 ? vm.meters.count - 2 : 0) },
                        width: 5
                    )
                    MeterBar(
                        level: masterMeterRight,
                        hold: vm.meterHoldLevel(vm.meters.count > 0 ? vm.meters.count - 1 : 0),
                        onResetHold: { vm.resetMeterHold(vm.meters.count > 0 ? vm.meters.count - 1 : 0) },
                        width: 5
                    )
                }
                .frame(height: 160)

                Fader(position: masterFaderPos, onChange: { position in
                    vm.setVolume(masterDB(for: position))
                }) {
                    vm.setVolume(0)
                }
                .frame(width: 32, height: 160)
            }

            Text(ScarlettViewModel.volumeDBString(vm.state.masterVolume))
                .font(ScarlettUI.mono(10, .semibold))
                .foregroundStyle(ScarlettUI.textPrimary)
                .padding(.horizontal, 4)
                .padding(.vertical, 1.5)
                .background(
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(red: 0.08, green: 0.09, blue: 0.11))
                        .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.white.opacity(0.06), lineWidth: 0.5))
                )

            ToggleButton(
                label: "MUTE",
                isOn: vm.state.masterMute,
                onColor: ScarlettUI.scarlettRed,
                offColor: ScarlettUI.textMuted,
                font: .system(size: 9, weight: .bold),
                controlSize: .mini,
                minWidth: 44,
                height: 18
            ) {
                vm.setMute(!vm.state.masterMute)
            }

            Button("Copy Mix…") { onCopyMix() }
                .font(ScarlettUI.title(9, .medium))
                .foregroundStyle(ScarlettUI.textSecondary)
                .padding(.horizontal, 4)
                .frame(height: 18)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.06))
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.white.opacity(0.08), lineWidth: 0.5))
                )
                .buttonStyle(.plain)

            Text("MONITOR")
                .font(ScarlettUI.title(9, .semibold))
                .foregroundStyle(ScarlettUI.textMuted)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(red: 0.13, green: 0.14, blue: 0.17))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(ScarlettUI.scarlettRed.opacity(0.7), lineWidth: 1.2)
                )
                .shadow(color: ScarlettUI.scarlettRed.opacity(0.2), radius: 4, x: 0, y: 1)
        )
    }

    private var masterFaderPos: CGFloat {
        CGFloat(vm.state.masterVolume + 128) / 128 * 0.75
    }

    private func masterDB(for position: CGFloat) -> Int {
        let dB = position <= 0.75 ? -128 + (position / 0.75) * 128 : 0
        return Int(dB.rounded())
    }

    private var masterMeterLevel: CGFloat {
        guard !vm.meters.isEmpty else { return 0 }
        return min(1, CGFloat(vm.meters.max() ?? 0) / 65535)
    }

    private var masterMeterLeft: CGFloat {
        guard vm.meters.count >= 2 else { return masterMeterLevel }
        return CGFloat(vm.meters[vm.meters.count - 2]) / 65535
    }

    private var masterMeterRight: CGFloat {
        guard let value = vm.meters.last else { return masterMeterLevel }
        return CGFloat(value) / 65535
    }
}
