import SwiftUI
import AVFoundation

struct AUSelectorView: View {
    @Environment(Project.self) private var project
    @Environment(AudioEngine.self) private var audioEngine
    @Environment(\.dismiss) private var dismiss
    let track: Track
    @State private var components: [AVAudioUnitComponent] = []

    var body: some View {
        NavigationStack {
            List(components, id: \.name) { comp in
                Button {
                    assign(comp)
                    dismiss()
                } label: {
                    VStack(alignment: .leading) {
                        Text(comp.name).fontWeight(.medium)
                        Text(comp.manufacturerName).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Select Instrument")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("None") { clearInstr(); dismiss() }
                }
            }
            .overlay {
                if components.isEmpty {
                    ContentUnavailableView("No Instruments Found", systemImage: "rectangle.3.group",
                        description: Text("Install AUv3 instruments from the App Store"))
                }
            }
        }
        .task { loadComps() }
    }

    private func loadComps() {
        let desc = AudioComponentDescription(
            componentType: kAudioUnitType_MusicDevice, componentSubType: 0,
            componentManufacturer: 0, componentFlags: 0, componentFlagsMask: 0)
        components = AVAudioUnitComponentManager.shared.components(matching: desc).sorted { $0.name < $1.name }
    }

    private func assign(_ comp: AVAudioUnitComponent) {
        guard let i = project.tracks.firstIndex(where: { $0.id == track.id }) else { return }
        let d = comp.audioComponentDescription
        project.tracks[i].auType = d.componentType
        project.tracks[i].auSubType = d.componentSubType
        project.tracks[i].auManufacturer = d.componentManufacturer
        project.tracks[i].auComponentName = comp.name
        audioEngine.loadAU(trackID: track.id, type: d.componentType, subType: d.componentSubType, manufacturer: d.componentManufacturer)
    }

    private func clearInstr() {
        guard let i = project.tracks.firstIndex(where: { $0.id == track.id }) else { return }
        project.tracks[i].auType = nil; project.tracks[i].auSubType = nil
        project.tracks[i].auManufacturer = nil; project.tracks[i].auComponentName = nil
        audioEngine.removeTrack(track.id); audioEngine.addTrack(project.tracks[i])
    }
}
