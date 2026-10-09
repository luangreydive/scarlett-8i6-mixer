import SwiftUI

struct ChannelStripView: View {
    @EnvironmentObject var vm: ScarlettViewModel
    let spec: ChannelSpec
    var width: CGFloat = 70

    private var leftCh: ScarlettState.InputChannel? {
        vm.state.inputs.indices.contains(spec.leftIndex) ? vm.state.inputs[spec.leftIndex] : nil
    }

    private var rightCh: ScarlettState.InputChannel? {
        vm.state.inputs.indices.contains(spec.rightIndex) ? vm.state.inputs[spec.rightIndex] : nil
    }

    private var isSoloActive: Bool {
        leftCh?.solo == true || (spec.isStereo && rightCh?.solo == true)
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(spec.label)
                .font(ScarlettUI.title(spec.isStereo ? 11 : 12, .bold))
                .foregroundStyle(ScarlettUI.textPrimary)
                .frame(maxWidth: .infinity)

            if spec.isAnalog {
                preampSection
            } else if spec.isStereo {
                stereoBadge
            } else {
                Color.clear.frame(height: 42)
            }

            panSection

            faderSection

            dBReadout

            pflButton

            muteAndSolo

            Text(spec.label)
                .font(ScarlettUI.title(spec.isStereo ? 9 : 10, .semibold))
                .foregroundStyle(ScarlettUI.textSecondary)
        }
        .frame(width: width)
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(ScarlettUI.stripFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSoloActive ? Color.yellow : ScarlettUI.stripBorder, lineWidth: isSoloActive ? 1.5 : 0.8)
                )
                .shadow(color: isSoloActive ? Color.yellow.opacity(0.3) : Color.black.opacity(0.35), radius: 4, x: 0, y: 1)
        )
    }

    // MARK: - Stereo Badge

    private var stereoBadge: some View {
        VStack(spacing: 2) {
            Text("STEREO")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(spec.color)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(spec.color.opacity(0.15))
                .cornerRadius(4)
            Text("DAW Playback")
                .font(.system(size: 8))
                .foregroundStyle(ScarlettUI.labelOnStrip.opacity(0.6))
        }
        .frame(height: 42)
    }

    // MARK: - Preamp

    private var isLo: Bool { spec.leftIndex < 2 ? leftCh?.impedance == "Line" : leftCh?.gain == "Lo" }
    private var isHi: Bool { spec.leftIndex < 2 ? leftCh?.impedance == "Hi-Z" : leftCh?.gain == "Hi" }

    private var preampSection: some View {
        // 8i6: Line/Inst only on inputs 1-2; Pad only on 3-4; no Lo/Hi switch
        VStack(spacing: 3) {
            if spec.leftIndex < 2 {
                HStack(spacing: 3) {
                    ToggleButton(label: "Line", isOn: isLo, onColor: .cyan, offColor: ScarlettUI.textMuted, height: 18) {
                        vm.setGain(ch: spec.leftIndex + 1, "lo")
                    }
                    ToggleButton(label: "Inst", isOn: isHi, onColor: .cyan, offColor: ScarlettUI.textMuted, height: 18) {
                        vm.setGain(ch: spec.leftIndex + 1, "hi")
                    }
                }
            } else {
                ToggleButton(label: "Pad", isOn: leftCh?.pad == true, onColor: .orange, offColor: ScarlettUI.textMuted, height: 18) {
                    vm.setPad(ch: spec.leftIndex + 1, !(leftCh?.pad ?? false))
                }
            }
        }
    }

    // MARK: - Pan / Balance

    private var panSection: some View {
        VStack(spacing: 2) {
            RotaryKnob(
                value: leftCh?.pan ?? 0.5,
                onColor: spec.isStereo ? .orange : .cyan,
                size: 26,
                onChange: { val in
                    if spec.isStereo {
                        vm.setStereoPan(left: spec.leftIndex, right: spec.rightIndex, val)
                    } else {
                        vm.setInputPan(ch: spec.leftIndex, val)
                    }
                },
                onReset: {
                    if spec.isStereo {
                        vm.setStereoPan(left: spec.leftIndex, right: spec.rightIndex, 0.5)
                    } else {
                        vm.setInputPan(ch: spec.leftIndex, 0.5)
                    }
                }
            )
            Text(panText)
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundStyle(ScarlettUI.textMuted)
        }
    }

    private var panText: String {
        let p = leftCh?.pan ?? 0.5
        if abs(p - 0.5) < 0.02 { return "C" }
        if p < 0.5 {
            let pct = Int(round((0.5 - p) * 200))
            return "L\(pct)"
        } else {
            let pct = Int(round((p - 0.5) * 200))
            return "R\(pct)"
        }
    }

    // MARK: - Fader + Meter

    private var faderSection: some View {
        HStack(spacing: 3) {
            if spec.isStereo {
                HStack(spacing: 2) {
                    MeterBar(
                        level: meterLevel(spec.leftIndex),
                        color: spec.color,
                        hold: vm.meterHoldLevel(spec.leftIndex),
                        onResetHold: { vm.resetMeterHold(spec.leftIndex) },
                        width: 5
                    )
                    MeterBar(
                        level: meterLevel(spec.rightIndex),
                        color: spec.color,
                        hold: vm.meterHoldLevel(spec.rightIndex),
                        onResetHold: { vm.resetMeterHold(spec.rightIndex) },
                        width: 5
                    )
                }
                .frame(height: 160)
            } else {
                MeterBar(level: meterLevel(spec.leftIndex), color: spec.color, hold: vm.meterHoldLevel(spec.leftIndex)) {
                    vm.resetMeterHold(spec.leftIndex)
                }
            }

            Fader(position: CGFloat(leftCh?.mixLevel ?? 0.75), onChange: { pos in
                if spec.isStereo {
                    vm.setStereoMixLevel(left: spec.leftIndex, right: spec.rightIndex, Float(pos))
                } else {
                    vm.setMixLevel(ch: spec.leftIndex, Float(pos))
                }
            }) {
                if spec.isStereo {
                    vm.setStereoMixLevel(left: spec.leftIndex, right: spec.rightIndex, 0.75)
                } else {
                    vm.setMixLevel(ch: spec.leftIndex, 0.75)
                }
            }
        }
        .frame(height: 160)
    }

    private func meterLevel(_ idx: Int) -> CGFloat {
        guard vm.meters.indices.contains(idx) else { return 0 }
        return CGFloat(vm.meters[idx]) / 65535.0
    }

    // MARK: - dB Readout

    private var dBReadout: some View {
        Text(ScarlettViewModel.dBString(from: leftCh?.mixLevel ?? 0.75))
            .font(ScarlettUI.mono(10, .semibold))
            .foregroundStyle(ScarlettUI.textPrimary)
            .padding(.horizontal, 4)
            .padding(.vertical, 1.5)
            .background(
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(red: 0.08, green: 0.09, blue: 0.11))
                    .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.white.opacity(0.06), lineWidth: 0.5))
            )
    }

    // MARK: - PFL + Link

    private var pflButton: some View {
        HStack(spacing: 6) {
            ToggleButton(label: "PFL", isOn: leftCh?.pfl == true, onColor: ScarlettUI.emerald, offColor: ScarlettUI.textMuted, font: .system(size: 9, weight: .bold), controlSize: .mini, height: 16) {
                if spec.isStereo {
                    vm.toggleStereoPfl(left: spec.leftIndex, right: spec.rightIndex)
                } else {
                    vm.toggleInputPfl(spec.leftIndex)
                }
            }
            if !spec.isStereo {
                Image(systemName: leftCh?.stereoLink == true ? "link" : "link.slash")
                    .font(.system(size: 9))
                    .foregroundColor(leftCh?.stereoLink == true ? .cyan : ScarlettUI.textMuted.opacity(0.4))
                    .onTapGesture { vm.toggleInputStereoLink(spec.leftIndex) }
            } else {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 9))
                    .foregroundColor(spec.color.opacity(0.8))
            }
        }
    }

    // MARK: - Mute + Solo

    private var muteAndSolo: some View {
        HStack(spacing: 4) {
            ToggleButton(label: "M", isOn: leftCh?.mute == true, onColor: ScarlettUI.scarlettRed, offColor: ScarlettUI.textMuted, font: .system(size: 10, weight: .bold), controlSize: .mini, minWidth: 22, height: 18) {
                if spec.isStereo {
                    vm.toggleStereoMute(left: spec.leftIndex, right: spec.rightIndex)
                } else {
                    vm.toggleInputMute(spec.leftIndex)
                }
            }
            ToggleButton(label: "S", isOn: leftCh?.solo == true, onColor: ScarlettUI.amber, offColor: ScarlettUI.textMuted, font: .system(size: 10, weight: .bold), controlSize: .mini, minWidth: 22, height: 18) {
                if spec.isStereo {
                    vm.toggleStereoSolo(left: spec.leftIndex, right: spec.rightIndex)
                } else {
                    vm.toggleInputSolo(spec.leftIndex)
                }
            }
        }
    }
}