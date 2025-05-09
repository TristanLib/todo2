import Foundation
import AVFoundation
import UIKit

// 声音类型枚举
enum SoundType: String {
    case startFocus = "start_focus"
    case endFocus = "end_focus"
    case startBreak = "start_break"
    case endBreak = "end_break"
    case tick = "tick"
    case complete = "complete"
}

// 白噪音类型枚举
enum WhiteNoiseType: String, CaseIterable, Identifiable {
    case none = "none"        // 无白噪音
    // 暂时只保留雷声音频，其他音频注释掉
    // case rain = "rain"        // 雨声
    // case ocean = "ocean"      // 海浪声
    // case fire = "fire"        // 篝火声
    case forest = "forest"    // 森林声
    // case cafe = "cafe"        // 咖啡厅
    case thunder = "thunder"  // 雷声
    // case wind = "wind"        // 风声
    // case river = "river"      // 河流声
    case bird = "bird"        // 鸟叫声
    case creek = "creek"      // 小溪声

    var id: String { self.rawValue }

    var displayName: String {
        switch self {
        case .none:
            return NSLocalizedString("无白噪音", comment: "No white noise")
        // case .rain:
        //     return NSLocalizedString("雨声", comment: "Rain sound")
        // case .ocean:
        //     return NSLocalizedString("海浪", comment: "Ocean waves sound")
        // case .fire:
        //     return NSLocalizedString("篝火", comment: "Fire crackling sound")
        case .forest:
            return NSLocalizedString("森林", comment: "Forest ambience sound")
        // case .cafe:
        //     return NSLocalizedString("咖啡厅", comment: "Cafe ambience sound")
        case .thunder:
            return NSLocalizedString("雷声", comment: "Thunder sound")
        // case .wind:
        //     return NSLocalizedString("风声", comment: "Wind sound")
        // case .river:
        //     return NSLocalizedString("河流", comment: "River sound")
        case .bird:
            return NSLocalizedString("鸟叫声", comment: "Bird sound")
        case .creek:
            return NSLocalizedString("小溪声", comment: "Creek sound")
        }
    }

    var iconName: String {
        switch self {
        case .none:
            return "speaker.slash"
        // case .rain:
        //     return "cloud.rain"
        // case .ocean:
        //     return "water.waves"
        // case .fire:
        //     return "flame"
        case .forest:
            return "leaf"
        // case .cafe:
        //     return "cup.and.saucer"
        case .thunder:
            return "cloud.bolt"
        // case .wind:
        //     return "wind"
        // case .river:
        //     return "water"
        case .bird:
            return "bird"
        case .creek:
            return "water.waves"
        }
    }
}

class SoundManager: ObservableObject {
    static let shared = SoundManager()

    private var audioPlayers: [SoundType: AVAudioPlayer] = [:]
    private var whiteNoisePlayer: AVAudioPlayer?

    @Published var isEnabled = true
    @Published var currentWhiteNoise: WhiteNoiseType = .none
    @Published var whiteNoiseVolume: Float = 0.5 // 默认音量50%

    private init() {
        // 从UserDefaults加载设置
        isEnabled = UserDefaults.standard.bool(forKey: "soundEnabled")
        if let savedNoiseType = UserDefaults.standard.string(forKey: "currentWhiteNoise"),
           let noiseType = WhiteNoiseType(rawValue: savedNoiseType) {
            currentWhiteNoise = noiseType
        }
        whiteNoiseVolume = UserDefaults.standard.float(forKey: "whiteNoiseVolume")
        if whiteNoiseVolume == 0 { whiteNoiseVolume = 0.5 } // 确保有默认值
        
        // 配置音频会话以支持后台播放
        setupAudioSession()
        
        // 注册应用生命周期通知
        registerForNotifications()
        
        setupAudioPlayers()

        // 注意：不再在初始化时自动播放白噪音
        // 白噪音将仅在专注模式启动时播放
    }

    // 设置音频播放器
    private func setupAudioPlayers() {
        loadSound(for: .startFocus, filename: "start_focus", extension: "mp3")
        loadSound(for: .endFocus, filename: "end_focus", extension: "mp3")
        loadSound(for: .startBreak, filename: "start_break", extension: "mp3")
        loadSound(for: .endBreak, filename: "end_break", extension: "mp3")
        loadSound(for: .tick, filename: "tick", extension: "mp3")
        loadSound(for: .complete, filename: "complete", extension: "mp3")

        // 预加载所有白噪音
        for noiseType in WhiteNoiseType.allCases where noiseType != .none {
            preloadWhiteNoise(noiseType)
        }
    }

    // 加载声音文件
    private func loadSound(for type: SoundType, filename: String, extension ext: String) {
        // 尝试从资源包中加载声音文件
        if let soundUrl = Bundle.main.url(forResource: filename, withExtension: ext) {
            do {
                let player = try AVAudioPlayer(contentsOf: soundUrl)
                player.prepareToPlay()
                audioPlayers[type] = player
            } catch {
                print("从资源包加载声音失败 \(filename).\(ext): \(error.localizedDescription)")
                createTemporarySoundPlayer(for: type, named: filename, withExtension: ext)
            }
        } else {
            // 如果资源包中没有声音文件，创建临时文件
            createTemporarySoundPlayer(for: type, named: filename, withExtension: ext)
        }
    }

    // 创建临时声音播放器
    private func createTemporarySoundPlayer(for type: SoundType, named filename: String, withExtension ext: String) {
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

        // 创建一个包含简单音频数据的文件，而不是空文件
        // 这里创建一个包含一些基本音频数据的文件
        // 注意：这不是一个有效的MP3文件，但对于测试来说已经足够
        var soundData = Data([0xFF, 0xFB, 0x90, 0x44, 0x00]) // 非常简单的MP3头
        // 添加一些随机数据作为音频数据
        for _ in 0..<1000 {
            soundData.append(UInt8.random(in: 0...255))
        }

        do {
            try soundData.write(to: fileURL)
            return fileURL
        } catch {
            print("创建临时文件失败: \(error.localizedDescription)")
            return nil
        }
    }

    // 预加载白噪音文件
    private func preloadWhiteNoise(_ type: WhiteNoiseType) {
        // 尝试从多个可能的路径加载白噪音文件
        let filename = type.rawValue
        let ext = "mp3"

        // 检查所有可能的路径
        let possiblePaths = [
            "\(filename)",                       // 直接文件名
            "Sounds/WhiteNoise/\(filename)",      // 目录结构
            "Resources/Sounds/WhiteNoise/\(filename)", // 完整目录结构
            "WhiteNoise/\(filename)"             // 只有子目录
        ]

        var foundPath = false
        for path in possiblePaths {
            if let resourcePath = Bundle.main.path(forResource: path, ofType: ext) {
                print("找到白噪音文件: \(resourcePath)")
                foundPath = true
                break
            }
        }

        if !foundPath {
            print("描述白噪音失败 \(filename).\(ext): 未能完成操作。")

            // 尝试直接从文件系统加载
            let projectPath = "/Volumes/disk2/cursor_projects/todo2/TodoList/TodoList/Resources/Sounds/WhiteNoise/\(filename).mp3"
            if FileManager.default.fileExists(atPath: projectPath) {
                print("在文件系统中找到\(type.displayName)文件: \(projectPath)")
            } else {
                print("在文件系统中未找到\(type.displayName)文件")
            }

            // 创建临时文件以模拟白噪音
            guard let _ = createTemporarySoundFile(named: filename, withExtension: ext) else {
                print("无法创建临时白噪音文件: \(filename).\(ext)")
                return
            }
        }
    }

    // 设置是否启用声音
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "soundEnabled")

        // 如果禁用声音，停止白噪音
        if !enabled && whiteNoisePlayer?.isPlaying == true {
            stopWhiteNoise()
        }
        // 注意：不再在这里自动播放白噪音
        // 白噪音将仅在专注模式启动时播放
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

    // 播放白噪音
    func playWhiteNoise(_ type: WhiteNoiseType) {
        // 如果声音被禁用或选择了无白噪音，则停止播放
        if !isEnabled || type == .none {
            stopWhiteNoise()
            return
        }

        // 停止当前播放的白噪音
        stopWhiteNoise()

        // 更新当前白噪音类型，但只有当类型不为.none时才更新
        if type != .none {
            currentWhiteNoise = type
            UserDefaults.standard.set(type.rawValue, forKey: "currentWhiteNoise")
        }

        // 尝试从多个可能的路径加载白噪音文件
        let filename = type.rawValue
        let ext = "mp3"
        var foundAndPlayed = false

        // 检查所有可能的路径
        let possiblePaths = [
            "\(filename)",                       // 直接文件名
            "Sounds/WhiteNoise/\(filename)",      // 目录结构
            "Resources/Sounds/WhiteNoise/\(filename)", // 完整目录结构
            "WhiteNoise/\(filename)"             // 只有子目录
        ]

        for path in possiblePaths {
            if let soundUrl = Bundle.main.url(forResource: path, withExtension: ext) {
                do {
                    // 创建新的播放器
                    let player = try AVAudioPlayer(contentsOf: soundUrl)
                    player.numberOfLoops = -1  // 无限循环播放
                    player.volume = whiteNoiseVolume
                    player.prepareToPlay()
                    player.play()

                    whiteNoisePlayer = player
                    print("成功从资源目录播放白噪音: \(path).\(ext)")
                    foundAndPlayed = true
                    break
                } catch {
                    print("从资源目录播放白噪音失败: \(path).\(ext): \(error.localizedDescription)")
                }
            }
        }

        // 如果从资源目录加载失败，尝试直接从文件系统加载
        if !foundAndPlayed {
            let projectPath = "/Volumes/disk2/cursor_projects/todo2/TodoList/TodoList/Resources/Sounds/WhiteNoise/\(filename).mp3"
            if FileManager.default.fileExists(atPath: projectPath) {
                do {
                    let fileUrl = URL(fileURLWithPath: projectPath)
                    let player = try AVAudioPlayer(contentsOf: fileUrl)
                    player.numberOfLoops = -1  // 无限循环播放
                    player.volume = whiteNoiseVolume
                    player.prepareToPlay()
                    player.play()

                    whiteNoisePlayer = player
                    print("成功从文件系统直接播放\(type.displayName)白噪音")
                    foundAndPlayed = true
                } catch {
                    print("从文件系统直接播放\(type.displayName)失败: \(error.localizedDescription)")
                }
            } else {
                print("在文件系统中未找到\(type.displayName)文件")
            }
        }

        // 如果从资源和文件系统都加载失败，使用模拟文件
        if !foundAndPlayed {
            guard let soundUrl = createTemporarySoundFile(named: filename, withExtension: ext) else {
                print("无法创建临时白噪音文件: \(filename).\(ext)")
                return
            }

            do {
                // 创建新的播放器
                let player = try AVAudioPlayer(contentsOf: soundUrl)
                player.numberOfLoops = -1  // 无限循环播放
                player.volume = whiteNoiseVolume
                player.prepareToPlay()
                player.play()

                whiteNoisePlayer = player
                print("播放模拟白噪音: \(type.rawValue)")
            } catch {
                print("播放白噪音失败 \(filename).\(ext): \(error.localizedDescription)")
            }
        }
    }

    // 停止白噪音
    func stopWhiteNoise() {
        // 停止播放器
        whiteNoisePlayer?.stop()
        whiteNoisePlayer = nil

        // 注意：不再清除currentWhiteNoise设置
        // 这样可以保留用户选择的白噪音类型，下次专注时可以继续使用
        print("停止白噪音播放，保留设置: \(currentWhiteNoise.displayName)")
    }

    // 设置白噪音音量
    func setWhiteNoiseVolume(_ volume: Float) {
        whiteNoiseVolume = volume
        whiteNoisePlayer?.volume = volume
        UserDefaults.standard.set(volume, forKey: "whiteNoiseVolume")
    }
    
    // MARK: - 后台播放支持
    
    // 配置音频会话以支持后台播放
    private func setupAudioSession() {
        do {
            // 设置音频会话类别为播放，并允许混音和后台播放
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers, .duckOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
            print("音频会话配置成功，支持后台播放")
        } catch {
            print("配置音频会话失败: \(error.localizedDescription)")
        }
    }
    
    // 注册应用生命周期通知
    private func registerForNotifications() {
        // 监听应用进入后台通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        // 监听应用进入前台通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        // 监听音频会话中断通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        
        // 监听专注结束通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleFocusEnded),
            name: NSNotification.Name("FocusTimerEndedNotification"),
            object: nil
        )
    }
    
    // 处理应用进入后台
    @objc private func handleAppDidEnterBackground() {
        print("应用进入后台，确保音频继续播放")
        // 如果需要，可以在这里添加额外的后台播放逻辑
    }
    
    // 处理应用进入前台
    @objc private func handleAppWillEnterForeground() {
        print("应用进入前台")
        // 重新激活音频会话
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("重新激活音频会话失败: \(error.localizedDescription)")
        }
    }
    
    // 处理专注结束通知
    @objc private func handleFocusEnded(notification: Notification) {
        print("收到专注结束通知，停止白噪音播放")
        stopWhiteNoise()
    }
    
    // 处理音频会话中断
    @objc private func handleAudioSessionInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            // 音频被中断（例如来电）
            print("音频播放被中断")
            
        case .ended:
            // 中断结束，检查是否应该恢复播放
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt,
               AVAudioSession.InterruptionOptions(rawValue: optionsValue).contains(.shouldResume) {
                print("中断结束，检查是否应该恢复音频播放")
                
                // 只有在专注状态下才恢复白噪音播放
                let focusTimer = FocusTimerManager.shared
                if currentWhiteNoise != .none && isEnabled && whiteNoisePlayer == nil && 
                   focusTimer.currentState == .focusing {
                    print("中断结束，当前处于专注状态，恢复白噪音播放")
                    playWhiteNoise(currentWhiteNoise)
                } else {
                    print("中断结束，但不恢复白噪音播放，当前状态：\(focusTimer.currentState.rawValue)")
                }
            }
            
        @unknown default:
            break
        }
    }
}