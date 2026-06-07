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
    let artwork: Data?
}
