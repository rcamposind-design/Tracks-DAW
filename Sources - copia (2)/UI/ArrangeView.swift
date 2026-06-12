import SwiftUI

struct ArrangeView: View {
    @Environment(Project.self) private var project

    var body: some View {
        List {
            ForEach(project.tracks) { track in
                TrackRowView(trackID: track.id)
            }
            .onDelete { idx in
                for i in idx { project.removeTrack(project.tracks[i].id) }
            }
        }
        .listStyle(.plain)
        .overlay {
            if project.tracks.isEmpty {
                ContentUnavailableView("No Tracks", systemImage: "music.note")
            }
        }
    }
}

struct TrackRowView: View {
    @Environment(Project.self) private var project
    @Environment(AudioEngine.self) private var audioEngine
    let trackID: UUID
    private var track: Track? { project.tracks.first { $0.id == trackID } }

    var body: some View {
        if let t = track {
            HStack(spacing: 8) {
                Circle().fill(t.color).frame(width: 10, height: 10)
                VStack(alignment: .leading) {
                    Text(t.name).fontWeight(.medium).font(.caption)
                    if let name = t.auComponentName { Text(name).font(.caption2).foregroundStyle(.secondary) }
                    else { Text("No instrument").font(.caption2).foregroundStyle(.tertiary) }
                }
                Spacer()
                Button("AU") { showAUSelector() }.buttonStyle(.bordered).controlSize(.small)
                VolumeSlider(value: Binding(
                    get: { t.volume },
                    set: { audioEngine.updateVolume(trackID: trackID, volume: $0) }
                )).frame(width: 80)
                MuteSoloView(trackID: trackID)
            }
            .padding(.vertical, 2)
        }
    }

    private func showAUSelector() {
        guard let t = track else { return }
        let vc = UIHostingController(rootView: AUSelectorView(track: t))
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(vc, animated: true)
        }
    }
}

struct VolumeSlider: View {
    @Binding var value: Float
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "speaker.fill").font(.caption2).foregroundStyle(.secondary)
            Slider(value: $value, in: 0...1)
            Image(systemName: "speaker.wave.3.fill").font(.caption2).foregroundStyle(.secondary)
        }
    }
}

struct MuteSoloView: View {
    @Environment(Project.self) private var project
    let trackID: UUID
    private var track: Track? { project.tracks.first { $0.id == trackID } }

    var body: some View {
        HStack(spacing: 2) {
            Button("M") {
                if let i = project.tracks.firstIndex(where: { $0.id == trackID }) { project.tracks[i].isMuted.toggle() }
            }.buttonStyle(.bordered).controlSize(.small).tint(track?.isMuted == true ? .red : nil)
            Button("S") {
                if let i = project.tracks.firstIndex(where: { $0.id == trackID }) { project.tracks[i].isSoloed.toggle() }
            }.buttonStyle(.bordered).controlSize(.small).tint(track?.isSoloed == true ? .yellow : nil)
        }
    }
}
