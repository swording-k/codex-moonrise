import Foundation

@main struct SoundtrackTests {
    static func main() throws {
        let suite = "local.codex.moonrise.audio-tests.\(UUID().uuidString)"
        let prefs = UserDefaults(suiteName: suite)!
        defer { prefs.removePersistentDomain(forName: suite) }
        let sound = try Soundtrack(url: URL(fileURLWithPath: CommandLine.arguments[1]), preferences: prefs)
        assert(abs(sound.duration - 14) < 0.1, "soundtrack must end with the animation")
        sound.setMuted(true)
        assert(sound.isMuted && sound.volume == 0)
        sound.start()
        RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        assert(sound.isPlaying && sound.currentTime > 0.05, "muted playback should retain timeline sync")
        sound.stop()
        assert(!sound.isPlaying && sound.currentTime == 0, "skip/handoff must stop audio")
        let mutedRestore = try Soundtrack(url: URL(fileURLWithPath: CommandLine.arguments[1]), preferences: prefs)
        assert(mutedRestore.isMuted && mutedRestore.volume == 0)
        sound.setMuted(false)
        assert(sound.volume > 0 && sound.volume <= 0.35, "use restrained default gain")
        let restored = try Soundtrack(url: URL(fileURLWithPath: CommandLine.arguments[1]), preferences: prefs)
        assert(!restored.isMuted, "mute preference must persist")
        print("PASS audio duration, silent playback clock, stop, restrained gain and persistence")
    }
}
