import SwiftUI

struct MixTabsView: View {
    @EnvironmentObject var vm: ScarlettViewModel

    var body: some View {
        HStack(spacing: 4) {
            Text("MIX")
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(ScarlettUI.textMuted)
                .tracking(1.0)
                .padding(.leading, 8)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { i in   // 8i6: 6 mixes = 3 pairs
                        let mixNum = i * 2 + 1
                        let isActive = vm.activeMix == i
                        Button {
                            vm.activeMix = i
                        } label: {
                            VStack(spacing: 2) {
                                Text("Mix \(mixNum)-\(mixNum + 1)")
                                    .font(ScarlettUI.title(10, isActive ? .bold : .medium))
                                    .foregroundStyle(isActive ? ScarlettUI.textPrimary : ScarlettUI.textSecondary)

                                Rectangle()
                                    .fill(isActive ? ScarlettUI.scarlettRed : Color.clear)
                                    .frame(height: 2)
                                    .cornerRadius(1)
                            }
                            .padding(.horizontal, 8)
                            .padding(.top, 4)
                            .padding(.bottom, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(isActive ? Color(red: 0.18, green: 0.20, blue: 0.24) : Color.clear)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .frame(height: 32)
        .padding(.vertical, 2)
        .background(Color(red: 0.07, green: 0.08, blue: 0.10))
        .overlay(Divider().background(Color.white.opacity(0.06)), alignment: .bottom)
    }
}
