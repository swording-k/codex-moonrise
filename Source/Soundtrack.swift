import AVFoundation
import Foundation

final class Soundtrack {
    private let player: AVAudioPlayer
    private let preferences: UserDefaults
    private(set) var isMuted: Bool
    var duration: TimeInterval { player.duration }
    var currentTime: TimeInterval { player.currentTime }
    var isPlaying: Bool { player.isPlaying }
    var volume: Float { player.volume }
    init(url: URL, preferences: UserDefaults = .standard) throws {
        self.preferences = preferences
        player = try AVAudioPlayer(contentsOf: url)
        isMuted = preferences.bool(forKey: "soundMuted")
        player.volume = isMuted ? 0 : 0.32
        player.prepareToPlay()
    }
    func start() { if !player.isPlaying { player.play() } }
    func setMuted(_ muted: Bool) {
        isMuted = muted
        preferences.set(muted, forKey: "soundMuted")
        player.volume = muted ? 0 : 0.32
    }
    func stop() { player.stop(); player.currentTime = 0 }
}
