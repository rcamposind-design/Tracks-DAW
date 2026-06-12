import Foundation

enum MIDISource: Hashable {
    case midiInput(channel: Int)
    case track(UUID)

    var label: String {
        switch self {
        case .midiInput(let ch): ch == 0 ? "MIDI In (All)" : "MIDI In (Ch \(ch))"
        case .track: "Track"
        }
    }
}

struct Connection: Identifiable, Hashable {
    let id: UUID
    var source: MIDISource
    var destTrackID: UUID
    var isActive: Bool
    var midiChannel: Int

    init(source: MIDISource, dest: UUID) {
        self.id = UUID()
        self.source = source
        self.destTrackID = dest
        self.isActive = true
        self.midiChannel = 0
    }
}
