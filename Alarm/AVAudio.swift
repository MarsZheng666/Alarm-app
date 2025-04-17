

import Foundation
import AVFoundation

/// 单例类，负责所有闹钟铃声的播放与停止
final class AlarmPlayer {
    /// 共享实例
    static let shared = AlarmPlayer()
    
    /// 内部 AVAudioPlayer 实例
    private var player: AVAudioPlayer?
    
    var isPlaying: Bool { player?.isPlaying == true }

    /// 私有化构造器，初始化时配置音频会话
    private init() {
        let session = AVAudioSession.sharedInstance()
        do {
            // 设置为后台播放模式，并在有其他音频时降低其他音量
            try session.setCategory(.playback, options: [.duckOthers])
            try session.setActive(true)
        } catch {
            print("⚠️ 音频会话配置失败：\(error)")
        }
    }

    /// 播放指定铃声文件
    /// - Parameters:
    ///   - name: 资源文件名（不含扩展名）
    ///   - ext: 资源文件扩展名（如 "caf", "mp3" 等），默认为 "caf"
    ///   - loops: 循环次数，-1 表示无限循环
    // “按名字播放”
        func playAlarmByName(named name: String, ext: String, loops: Int = -1, volume: Double = 1.0) {
            guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
                print("❌ \(name).\(ext) 不在 Bundle")
                return
            }
            playAlarmByURL(fileURL: url, loops: loops, volume: volume)
        }
        
        // 直接用 URL 播放
        func playAlarmByURL(fileURL url: URL, loops: Int = -1, volume: Double = 1.0) {
            stopAlarm()
            do {
                player = try AVAudioPlayer(contentsOf: url)
                player?.numberOfLoops = loops
                player?.volume       = Float(volume)
                player?.prepareToPlay()
                player?.play()
            } catch {
                print("❌ 播放失败：\(error)")
            }
        }

    /// 停止当前铃声播放
    func stopAlarm() {
        player?.stop()
        player = nil
    }
    
    /// 设置当前播放器的音量，0.0–1.0
    func setVolume(_ volume: Double) {
        player?.volume = Float(volume)
    }
    
    // 播放完毕时自动清理
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.player = nil
    }
}
