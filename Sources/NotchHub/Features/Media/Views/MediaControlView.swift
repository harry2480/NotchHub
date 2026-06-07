import SwiftUI

/// The Media tab: artwork, title/artist and Play/Pause / Next / Previous
/// (要件定義.md §18.1–18.2).
struct MediaControlView: View {
    let viewModel: MediaViewModel

    var body: some View {
        Group {
            if let track = viewModel.nowPlaying {
                content(track)
            } else {
                VStack(spacing: 6) {
                    Image(systemName: "music.note")
                        .font(.system(size: 26))
                        .foregroundStyle(.secondary)
                    Text("Nothing playing")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear { viewModel.refresh() }
    }

    private func content(_ track: NowPlaying) -> some View {
        VStack(spacing: 12) {
            artwork(track)
            VStack(spacing: 2) {
                Text(track.title)
                    .font(.headline)
                    .lineLimit(1)
                Text(track.artist)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            controls(track)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(NotchStyle.contentPadding)
    }

    @ViewBuilder
    private func artwork(_ track: NowPlaying) -> some View {
        if let data = track.artwork, let image = NSImage(data: data) {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 96, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.secondary.opacity(0.15))
                .frame(width: 96, height: 96)
                .overlay(Image(systemName: "music.note").foregroundStyle(.secondary))
        }
    }

    private func controls(_ track: NowPlaying) -> some View {
        HStack(spacing: 28) {
            button("backward.fill", action: viewModel.previous)
            button(track.isPlaying ? "pause.fill" : "play.fill", action: viewModel.playPause)
            button("forward.fill", action: viewModel.next)
        }
    }

    private func button(_ systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18))
        }
        .buttonStyle(.borderless)
    }
}
