import AppKit
import WebKit

final class AudioPageTest: NSObject, WKNavigationDelegate {
    let web: WKWebView
    let window: NSWindow
    init(path: String) {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        config.mediaTypesRequiringUserActionForPlayback = []
        web = WKWebView(frame: NSRect(x: 0, y: 0, width: 900, height: 650), configuration: config)
        window = NSWindow(contentRect: web.frame, styleMask: [.titled], backing: .buffered, defer: false)
        super.init()
        window.contentView = web; window.makeKeyAndOrderFront(nil)
        web.navigationDelegate = self
        let url = URL(fileURLWithPath: path)
        web.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.asyncAfter(deadline: .now()+1) {
            self.web.evaluateJavaScript("JSON.stringify({playing:!audio.paused,time:audio.currentTime,duration:audio.duration,blocked:soundBlocked})") { value, error in
                guard error == nil, let json = (value as? String)?.data(using: .utf8), let state = try? JSONSerialization.jsonObject(with: json) as? [String: Any], state["playing"] as? Bool == true, (state["time"] as? Double ?? 0) > 0.1, abs((state["duration"] as? Double ?? 0)-14)<0.1 else { print("FAIL browser playback \(String(describing: value)) \(String(describing: error))"); exit(1) }
                self.web.evaluateJavaScript("complete('skip'); const stoppedOK=audio.paused&&audio.currentTime===0;toggleSound(); const muteOK=audio.muted===soundMuted;JSON.stringify({stoppedOK,muteOK,errors:bootState.errors})") { value, error in
                    guard error == nil, let json = (value as? String)?.data(using: .utf8), let state = try? JSONSerialization.jsonObject(with: json) as? [String: Any], state["stoppedOK"] as? Bool == true, state["muteOK"] as? Bool == true, (state["errors"] as? [String])?.isEmpty == true else { print("FAIL browser stop/mute \(String(describing: value))"); exit(1) }
                    print("PASS WebKit browser audio decode, playback clock, mute and skip stop"); NSApp.terminate(nil)
                }
            }
        }
    }
}
@main struct WebAudioTests {
    static func main() {
        let app=NSApplication.shared; app.setActivationPolicy(.accessory)
        let test=AudioPageTest(path:CommandLine.arguments[1])
        DispatchQueue.main.asyncAfter(deadline:.now()+12){print("FAIL web audio timeout");exit(1)}
        withExtendedLifetime(test){app.run()}
    }
}
