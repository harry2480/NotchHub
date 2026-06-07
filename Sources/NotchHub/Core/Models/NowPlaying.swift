import Foundation

/// Currently playing track (要件定義.md §18.1). Carries no AppleScript types.
struct NowPlaying: Equatable {
    enum Source: String, Equatable {
        case appleMusic
        case spotify
    }

    let source: Source
    let title: String
    let artist: String
    let isPlaying: Bool
    /// Elapsed playback position, in seconds.
    let position: Double
    /// Track length, in seconds (0 when unknown).
    let duration: Double
    /// Player output volume, 0–100.
    let volume: Int
    var artwork: Data?

    init(
        source: Source,
        title: String,
        artist: String,
        isPlaying: Bool,
        position: Double = 0,
        duration: Double = 0,
        volume: Int = 0,
        artwork: Data? = nil
    ) {
        self.source = source
        self.title = title
        self.artist = artist
        self.isPlaying = isPlaying
        self.position = position
        self.duration = duration
        self.volume = volume
        self.artwork = artwork
    }

    /// Stable identity for the current track, used to avoid re-fetching artwork
    /// while the same song keeps playing.
    var identityKey: String {
        "\(source.rawValue)|\(title)|\(artist)"
    }
}
