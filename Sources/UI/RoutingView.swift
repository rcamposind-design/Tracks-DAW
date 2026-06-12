import SwiftUI

struct RoutingView: View {
    @Environment(Project.self) private var project
    @Environment(MIDIRouter.self) private var midiRouter

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("MIDI Routing Matrix").font(.title2).fontWeight(.semibold)
            Text("Rows = MIDI source, Columns = track destination").font(.caption).foregroundStyle(.secondary)
            if project.tracks.isEmpty {
                Spacer(); ContentUnavailableView("No tracks", systemImage: "arrow.triangle.branch"); Spacer()
            } else {
                ScrollView([.horizontal, .vertical]) {
                    Grid(horizontalSpacing: 1, verticalSpacing: 1) {
                        GridRow {
                            Text("Source \\ Dest").font(.caption2).frame(width: 80, alignment: .leading)
                            ForEach(project.tracks) { dest in
                                Text(dest.name).font(.caption2).lineLimit(1).frame(width: 60).foregroundStyle(dest.color)
                            }
                        }
                        ForEach(0..<17) { ch in
                            let source = MIDISource.midiInput(channel: ch)
                            GridRow {
                                Text(sourceLabel(ch)).font(.caption2).frame(width: 80, alignment: .leading)
                                ForEach(project.tracks) { dest in
                                    Toggle("", isOn: Binding(
                                        get: { project.isConnected(source: source, dest: dest.id) },
                                        set: { _ in project.toggleConnection(source: source, dest: dest.id) }
                                    )).toggleStyle(.button).controlSize(.mini)
                                }
                            }
                        }
                        Divider().gridCellUnsizedAxes(.horizontal)
                        ForEach(project.tracks) { srcTrack in
                            let source = MIDISource.track(srcTrack.id)
                            GridRow {
                                HStack {
                                    Circle().fill(srcTrack.color).frame(width: 6, height: 6)
                                    Text(srcTrack.name).font(.caption2)
                                }.frame(width: 80, alignment: .leading)
                                ForEach(project.tracks) { dest in
                                    if dest.id == srcTrack.id {
                                        Color.clear.frame(width: 20, height: 20)
                                    } else {
                                        Toggle("", isOn: Binding(
                                            get: { project.isConnected(source: source, dest: dest.id) },
                                            set: { _ in project.toggleConnection(source: source, dest: dest.id) }
                                        )).toggleStyle(.button).controlSize(.mini)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .padding()
        .onChange(of: project.connections, initial: true) { _, new in midiRouter.updateConnections(new) }
    }

    private func sourceLabel(_ ch: Int) -> String { ch == 0 ? "MIDI All" : "MIDI Ch.\(ch)" }
}
