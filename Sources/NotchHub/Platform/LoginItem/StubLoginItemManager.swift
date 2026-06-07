/// In-memory ``LoginItemManaging`` for tests, previews and environments where
/// `SMAppService` is unavailable.
final class StubLoginItemManager: LoginItemManaging {
    private(set) var isEnabled: Bool

    init(isEnabled: Bool = false) {
        self.isEnabled = isEnabled
    }

    func enable() throws {
        isEnabled = true
    }

    func disable() throws {
        isEnabled = false
    }
}
