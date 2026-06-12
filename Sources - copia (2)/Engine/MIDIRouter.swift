import Foundation
import Observation

@Observable
final class MIDIRouter {
    var connections: [Connection] = []

    func updateConnections(_ new: [Connection]) { connections = new }

    func shouldRouteEvent(from source: MIDISource, channel: UInt8) -> [UUID] {
        connections.filter { conn in
            guard conn.isActive else { return false }
            if conn.source != source { return false }
            if conn.midiChannel == 0 { return true }
            return conn.midiChannel == Int(channel) + 1
        }.map { $0.destTrackID }
    }
}
