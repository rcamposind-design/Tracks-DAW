import SwiftUI

@main
struct TracksApp: App {
    @State private var project = Project(name: "Untitled")
    @State private var audioEngine = AudioEngine()
    @State private var midiRouter = MIDIRouter()
    @State private var midiManager = MIDIManager()
    @State private var transport = Transport()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(project)
                .environment(audioEngine)
                .environment(midiRouter)
                .environment(midiManager)
                .environment(transport)
                .task {
                    try? audioEngine.start()
                    midiManager.setup()
                    midiManager.onMIDIEvent = handleMIDIEvent
                }
                .onDisappear {
                    audioEngine.allNotesOff()
                    audioEngine.stop()
                }
        }
    }

    private func handleMIDIEvent(status: UInt8, data1: UInt8, data2: UInt8, channel: UInt8) {
        let source = MIDISource.midiInput(channel: Int(channel) + 1)
        let dests = midiRouter.shouldRouteEvent(from: source, channel: channel)
        if dests.isEmpty {
            let destsAll = midiRouter.shouldRouteEvent(from: .midiInput(channel: 0), channel: channel)
            for trackID in destsAll {
                routeMIDI(trackID: trackID, status: status, data1: data1, data2: data2, channel: channel)
            }
        } else {
            for trackID in dests {
                routeMIDI(trackID: trackID, status: status, data1: data1, data2: data2, channel: channel)
            }
        }
    }

    private func routeMIDI(trackID: UUID, status: UInt8, data1: UInt8, data2: UInt8, channel: UInt8) {
        guard let track = project.tracks.first(where: { $0.id == trackID }), !track.isMuted else { return }
        switch status & 0xF0 {
        case 0x90 where data2 > 0:
            audioEngine.sendNoteOn(trackID: trackID, note: data1, velocity: data2, channel: channel)
        case 0x80, 0x90:
            audioEngine.sendNoteOff(trackID: trackID, note: data1, channel: channel)
        default:
            audioEngine.sendMIDI(trackID: trackID, status: status, data1: data1, data2: data2)
        }
    }
}
