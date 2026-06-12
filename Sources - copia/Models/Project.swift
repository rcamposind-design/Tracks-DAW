import Foundation
import Observation

@Observable
final class Project {
    var name: String
    var tempo: Double
    var tracks: [Track]
    var connections: [Connection]

    init(name: String) {
        self.name = name
        self.tempo = 120
        self.tracks = []
        self.connections = []
    }

    func addTrack(_ track: Track) { tracks.append(track) }

    func removeTrack(_ id: UUID) {
        tracks.removeAll { $0.id == id }
        connections.removeAll { $0.destTrackID == id }
    }

    func toggleConnection(source: MIDISource, dest: UUID) {
        if let idx = connections.firstIndex(where: { $0.source == source && $0.destTrackID == dest }) {
            connections.remove(at: idx)
        } else {
            connections.append(Connection(source: source, dest: dest))
        }
    }

    func isConnected(source: MIDISource, dest: UUID) -> Bool {
        connections.contains { $0.source == source && $0.destTrackID == dest && $0.isActive }
    }
}
