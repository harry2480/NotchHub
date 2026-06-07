import ServiceManagement

/// Production ``LoginItemManaging`` backed by `SMAppService` (インフラストラクチャ規約.md).
final class SMAppServiceLoginItemManager: LoginItemManaging {
    private let service: SMAppService

    init(service: SMAppService = .mainApp) {
        self.service = service
    }

    var isEnabled: Bool {
        service.status == .enabled
    }

    func enable() throws {
        try service.register()
    }

    func disable() throws {
        try service.unregister()
    }
}
