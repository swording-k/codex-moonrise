import AppKit
if NSWorkspace.shared.frontmostApplication?.bundleIdentifier == "com.apple.loginwindow" {
    print("SKIP: native window handoff requires an unlocked macOS desktop")
    exit(77)
}
