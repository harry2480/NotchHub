import Foundation

/// Production ``AISocketServing`` over a Unix domain socket (実装計画.md §2.3).
///
/// CLI hooks connect and write newline-delimited JSON ``AIEvent``s; approval
/// decisions are written back on the same connection that raised the
/// `permissionRequest`. All socket work runs on a private serial queue; decoded
/// events are delivered on the main thread.
final class UnixSocketAIServer: AISocketServing {
    var onEvent: ((AIEvent) -> Void)?

    private let socketPath: String
    private let queue = DispatchQueue(label: "com.harry.notchhub.aisocket")
    private let decoder = JSONDecoder()

    private var listenFD: Int32 = -1
    private var listenSource: DispatchSourceRead?
    private var clientSources: [Int32: DispatchSourceRead] = [:]
    private var buffers: [Int32: Data] = [:]
    private var clientByRequestId: [String: Int32] = [:]

    init(socketPath: String) {
        self.socketPath = socketPath
    }

    /// Socket at `~/Library/Application Support/NotchHub/notchhub.sock`.
    static func standard() throws -> UnixSocketAIServer {
        let url = try AppPaths.applicationSupportDirectory().appendingPathComponent("notchhub.sock", isDirectory: false)
        return UnixSocketAIServer(socketPath: url.path)
    }

    func start() {
        queue.async { [weak self] in self?.bindAndListen() }
    }

    func stop() {
        queue.async { [weak self] in
            guard let self else { return }
            listenSource?.cancel()
            listenSource = nil
            clientSources.values.forEach { $0.cancel() }
            unlink(socketPath)
        }
    }

    func respond(requestId: String, decision: ApprovalDecision) {
        queue.async { [weak self] in
            guard let self, let fd = clientByRequestId[requestId] else { return }
            let payload: [String: String] = ["requestId": requestId, "decision": decision.rawValue]
            if var data = try? JSONSerialization.data(withJSONObject: payload) {
                data.append(0x0A)
                data.withUnsafeBytes { _ = write(fd, $0.baseAddress, $0.count) }
            }
            clientByRequestId[requestId] = nil
        }
    }

    // MARK: - Socket setup

    private func bindAndListen() {
        unlink(socketPath)
        listenFD = socket(AF_UNIX, SOCK_STREAM, 0)
        guard listenFD >= 0 else {
            Log.app.error("AI socket: create failed")
            return
        }

        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        let pathBytes = socketPath.utf8CString
        let capacity = MemoryLayout.size(ofValue: addr.sun_path)
        withUnsafeMutablePointer(to: &addr.sun_path) { rawPtr in
            rawPtr.withMemoryRebound(to: CChar.self, capacity: capacity) { dest in
                pathBytes.withUnsafeBufferPointer { src in
                    guard let base = src.baseAddress else { return }
                    dest.update(from: base, count: min(src.count, capacity - 1))
                }
            }
        }

        let size = socklen_t(MemoryLayout<sockaddr_un>.size)
        let bound = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { bind(listenFD, $0, size) }
        }
        guard bound == 0, listen(listenFD, 8) == 0 else {
            Log.app.error("AI socket: bind/listen failed")
            close(listenFD)
            listenFD = -1
            return
        }

        let source = DispatchSource.makeReadSource(fileDescriptor: listenFD, queue: queue)
        source.setEventHandler { [weak self] in self?.acceptClient() }
        source.setCancelHandler { [weak self] in
            if let fd = self?.listenFD, fd >= 0 { close(fd) }
            self?.listenFD = -1
        }
        listenSource = source
        source.resume()
    }

    private func acceptClient() {
        let clientFD = accept(listenFD, nil, nil)
        guard clientFD >= 0 else { return }
        buffers[clientFD] = Data()
        let source = DispatchSource.makeReadSource(fileDescriptor: clientFD, queue: queue)
        source.setEventHandler { [weak self] in self?.readAvailable(clientFD) }
        source.setCancelHandler { [weak self] in
            close(clientFD)
            self?.buffers[clientFD] = nil
            self?.clientSources[clientFD] = nil
            // Drop any pending request → fd mappings for this client so a later
            // respond() can't write to a closed (or OS-reused) descriptor.
            self?.clientByRequestId = self?.clientByRequestId.filter { $0.value != clientFD } ?? [:]
        }
        clientSources[clientFD] = source
        source.resume()
    }

    private func readAvailable(_ fd: Int32) {
        var chunk = [UInt8](repeating: 0, count: 4096)
        let count = read(fd, &chunk, chunk.count)
        guard count > 0 else {
            clientSources[fd]?.cancel()
            return
        }
        buffers[fd, default: Data()].append(contentsOf: chunk[0 ..< count])
        drainLines(fd)
    }

    private func drainLines(_ fd: Int32) {
        while let buffer = buffers[fd], let newline = buffer.firstIndex(of: 0x0A) {
            let line = buffer.subdata(in: buffer.startIndex ..< newline)
            buffers[fd]?.removeSubrange(buffer.startIndex ... newline)
            guard let event = try? decoder.decode(AIEvent.self, from: line) else { continue }
            if event.type == .permissionRequest, let requestId = event.requestId {
                clientByRequestId[requestId] = fd
            }
            DispatchQueue.main.async { [weak self] in self?.onEvent?(event) }
        }
    }
}
