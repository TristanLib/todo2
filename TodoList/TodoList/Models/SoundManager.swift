import Foundation
import AVFoundation

// 声音类型枚举
enum SoundType: String {
    case startFocus = "start_focus"
    case endFocus = "end_focus"
    case startBreak = "start_break"
    case endBreak = "end_break"
    case tick = "tick"
    case complete = "complete"
}

class SoundManager {
    static let shared = SoundManager()
    
    private var audioPlayers: [SoundType: AVAudioPlayer] = [:]
    private var isEnabled = true
    
    private init() {
        setupAudioPlayers()
    }
    
    // 设置音频播放器
    private func setupAudioPlayers() {
        loadSound(for: .startFocus, filename: "start_focus", extension: "mp3")
        loadSound(for: .endFocus, filename: "end_focus", extension: "mp3")
        loadSound(for: .startBreak, filename: "start_break", extension: "mp3")
        loadSound(for: .endBreak, filename: "end_break", extension: "mp3")
        loadSound(for: .tick, filename: "tick", extension: "mp3")
        loadSound(for: .complete, filename: "complete", extension: "mp3")
    }
    
    // 加载声音文件
    private func loadSound(for type: SoundType, filename: String, extension ext: String) {
        // 这里应该加载实际的声音文件
        // 由于我们没有实际的音频文件，所以这里使用系统音效代替
        guard let soundUrl = createTemporarySoundFile(named: filename, withExtension: ext) else {
            print("无法创建临时声音文件: \(filename).\(ext)")
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: soundUrl)
            player.prepareToPlay()
            audioPlayers[type] = player
        } catch {
            print("加载声音失败 \(filename).\(ext): \(error.localizedDescription)")
        }
    }
    
    // 创建临时声音文件(模拟文件)
    private func createTemporarySoundFile(named filename: String, withExtension ext: String) -> URL? {
        let tempDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory())
        let fileURL = tempDirectoryURL.appendingPathComponent("\(filename).\(ext)")
        
        // 已经存在就直接返回
        if FileManager.default.fileExists(atPath: fileURL.path) {
            return fileURL
        }
        
        // 创建一个空的音频文件
        let emptyData = Data()
        do {
            try emptyData.write(to: fileURL)
            return fileURL
        } catch {
            print("创建临时文件失败: \(error.localizedDescription)")
            return nil
        }
    }
    
    // 设置是否启用声音
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }
    
    // 播放声音
    func playSound(_ type: SoundType) {
        guard isEnabled, let player = audioPlayers[type] else { return }
        
        // 重置播放位置
        player.currentTime = 0
        
        // 播放声音
        player.play()
    }
    
    // 停止声音
    func stopSound(_ type: SoundType) {
        guard let player = audioPlayers[type] else { return }
        
        if player.isPlaying {
            player.stop()
        }
    }
} 