import SwiftUI

/// Bridges SwiftUI drop events to the ``NotchViewModel``. The target zone is
/// captured synchronously at drop time (before the async item load) so it
/// survives the mouse-up that ends the drag. SwiftUI delivers drop callbacks on
/// the main thread, asserted via `MainActor.assumeIsolated`.
struct NotchDropDelegate: DropDelegate {
    let viewModel: NotchViewModel

    func performDrop(info: DropInfo) -> Bool {
        let providers = info.itemProviders(for: DropItemLoader.readableTypes)
        return MainActor.assumeIsolated {
            guard let zone = viewModel.pendingDropZone, !providers.isEmpty else { return false }
            DropItemLoader.load(from: providers) { items in
                viewModel.commitDrop(items: items, zone: zone)
            }
            return true
        }
    }
}
