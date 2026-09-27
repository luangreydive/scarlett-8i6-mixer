import SwiftUI

struct ChannelsAreaView: View {
    @EnvironmentObject var vm: ScarlettViewModel
    var totalWidth: CGFloat
    var onCopyMix: () -> Void

    private static let gap: CGFloat = 3
    private static let sidePad: CGFloat = 8

    var body: some View {
        let baseW = stripWidth
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .center, spacing: Self.gap) {
                channelStrips(baseWidth: baseW)

                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 1, height: 260)
                    .padding(.horizontal, 2)

                MasterChannelView(onCopyMix: onCopyMix)
                    .frame(width: max(65, baseW * 1.15))
            }
            .frame(maxHeight: .infinity, alignment: .center)
            .padding(.horizontal, Self.sidePad)
            .padding(.vertical, 12)
        }
    }

    private var stripWidth: CGFloat {
        let monoCount = CGFloat(ChannelCatalog.all.filter { !$0.isStereo }.count)
        let stereoCount = CGFloat(ChannelCatalog.all.filter { $0.isStereo }.count)
        let totalUnits = monoCount + stereoCount * 1.25 + 1.15 // + 1.15 for Master
        let available = totalWidth - Self.sidePad * 2 - Self.gap * CGFloat(ChannelCatalog.all.count)
        let base = available / max(1, totalUnits)
        return max(54, min(75, base))
    }

    private func channelStrips(baseWidth: CGFloat) -> some View {
        HStack(spacing: 2) {
            ForEach(ChannelCatalog.all) { spec in
                ChannelStripView(
                    spec: spec,
                    width: spec.isStereo ? baseWidth * 1.25 : baseWidth
                )
            }
        }
    }
}
