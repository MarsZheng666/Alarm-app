//
//  AlarmApp.swift
//  Alarm
//
//  Created by 郑席明 on 02/04/2025.
//
import AVFoundation
import SwiftUI

/// 统一配置音频会话：后台播放 + Duck 其它声音
private func configureAudioSession() {
    do {
        let session = AVAudioSession.sharedInstance()
        // .playback 允许在后台/锁屏继续播放
        // .duckOthers 在闹钟响时调低其它 App 音量
        try session.setCategory(.playback, options: [.duckOthers])
        try session.setActive(true)
    } catch {
        print("⚠️ AudioSession 配置失败：\(error)")
    }
}

@main
struct AlarmApp: App {
    init() {
           configureAudioSession()   
       }
    var body: some Scene {
        WindowGroup {
            TabView {
                BedtimeWakeupView()
                    .tabItem {
                        Label("Clock", systemImage: "clock")
                    }
                AlarmSettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
            }
        }
    }
}
