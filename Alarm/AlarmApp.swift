//
//  AlarmApp.swift
//  Alarm
//
//  Created by 郑席明 on 02/04/2025.
//

import SwiftUI

@main
struct AlarmApp: App {
//    init() {
//            requestNotificationPermission()
//        }
    
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
