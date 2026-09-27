import SwiftUI

struct BottomPanelView: View {
    @EnvironmentObject var vm: ScarlettViewModel
    var totalWidth: CGFloat
    var onPreset: () -> Void
    var onSettings: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            RoutingPanelView(onPreset: onPreset)
                .frame(maxWidth: .infinity)

            ClockPanelView(onSettings: onSettings)
                .frame(width: max(185, totalWidth * 0.26))

            MonitorPanelView()
                .frame(width: max(140, totalWidth * 0.18))
        }
        .padding(8)
        .background(Color(red: 0.07, green: 0.08, blue: 0.09))
    }
}