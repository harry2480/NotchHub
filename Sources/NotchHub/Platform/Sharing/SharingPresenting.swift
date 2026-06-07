import Foundation

/// Presents the macOS Share Sheet / AirDrop, hiding `NSSharingService(Picker)`
/// behind a protocol (AGENTS.md: OS API は Platform 層に隠蔽). AirDrop reports
/// its outcome so history can be recorded (要件定義.md §10.5).
protocol SharingPresenting {
    func presentShareSheet(for urls: [URL])
    func presentAirDrop(for urls: [URL], completion: @escaping (ShareOutcome) -> Void)
}
