import Foundation
import CoreMIDI
import Observation

@Observable
final class MIDIManager {
    private var client = MIDIClientRef()
    private var inputPort = MIDIPortRef()
    private(set) var isConnected = false
    var onMIDIEvent: ((UInt8, UInt8, UInt8, UInt8) -> Void)?

    func setup() {
        guard !isConnected else { return }
        let status = MIDIClientCreateWithBlock("Tracks MIDI Client" as CFString, &client) { _ in }
        guard status == noErr else { print("MIDI client error: \(status)"); return }

        let portStatus = MIDIInputPortCreateWithBlock(client, "Input" as CFString, &inputPort) { [weak self] eventList, _ in
            self?.handleMIDIEventList(eventList.pointee)
        }
        guard portStatus == noErr else { print("MIDI port error: \(portStatus)"); return }

        for i in 0..<MIDIGetNumberOfSources() {
            let src = MIDIGetSource(i)
            MIDIPortConnectSource(inputPort, src, nil)
        }
        isConnected = true
        print("MIDI ready: \(MIDIGetNumberOfSources()) sources")
    }

    private func handleMIDIEventList(_ eventList: MIDIEventList) {
        let count = Int(eventList.numPackets)
        let wordsOffset = MemoryLayout<MIDITimeStamp>.size + MemoryLayout<UInt32>.size
        withUnsafePointer(to: eventList.packet) { first in
            var ptr = UnsafeRawPointer(first)
            for _ in 0..<count {
                let packet = ptr.assumingMemoryBound(to: MIDIEventPacket.self).pointee
                if packet.wordCount > 0 {
                    let word = packet.words.0
                    let status = UInt8((word >> 24) & 0xFF)
                    let data1 = UInt8((word >> 16) & 0xFF)
                    let data2 = UInt8((word >> 8) & 0xFF)
                    let channel = status & 0x0F
                    let msgType = status & 0xF0
                    if msgType == 0x90 || msgType == 0x80 || msgType == 0xB0 || msgType == 0xC0 || msgType == 0xE0 {
                        DispatchQueue.main.async { [weak self] in
                            self?.onMIDIEvent?(status, data1, data2, channel)
                        }
                    }
                }
                let byteLen = wordsOffset + Int(packet.wordCount) * MemoryLayout<UInt32>.stride
                ptr = ptr + byteLen
            }
        }
    }

    deinit {
        if inputPort != 0 { MIDIPortDispose(inputPort) }
        if client != 0 { MIDIClientDispose(client) }
    }
}
