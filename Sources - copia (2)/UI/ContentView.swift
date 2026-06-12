import SwiftUI

struct ContentView: View {
    @Environment(Project.self) private var project
    @Environment(Transport.self) private var transport
    @Environment(AudioEngine.self) private var audioEngine
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            TransportBar().padding(.horizontal).padding(.vertical, 6)
                .background(Color(.systemGray6))
            TabView(selection: $selectedTab) {
                ArrangeView().tabItem { Label("Arrange", systemImage: "music.note.list") }.tag(0)
                MixerView().tabItem { Label("Mixer", systemImage: "slider.vertical.3") }.tag(1)
                RoutingView().tabItem { Label("Routing", systemImage: "arrow.triangle.branch") }.tag(2)
            }
            .toolbar {
                ToolbarItem(placement: .principal) { Text(project.name).fontWeight(.semibold) }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("+ Track") { addTrack() }
                }
            }
        }
    }

    private func addTrack() {
        let n = project.tracks.count + 1
        let track = Track(name: "Track \(n)")
        project.addTrack(track)
        audioEngine.addTrack(track)
    }
}

struct TransportBar: View {
    @Environment(Transport.self) private var transport
    @Environment(Project.self) private var project

    var body: some View {
        HStack(spacing: 12) {
            Button(action: { transport.togglePlay() }) {
                Image(systemName: transport.isPlaying ? "stop.fill" : "play.fill")
                    .font(.title2)
            }
            .buttonStyle(.borderedProminent)
            Text("\(Int(project.tempo)) BPM").font(.caption).monospacedDigit()
            Spacer()
            Text(transport.isPlaying ? "Playing" : "Stopped")
                .font(.caption).foregroundStyle(transport.isPlaying ? .green : .secondary)
        }
    }
}
