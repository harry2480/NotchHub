import SwiftUI

/// The Media tab: artwork, title/artist, transport controls plus a seek bar and
/// a volume slider (要件定義.md §18.1–18.2 + user-requested controls).
struct MediaControlView: View {
    @Bindable var viewModel: MediaViewModel

    var body: some View {
        Group {
            if let track = viewModel.nowPlaying {
                content(track)
            } else {
                emptyState
            }
        }
        .onAppear { viewModel.startPolling() }
        .onDisappear { viewModel.stopPolling() }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "music.note")
                .font(.system(size: 26))
                .foregroundStyle(.secondary)
            Text("Apple Music / Spotify が再生されていません")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Apple Music を開く") { viewModel.openDefaultPlayer() }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
        }
        .padding(NotchStyle.contentPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func content(_ track: NowPlaying) -> some View {
        VStack(spacing: 12) {
            artwork
            VStack(spacing: 2) {
                Text(track.title)
                    .font(.headline)
                    .lineLimit(1)
                Text(track.artist)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            progress
            controls(track)
            volume
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(NotchStyle.contentPadding)
    }

    @ViewBuilder
    private var artwork: some View {
        if let data = viewModel.artwork, let image = NSImage(data: data) {
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

    // MARK: - Seek bar

    private var progress: some View {
        VStack(spacing: 2) {
            Slider(
                value: $viewModel.position,
                in: 0 ... max(viewModel.duration, 1),
                onEditingChanged: viewModel.seekEditingChanged
            )
            .controlSize(.mini)
            .disabled(viewModel.duration <= 0)
            HStack {
                Text(Self.timeString(viewModel.position))
                Spacer()
                Text(Self.timeString(viewModel.duration))
            }
            .font(.caption2.monospacedDigit())
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Volume

    private var volume: some View {
        HStack(spacing: 8) {
            Image(systemName: "speaker.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
            Slider(
                value: $viewModel.volume,
                in: 0 ... 100,
                onEditingChanged: viewModel.volumeEditingChanged
            )
            .controlSize(.mini)
            Image(systemName: "speaker.wave.3.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
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

    /// Formats seconds as `m:ss` (clamped at 0).
    static func timeString(_ seconds: Double) -> String {
        let total = Int(max(0, seconds).rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
