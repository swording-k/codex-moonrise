import AppKit
final class Fixture: NSObject, NSApplicationDelegate {
    var window: NSWindow?
    func showWindow() {
        if window == nil {
            window = NSWindow(contentRect: NSRect(x: 160, y: 160, width: 480, height: 260), styleMask: [.titled, .closable], backing: .buffered, defer: false)
            window?.title = "Moonrise Handoff Test"
            window?.isReleasedWhenClosed = false
        }
        window?.makeKeyAndOrderFront(nil)
    }
    func applicationDidFinishLaunching(_ notification: Notification) {
        if !CommandLine.arguments.contains("--without-window") { showWindow() }
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool { showWindow(); return true }
}
let app = NSApplication.shared
app.setActivationPolicy(.regular)
let fixture = Fixture()
app.delegate = fixture
withExtendedLifetime(fixture) { app.run() }
