//
//  AlarmModel.swift
//  Alarm
//
//  Created by 郑席明 on 14/04/2025.
//

import Foundation
import UserNotifications
import AudioToolbox
import Combine

/// 管理闹钟状态与本地通知调度，并在通知触发时调用 AlarmPlayer 播放铃声和振动
final class AlarmModel: NSObject, ObservableObject {
    /// 单例实例，整个 App 共享
    static let shared = AlarmModel()
    
    /// 闹钟铃声音量（0.0–1.0），默认为 0.5
    @Published var alarmVolume: Double = 0.5
    
    /// 闹钟开关，打开时会调度通知，关闭时移除通知
    @Published var alarmOn: Bool = true {
        didSet { configureAlarm() }
    }
    /// 闹钟触发时是否振动
    @Published var snoozeOn: Bool = true
    /// 起床时的小时（24 小时制 0–23）
    @Published var wakeHour: Int = 7 {
        didSet { configureAlarm() }
    }
    /// 起床时的分钟（0–59）
    @Published var wakeMinute: Int = 30 {
        didSet { configureAlarm() }
    }
    /// 选中的铃声文件名（不含扩展名）
    @Published var selectedSound: String = "Anticipate"
    /// 选中的铃声文件扩展名
    @Published var selectedExt: String = "caf"
    //自选铃声URL
    @Published var selectedURL: URL? = nil
    
    /// 私有化构造器，设置通知代理并请求权限
    private override init() {
        super.init()
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        requestPermission()
        
        // 监听 alarmVolume 改变，实时更新正在播放的音量
        $alarmVolume
            .sink { vol in
                AlarmPlayer.shared.setVolume(vol)
            }
            .store(in: &cancellables)
    }
    
    
   

    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 权限请求
    
    /// 请求本地通知权限（弹窗一次）
    private func requestPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound]) { granted, error in
                if let error = error {
                    print("❌ 请求通知权限失败：\(error)")
                }
            }
    }
    
    // MARK: - 通知调度
    
    /// 根据当前状态调度或移除闹钟通知
    private func configureAlarm() {
        let center = UNUserNotificationCenter.current()
        // 移除旧的同标识通知
        center.removePendingNotificationRequests(withIdentifiers: ["wakeAlarm"])
        
        // 如果闹钟开关关闭，则不再调度
        guard alarmOn else { return }
        
        // 构造通知内容
        let content = UNMutableNotificationContent()
        content.title = "⏰ Wake Up"
        content.body  = "Time to wake up!"
        
        if let url = selectedURL {
            // 自定义文件：放在 Library/Sounds 下即可用 URL
            let soundName = UNNotificationSoundName(url.lastPathComponent)
            content.sound = UNNotificationSound(named: soundName)
        } else {
            // Bundle 文件
            content.sound = UNNotificationSound(
                named: UNNotificationSoundName("\(selectedSound).\(selectedExt)")
            )
        }
        
        // 构造触发时间：每天的 wakeHour:wakeMinute
        var comps = DateComponents()
        comps.hour   = wakeHour
        comps.minute = wakeMinute
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: comps,
            repeats: true
        )
        let request = UNNotificationRequest(
            identifier: "wakeAlarm",
            content: content,
            trigger: trigger
        )
        // 提交请求
        center.add(request) { error in
            if let error = error {
                print("❌ 通知调度失败：\(error)")
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AlarmModel: UNUserNotificationCenterDelegate {
    /// 通知在前台弹出时回调
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
        @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // 如果闹钟开启，则播放自定义铃声
        if alarmOn {
            if let url = selectedURL {
                AlarmPlayer.shared.playAlarmByURL(fileURL: url,
                                             loops: 0,
                                             volume: alarmVolume)
            } else {
                AlarmPlayer.shared.playAlarmByName(named:  selectedSound,
                                             ext:    selectedExt,
                                             loops:  0,
                                             volume: alarmVolume)
            }
        }
        
        // 如果 snoozeOn 打开，则振动
        if snoozeOn {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
        // 仅展示横幅，不播放系统默认声音
        completionHandler([.banner])
    }
}
        


