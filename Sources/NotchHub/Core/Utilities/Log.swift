import os

/// Centralised `os.Logger` instances. Production code logs through these rather
/// than `print` (see スタイルガイド.md §5).
enum Log {
    private static let subsystem = "com.harry.notchhub"

    static let app = Logger(subsystem: subsystem, category: "app")
    static let database = Logger(subsystem: subsystem, category: "database")
    static let notch = Logger(subsystem: subsystem, category: "notch")
    static let shelf = Logger(subsystem: subsystem, category: "shelf")
}
