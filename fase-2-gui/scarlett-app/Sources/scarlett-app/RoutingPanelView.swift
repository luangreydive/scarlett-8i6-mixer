import SwiftUI

struct RoutingPanelView: View {
    @EnvironmentObject var vm: ScarlettViewModel
    var onPreset: () -> Void

    private static let outputNames = [
        ["Mon L", "Mon R"],
        ["HP L", "HP R"],
        ["S/PDIF L", "S/PDIF R"]
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                SectionTitle(text: "OUTPUT ROUTING")
                Spacer()
                Text(vm.routingPreset)
                    .font(ScarlettUI.title(9, .semibold))
                    .foregroundStyle(ScarlettUI.accent)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 3)
                            .fill(ScarlettUI.accent.opacity(0.12))
                            .overlay(RoundedRectangle(cornerRadius: 3).stroke(ScarlettUI.accent.opacity(0.4), lineWidth: 0.5))
                    )

                Button {
                    onPreset()
                } label: {
                    Text("Presets…")
                        .font(ScarlettUI.title(9, .medium))
                        .foregroundStyle(ScarlettUI.textPrimary)
                        .padding(.horizontal, 6)
                        .frame(height: 18)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.06))
                                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.white.opacity(0.1), lineWidth: 0.5))
                        )
                }
                .buttonStyle(.plain)
            }

            Grid(alignment: .leading, horizontalSpacing: 6, verticalSpacing: 4) {
                ForEach(0..<3, id: \.self) { row in
                    GridRow {
                        Text("\(outputName(row, 0)) →")
                            .font(ScarlettUI.mono(10, .medium))
                            .foregroundStyle(ScarlettUI.textSecondary)
                        outputPicker(bus: row * 2)

                        Text("\(outputName(row, 1)) →")
                            .font(ScarlettUI.mono(10, .medium))
                            .foregroundStyle(ScarlettUI.textSecondary)
                        outputPicker(bus: row * 2 + 1)
                    }
                }
            }
        }
        .padding(10)
        .cardStyle(radius: 6)
    }

    private func outputName(_ row: Int, _ col: Int) -> String {
        Self.outputNames[row][col]
    }

    private static let availableSources: [(label: String, src: Int)] = [
        ("DAW 1", 0),
        ("DAW 2", 1),
        ("Input 1 (Guitar)", 12),
        ("Input 2", 13),
        ("Input 3", 14),
        ("Input 4", 15),
        ("S/PDIF 1", 16),
        ("S/PDIF 2", 17),
        ("Mix 1 L", 18),
        ("Mix 1 R", 19),
        ("Mix 2 L", 20),
        ("Mix 2 R", 21),
        ("Mix 3 L", 22),
        ("Mix 3 R", 23)
    ]

    static func sourceLabel(for src: Int) -> String {
        if let found = availableSources.first(where: { $0.src == src }) {
            return found.label
        }
        return "Src \(src)"
    }

    private func outputPicker(bus: Int) -> some View {
        let currentSrc = vm.routing.outputMux.indices.contains(bus) ? vm.routing.outputMux[bus] : 0
        return Menu {
            ForEach(Self.availableSources, id: \.src) { item in
                Button(item.label) { vm.setOutputMux(bus: bus, src: item.src) }
            }
        } label: {
            HStack(spacing: 4) {
                Text(Self.sourceLabel(for: currentSrc))
                    .font(ScarlettUI.title(9, .medium))
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(ScarlettUI.textMuted)
            }
            .foregroundStyle(ScarlettUI.textPrimary)
            .padding(.horizontal, 6)
            .frame(width: 88, height: 22)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(red: 0.10, green: 0.11, blue: 0.13))
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.white.opacity(0.10), lineWidth: 0.6))
            )
        }
        .menuStyle(.borderlessButton)
    }
}
