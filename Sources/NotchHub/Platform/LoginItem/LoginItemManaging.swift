/// Abstraction over "Launch at Login" so the OS API (`SMAppService`) stays
/// behind a protocol that can be stubbed in tests and previews (AGENTS.md:
/// "OS API は Platform 層に隠蔽する").
protocol LoginItemManaging {
    /// Whether the app is currently registered to launch at login.
    var isEnabled: Bool { get }
    func enable() throws
    func disable() throws
}
