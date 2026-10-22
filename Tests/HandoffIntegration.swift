import AppKit

@main struct HandoffIntegration {
    static var handoff = ClientHandoff(timeout: 12)
    static var client: NSRunningApplication?
    static var code: Int32 = 1
    static func main() {
        let url = URL(fileURLWithPath: CommandLine.arguments[1])
        let scenario = CommandLine.arguments[2]
        if scenario == "cold" || scenario == "missing" { run(scenario == "missing" ? url.appendingPathComponent("Missing.app") : url, scenario) }
        else {
            let config = NSWorkspace.OpenConfiguration()
            config.activates = false; config.arguments = ["--without-window"]
            NSWorkspace.shared.openApplication(at: url, configuration: config) { app, error in
                client = app
                DispatchQueue.main.asyncAfter(deadline: .now()+1) {
                    guard let app, error == nil else { finish(false, "fixture launch failed"); return }
                    if scenario == "stale" {
                        app.terminate()
                        waitForTermination(app, url, scenario)
                    } else {
                        guard !ClientHandoff.hasVisibleWindow(app.processIdentifier) else { finish(false, "fixture unexpectedly visible"); return }
                        run(url, scenario)
                    }
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now()+18) { finish(false, "test deadline") }
        CFRunLoopRun()
        exit(code)
    }
    static func waitForTermination(_ app: NSRunningApplication, _ url: URL, _ scenario: String) {
        if app.isTerminated { run(url, scenario) }
        else { DispatchQueue.main.asyncAfter(deadline: .now()+0.1) { waitForTermination(app,url,scenario) } }
    }
    static func run(_ url: URL, _ scenario: String) {
        handoff.open(url) { result in
            switch result {
            case .success(let app):
                guard scenario != "missing" else { client = app; finish(false, "missing application unexpectedly opened"); return }
                client = app
                let visible = ClientHandoff.hasVisibleWindow(app.processIdentifier)
                let active = NSWorkspace.shared.frontmostApplication?.processIdentifier == app.processIdentifier
                finish(visible && active, "\(scenario): pid=\(app.processIdentifier) active=\(active) visible=\(visible)")
            case .failure(let error): finish(scenario == "missing", "\(scenario): \(error.localizedDescription)")
            }
        }
    }
    static func finish(_ pass: Bool, _ detail: String) {
        print("\(pass ? "PASS" : "FAIL") \(detail)"); fflush(stdout)
        code = pass ? 0 : 1
        guard let app = client else { CFRunLoopStop(CFRunLoopGetMain()); return }
        app.terminate()
        finishAfterExit(app, Date().addingTimeInterval(4))
    }
    static func finishAfterExit(_ app: NSRunningApplication, _ deadline: Date) {
        if app.isTerminated { CFRunLoopStop(CFRunLoopGetMain()) }
        else if Date() >= deadline { print("FAIL fixture did not exit"); code = 1; CFRunLoopStop(CFRunLoopGetMain()) }
        else { DispatchQueue.main.asyncAfter(deadline: .now()+0.1) { finishAfterExit(app, deadline) } }
    }
}
