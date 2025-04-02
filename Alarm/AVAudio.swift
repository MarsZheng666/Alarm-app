//import UserNotifications
//
//func requestNotificationPermission() {
//    let center = UNUserNotificationCenter.current()
//    center.requestAuthorization(options: [.alert, .sound]) { granted, error in
//        if let error = error {
//            print("请求通知权限失败：\(error)")
//        }
//    }
//}
//
///// 调度一个闹钟通知，在下一个符合 hour/minute 的时刻触发
//func scheduleAlarmNotification(hour24: Int, minute: Int, identifier: String = "wakeAlarm") {
//    let center = UNUserNotificationCenter.current()
//    // 先移除旧的同 ID 通知
//    center.removePendingNotificationRequests(withIdentifiers: [identifier])
//
//    // 构造通知内容
//    let content = UNMutableNotificationContent()
//    content.title = "⏰ Wake Up"
//    content.body = "Time to wake up!"
//    content.sound = .defaultCritical  // 或 UNNotificationSound.default
//
//    // 构造触发条件：每一天的指定 hour/minute
//    var dateComponents = DateComponents()
//    dateComponents.hour = hour24
//    dateComponents.minute = minute
//
//    // 以日历触发，重复执行
//    let trigger = UNCalendarNotificationTrigger(
//        dateMatching: dateComponents,
//        repeats: true
//    )
//
//    let request = UNNotificationRequest(
//        identifier: identifier,
//        content: content,
//        trigger: trigger
//    )
//
//    center.add(request) { error in
//        if let error = error {
//            print("调度闹钟通知失败：\(error)")
//        }
//    }
//}

import Foundation
import AVFoundation

/// 单例类，负责所有闹钟铃声的播放与停止
final class AlarmPlayer {
    /// 共享实例
    static let shared = AlarmPlayer()
    
    /// 内部 AVAudioPlayer 实例
    private var player: AVAudioPlayer?

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
    func playAlarm(named name: String, ext: String = "caf", loops: Int = -1) {
        stopAlarm()  // 先停止任何已有播放
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
            print("❌ 未找到铃声文件：\(name).\(ext)")
            return
        }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = loops
            player?.prepareToPlay()
            player?.play()
        } catch {
            print("❌ 播放闹钟铃声失败：\(error)")
        }
    }

    /// 停止当前铃声播放
    func stopAlarm() {
        player?.stop()
        player = nil
    }
}
