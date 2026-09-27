import SwiftUI

struct ChannelSpec: Identifiable {
    var id: String { label }
    let label: String
    let color: Color
    let isAnalog: Bool
    let isStereo: Bool
    let leftIndex: Int
    let rightIndex: Int
}

enum ChannelCatalog {
    static let all: [ChannelSpec] = [
        ChannelSpec(label: "Input 1", color: .blue, isAnalog: true, isStereo: false, leftIndex: 0, rightIndex: 0),
        ChannelSpec(label: "Input 2", color: .cyan, isAnalog: true, isStereo: false, leftIndex: 1, rightIndex: 1),
        ChannelSpec(label: "Input 3", color: .green, isAnalog: true, isStereo: false, leftIndex: 2, rightIndex: 2),
        ChannelSpec(label: "Input 4", color: .mint, isAnalog: true, isStereo: false, leftIndex: 3, rightIndex: 3),
        ChannelSpec(label: "S/PDIF L", color: .purple, isAnalog: false, isStereo: false, leftIndex: 4, rightIndex: 4),
        ChannelSpec(label: "S/PDIF R", color: .purple, isAnalog: false, isStereo: false, leftIndex: 5, rightIndex: 5),
        ChannelSpec(label: "DAW 1-2", color: .orange, isAnalog: false, isStereo: true, leftIndex: 6, rightIndex: 7)
    ]
}
