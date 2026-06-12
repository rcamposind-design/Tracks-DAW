import Foundation
import SwiftUI

struct Track: Identifiable, Hashable {
    let id: UUID
    var name: String
    var color: Color
    var volume: Float
    var pan: Float
    var isMuted: Bool
    var isSoloed: Bool
    var auType: UInt32?
    var auSubType: UInt32?
    var auManufacturer: UInt32?
    var auComponentName: String?
    var midiInputChannel: Int

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.color = Self.randomColor()
        self.volume = 0.8
        self.pan = 0
        self.isMuted = false
        self.isSoloed = false
        self.midiInputChannel = 0
    }

    static func randomColor() -> Color {
        [.red, .orange, .yellow, .green, .blue, .purple, .pink, .teal, .mint, .indigo].randomElement()!
    }
}
