import SwiftUI

struct MixerView: View {
    @Environment(Project.self) private var project
    @Environment(AudioEngine.self) private var audioEngine

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(project.tracks) { track in
                    MixerChannelView(trackID: track.id)
                }
            }
            .padding()
        }
        .overlay {
            if project.tracks.isEmpty { ContentUnavailableView("No Tracks", systemImage: "slider.vertical.3") }
        }
    }
}

struct MixerChannelView: View {
    @Environment(Project.self) private var project
    @Environment(AudioEngine.self) private var audioEngine
    let trackID: UUID
    private var track: Track? { project.tracks.first { $0.id == trackID } }

    var body: some View {
        if let t = track {
            VStack(spacing: 4) {
                Text(t.name).font(.caption2).fontWeight(.medium)
                MuteSoloView(trackID: trackID)
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 4).fill(Color(.systemGray5)).frame(width: 32, height: 140)
                    RoundedRectangle(cornerRadius: 4).fill(t.color.opacity(0.7))
                        .frame(width: 32, height: CGFloat(t.volume) * 140)
                        .animation(.spring(response: 0.3), value: t.volume)
                }
                .gesture(DragGesture(minimumDistance: 0).onChanged { v in
                    let h = max(0, min(1, Float((140 - v.location.y) / 140)))
                    audioEngine.updateVolume(trackID: trackID, volume: h)
                    if let i = project.tracks.firstIndex(where: { $0.id == trackID }) { project.tracks[i].volume = h }
                })
                Text("\(Int(t.volume * 100))%").font(.system(size: 9)).monospacedDigit()
                HStack(spacing: 2) {
                    Slider(value: Binding(
                        get: { t.pan }, set: {
                            audioEngine.updatePan(trackID: trackID, pan: $0)
                            if let i = project.tracks.firstIndex(where: { $0.id == trackID }) { project.tracks[i].pan = $0 }
                        }), in: -1...1).frame(width: 50)
                }
                Text(panLabel(t.pan)).font(.system(size: 8)).foregroundStyle(.secondary)
            }
            .frame(width: 64)
            .padding(4)
            .background(Color(.systemGray6))
            .cornerRadius(6)
        }
    }

    private func panLabel(_ p: Float) -> String {
        p < -0.05 ? "L\(Int(abs(p)*100))" : p > 0.05 ? "R\(Int(p*100))" : "C"
    }
}
