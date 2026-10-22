import AppKit
import WebKit

let args = CommandLine.arguments
let snapshotMode = args.contains("--snapshot")
let verifyMode = args.contains("--verify") || args.contains("--verify-skip")
let previewMode = args.contains("--preview") || snapshotMode || verifyMode || args.contains("--verify-palette") || args.contains("--verify-native-skip")
func argument(_ key: String) -> String? { guard let i = args.firstIndex(of: key), args.count > i+1 else { return nil }; return args[i+1] }
func log(_ message: String) {
    let line = "\(ISO8601DateFormatter().string(from: Date())) MOONRISE \(message)\n"
    print(line, terminator: ""); fflush(stdout)
    guard !previewMode else { return }
    let directory = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Logs/CodexMoonrise")
    let url = directory.appendingPathComponent("launcher.log")
    do {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        if !FileManager.default.fileExists(atPath: url.path) || size > 524288 { try Data().write(to: url) }
        let handle = try FileHandle(forWritingTo: url); defer { try? handle.close() }
        try handle.seekToEnd(); try handle.write(contentsOf: Data(line.utf8))
    } catch { /* Diagnostics must not prevent launching the client. */ }
}

final class OverlayWindow: NSWindow { override var canBecomeKey: Bool { true } }

final class Launcher: NSObject, NSApplicationDelegate, WKNavigationDelegate, WKScriptMessageHandler {
    var window: NSWindow!
    var web: WKWebView!
    let handoff = ClientHandoff(logger: log)
    var ended = false
    var messages = 0
    var keyMonitor: Any?
    var watchdog: Timer?
    func applicationDidFinishLaunching(_ notification: Notification) {
        log("DID_FINISH begin")
        if !previewMode && NSRunningApplication.runningApplications(withBundleIdentifier: "local.codex.moonrise").filter({ $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }).count > 0 { NSApp.terminate(nil); return }
        let screen = NSScreen.screens.first(where: { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) }) ?? NSScreen.main!
        let rect = previewMode ? NSRect(x: screen.frame.midX-600, y: screen.frame.midY-390, width: 1200, height: 780) : screen.frame
        window = OverlayWindow(contentRect: rect, styleMask: [.borderless], backing: .buffered, defer: false)
        window.backgroundColor = NSColor(calibratedRed: 0.031, green: 0.043, blue: 0.071, alpha: 1)
        window.isReleasedWhenClosed = false
        window.level = previewMode ? .normal : .statusBar
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        let config = WKWebViewConfiguration()
        config.userContentController.add(self, name: "boot")
        let palette = UserDefaults.standard.string(forKey: "palette") ?? "silver"
        let safePalette = ["silver", "amber", "violet"].contains(palette) ? palette : "silver"
        config.userContentController.addUserScript(WKUserScript(source: "window.MOONRISE_PALETTE='\(safePalette)';", injectionTime: .atDocumentStart, forMainFrameOnly: true))
        if snapshotMode { let t = Double(argument("--time") ?? "3.8") ?? 3.8; config.userContentController.addUserScript(WKUserScript(source: "window.MOONRISE_FRAME=\(t);", injectionTime: .atDocumentStart, forMainFrameOnly: true)) }
        web = WKWebView(frame: NSRect(origin: .zero, size: rect.size), configuration: config)
        web.navigationDelegate = self
        window.contentView = web
        log("WINDOW ready"); window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { self?.finish("escape"); return nil }; return event
        }
        guard let resource = Bundle.main.resourceURL?.appendingPathComponent("index.html"), FileManager.default.fileExists(atPath: resource.path) else { fail("找不到本地动画资源。"); return }
        watchdog = Timer.scheduledTimer(withTimeInterval: 22, repeats: false) { [weak self] _ in self?.finish("watchdog") }
        web.loadFileURL(resource, allowingReadAccessTo: resource.deletingLastPathComponent())
        log("START mode=\(previewMode ? "preview" : "launch")")
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        log("WEB loaded")
        if snapshotMode {
            DispatchQueue.main.asyncAfter(deadline: .now()+0.8) { [weak self] in self?.snapshot() }
        } else if args.contains("--verify-palette") {
            let before = UserDefaults.standard.string(forKey: "palette")
            web.evaluateJavaScript("setPalette('violet'); window.bootState.palette") { result, error in
                let pass = error == nil && result as? String == "violet" && UserDefaults.standard.string(forKey: "palette") == "violet"
                log("VERIFY PALETTE \(pass ? "PASS" : "FAIL")")
                if let before { UserDefaults.standard.set(before, forKey: "palette") } else { UserDefaults.standard.removeObject(forKey: "palette") }
                if !pass { exit(1) }; NSApp.terminate(nil)
            }
        } else if args.contains("--verify-native-skip") {
            DispatchQueue.main.asyncAfter(deadline: .now()+0.8) {
                if let event = NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0, windowNumber: self.window.windowNumber, context: nil, characters: "\u{1b}", charactersIgnoringModifiers: "\u{1b}", isARepeat: false, keyCode: 53) { NSApp.postEvent(event, atStart: true) }
            }
        } else if args.contains("--verify-skip") {
            DispatchQueue.main.asyncAfter(deadline: .now()+0.8) { [weak self] in
                self?.web.evaluateJavaScript("window.dispatchEvent(new KeyboardEvent('keydown',{key:'Escape'}))")
            }
        }
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { fail(error.localizedDescription) }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { fail(error.localizedDescription) }
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) { finish("web-process-exit") }
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let reason = message.body as? String else { return }
        if reason.hasPrefix("palette:") {
            let value = String(reason.dropFirst(8))
            if ["silver", "amber", "violet"].contains(value) { UserDefaults.standard.set(value, forKey: "palette"); log("PALETTE saved=\(value)") }
            return
        }
        guard ["complete", "skip"].contains(reason) else { return }
        messages += 1
        if verifyMode {
            web.evaluateJavaScript("complete(); JSON.stringify(window.bootState)") { [weak self] result, error in
                guard let self else { return }
                let expected = args.contains("--verify-skip") ? "skip" : "complete"
                let json = (result as? String)?.data(using: .utf8)
                let state = json.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
                let durationOK = expected == "skip" || (state?["time"] as? Double ?? 0) >= 14
                let pass = error == nil && self.messages == 1 && reason == expected && durationOK && (state?["errors"] as? [String] ?? []).isEmpty
                log("VERIFY \(pass ? "PASS" : "FAIL") messages=\(self.messages) state=\(result ?? "nil")")
                self.watchdog?.invalidate(); if !pass { exit(1) }; NSApp.terminate(nil)
            }
        } else { finish(reason) }
    }
    func snapshot() {
        let config = WKSnapshotConfiguration(); config.rect = web.bounds
        web.takeSnapshot(with: config) { image, error in
            guard let image, let data = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data: data), let png = bitmap.representation(using: .png, properties: [:]), let path = argument("--snapshot") else { log("SNAPSHOT FAIL \(String(describing: error))"); NSApp.terminate(nil); return }
            do { try png.write(to: URL(fileURLWithPath: path)); log("SNAPSHOT \(path)") } catch { log("SNAPSHOT FAIL \(error)") }
            NSApp.terminate(nil)
        }
    }
    func fail(_ message: String) {
        log("ERROR \(message)"); ended = true; watchdog?.invalidate(); window?.orderOut(nil)
        let alert = NSAlert(); alert.messageText = "Codex Moonrise"; alert.informativeText = message; alert.runModal(); NSApp.terminate(nil)
    }
    func finish(_ reason: String) {
        guard !ended else { return }; ended = true; watchdog?.invalidate()
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        log("HANDOFF requested reason=\(reason)")
        if verifyMode || args.contains("--verify-palette") { log("VERIFY FAIL unexpected finish=\(reason)"); exit(1) }
        if args.contains("--verify-native-skip") {
            let pass = reason == "escape"; log("VERIFY NATIVE ESC \(pass ? "PASS" : "FAIL")"); if !pass { exit(1) }
        }
        do {
            window.orderOut(nil)
            if previewMode { NSApp.terminate(nil); return }
            guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.openai.codex") else {
                fail("未找到 Codex（com.openai.codex）。请先安装客户端。"); return
            }
            log("HANDOFF opening url=\(url.path)")
            handoff.open(url) { [self] result in
                switch result {
                case .success(let app):
                    log("HANDOFF confirmed pid=\(app.processIdentifier) frontmost=true visible-window=true")
                    NSApp.terminate(nil)
                case .failure(let error):
                    fail("Codex 交接失败：\(error.localizedDescription)")
                }
            }
        }
    }
}
let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let launcher = Launcher()
app.delegate = launcher
withExtendedLifetime(launcher) { app.run() }
