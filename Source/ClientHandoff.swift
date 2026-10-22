import AppKit

/// Launch Services must receive an open/reopen request, even for a running client.
/// Keep the launcher alive until the resulting app is frontmost with a visible window.
final class ClientHandoff {
    private var timer: Timer?
    private var application: NSRunningApplication?
    private var completion: ((Result<NSRunningApplication, Error>) -> Void)?
    private var started = Date()
    private var attempts = 0
    private var lastError: Error?
    private var lastRequest = Date.distantPast
    private var target: URL?
    private let timeout: TimeInterval
    private let logger: (String) -> Void
    private var lastState = ""

    init(timeout: TimeInterval = 15, logger: @escaping (String) -> Void = { print($0); fflush(stdout) }) { self.timeout = timeout; self.logger = logger }

    static func hasVisibleWindow(_ pid: pid_t) -> Bool {
        let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
        return windows.contains { window in
            guard (window[kCGWindowOwnerPID as String] as? Int32) == pid,
                  (window[kCGWindowLayer as String] as? Int) == 0,
                  let bounds = window[kCGWindowBounds as String] as? [String: Any],
                  let width = bounds["Width"] as? Double,
                  let height = bounds["Height"] as? Double else { return false }
            return width > 120 && height > 80
        }
    }

    func open(_ url: URL, completion: @escaping (Result<NSRunningApplication, Error>) -> Void) {
        precondition(Thread.isMainThread)
        guard self.completion == nil else { return }
        target = url; self.completion = completion; started = Date(); attempts = 0
        application = nil; lastError = nil; lastRequest = .distantPast
        requestOpen()
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in self?.check() }
    }

    private func requestOpen() {
        guard let target, completion != nil else { return }
        attempts += 1; lastRequest = Date()
        logger("OPEN request attempt=\(attempts) url=\(target.path)")
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        config.hides = false
        config.createsNewApplicationInstance = false
        NSWorkspace.shared.openApplication(at: target, configuration: config) { [weak self] app, error in
            DispatchQueue.main.async {
                guard let self, self.completion != nil else { return }
                self.lastError = error
                self.logger("OPEN callback pid=\(app?.processIdentifier ?? 0) error=\(error?.localizedDescription ?? "none")")
                if let app, !app.isTerminated {
                    self.application = app
                    app.unhide()
                }
                self.check()
            }
        }
    }

    private func check() {
        guard completion != nil else { return }
        let state = "pid=\(application?.processIdentifier ?? 0) terminated=\(application?.isTerminated ?? true) finished=\(application?.isFinishedLaunching ?? false) frontmost=\(NSWorkspace.shared.frontmostApplication?.processIdentifier ?? 0) visible=\(application.map { Self.hasVisibleWindow($0.processIdentifier) } ?? false)"
        if state != lastState { lastState = state; logger("OPEN state \(state)") }
        if let app = application, !app.isTerminated,
           app.isFinishedLaunching,
           NSWorkspace.shared.frontmostApplication?.processIdentifier == app.processIdentifier,
           Self.hasVisibleWindow(app.processIdentifier) {
            resolve(.success(app)); return
        }
        if Date().timeIntervalSince(started) >= timeout {
            let error = lastError ?? NSError(domain: "CodexMoonrise.Handoff", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "未能确认 Codex 窗口已打开。客户端可能仍在退出、启动或等待确认；请处理后重试。"])
            resolve(.failure(error)); return
        }
        if attempts < 3 && Date().timeIntervalSince(lastRequest) >= 3 { requestOpen() }
    }

    private func resolve(_ result: Result<NSRunningApplication, Error>) {
        timer?.invalidate(); timer = nil
        let callback = completion; completion = nil
        callback?(result)
    }
}
