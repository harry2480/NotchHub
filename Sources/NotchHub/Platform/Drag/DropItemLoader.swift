import Foundation
import UniformTypeIdentifiers

/// Converts dropped `NSItemProvider`s into domain ``DroppedItem``s. File URLs
/// are preferred (the Shelf turns them into security-scoped bookmarks later);
/// otherwise inline URLs / text are captured. Loading is asynchronous, so the
/// completion is delivered on the main actor once every provider resolves.
enum DropItemLoader {
    static let readableTypes: [UTType] = [.fileURL, .url, .plainText, .text]

    static func load(
        from providers: [NSItemProvider],
        completion: @escaping @MainActor ([DroppedItem]) -> Void
    ) {
        let group = DispatchGroup()
        let lock = NSLock()
        var items: [DroppedItem] = []

        func append(_ item: DroppedItem?) {
            guard let item else { return }
            lock.lock()
            items.append(item)
            lock.unlock()
        }

        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                group.enter()
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    append(url.map(DroppedItem.fileURL))
                    group.leave()
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                group.enter()
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    append(url.map(DroppedItem.url))
                    group.leave()
                }
            } else if provider.canLoadObject(ofClass: String.self) {
                group.enter()
                _ = provider.loadObject(ofClass: String.self) { text, _ in
                    append(text.map(DroppedItem.text))
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            let resolved = items
            MainActor.assumeIsolated {
                completion(resolved)
            }
        }
    }
}
