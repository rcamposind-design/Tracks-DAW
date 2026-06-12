import AVFoundation
import AudioToolbox
import Observation

@Observable
final class AudioEngine {
    let engine = AVAudioEngine()
    private(set) var isRunning = false
    private var trackMixers: [UUID: AVAudioMixerNode] = [:]
    private(set) var trackAudioUnits: [UUID: AVAudioUnit] = [:]

    init() { configureSession() }

    private func configureSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setPreferredIOBufferDuration(0.005)
            try session.setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }
    }

    func start() throws {
        guard !isRunning else { return }
        engine.prepare()
        try engine.start()
        isRunning = true
    }

    func stop() {
        engine.stop()
        isRunning = false
    }

    func addTrack(_ track: Track) {
        let mixer = AVAudioMixerNode()
        mixer.volume = track.volume
        mixer.pan = track.pan
        engine.attach(mixer)
        engine.connect(mixer, to: engine.mainMixerNode, format: nil)
        trackMixers[track.id] = mixer
        guard let t = track.auType, let s = track.auSubType, let m = track.auManufacturer else { return }
        loadAU(trackID: track.id, type: t, subType: s, manufacturer: m)
    }

    func loadAU(trackID: UUID, type: UInt32, subType: UInt32, manufacturer: UInt32) {
        let desc = AudioComponentDescription(
            componentType: type,
            componentSubType: subType,
            componentManufacturer: manufacturer,
            componentFlags: 0,
            componentFlagsMask: 0
        )
        guard let au = try? AVAudioUnit(componentDescription: desc) else { return }
        engine.attach(au)
        if let mixer = trackMixers[trackID] {
            engine.disconnectNodeInput(mixer)
            engine.connect(au, to: mixer, format: nil)
        }
        trackAudioUnits[trackID] = au
    }

    func removeTrack(_ id: UUID) {
        if let au = trackAudioUnits.removeValue(forKey: id) { engine.detach(au) }
        if let mixer = trackMixers.removeValue(forKey: id) { engine.detach(mixer) }
    }

    func updateVolume(trackID: UUID, volume: Float) { trackMixers[trackID]?.volume = volume }
    func updatePan(trackID: UUID, pan: Float) { trackMixers[trackID]?.pan = pan }

    func sendMIDI(trackID: UUID, status: UInt8, data1: UInt8, data2: UInt8) {
        guard let au = trackAudioUnits[trackID] else { return }
        MusicDeviceMIDIEvent(au.audioUnit, UInt32(status), UInt32(data1), UInt32(data2), 0)
    }

    func sendNoteOn(trackID: UUID, note: UInt8, velocity: UInt8, channel: UInt8) {
        let st = UInt8(0x90) | (channel & 0x0F)
        sendMIDI(trackID: trackID, status: st, data1: note, data2: velocity)
    }

    func sendNoteOff(trackID: UUID, note: UInt8, channel: UInt8) {
        let st = UInt8(0x80) | (channel & 0x0F)
        sendMIDI(trackID: trackID, status: st, data1: note, data2: 0)
    }

    func allNotesOff() {
        for id in trackAudioUnits.keys {
            for ch in 0..<16 {
                let st = UInt8(0xB0) | UInt8(ch & 0x0F)
                sendMIDI(trackID: id, status: st, data1: 123, data2: 0)
            }
        }
    }
}
