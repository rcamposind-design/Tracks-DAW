import Foundation
import Observation

@Observable
final class Transport {
    enum State { case stopped, playing, recording }
    var state: State = .stopped
    var position: Double = 0
    var isPlaying: Bool { state == .playing }
    func play() { state = .playing }
    func stop() { state = .stopped; position = 0 }
    func togglePlay() { state = isPlaying ? .stopped : .playing }
}
