import SwiftUI
import MediaPlayer

struct AlarmSettingsView: View {
    // 1. 用单例模型替代本地 State
    @StateObject private var model = AlarmModel.shared
    @State private var previewing  = false
    
    var body: some View {
        
        NavigationView {
            Form {
                // 2. Alarm 开关 绑定到 model.alarmOn
                Section {
                    Toggle("Alarm", isOn: $model.alarmOn)
                }
                
                Section(header: Text("Sounds & Haptics")) {
                    // 3. 铃声选择绑定到 model.selectedSound/ext
                    NavigationLink(
                        destination: SoundSelectionView(
                            selectedSound: $model.selectedSound,
                            selectedExt:   $model.selectedExt,
                            selectedURL:  $model.selectedURL
                        )
                    ) {
                        HStack {
                            Text("Sound")
                            Spacer()
                            Text(model.selectedSound)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // 4. 系统音量滑块保持不变
                    HStack {
                        Image(systemName: "speaker.fill")
                        Slider(value: $model.alarmVolume, in: 0...1)
                        
                        Image(systemName: "speaker.wave.3.fill")
                    }
                    Button {
                        if previewing {
                            AlarmPlayer.shared.stopAlarm()
                            previewing = false
                        } else {
                            if let url = model.selectedURL {
                                AlarmPlayer.shared.playAlarmByURL(
                                    fileURL: url,
                                    loops:   0,
                                    volume:  model.alarmVolume
                                )
                            } else {
                                AlarmPlayer.shared.playAlarmByName(
                                    named:  model.selectedSound,
                                    ext:    model.selectedExt,
                                    loops:  0,
                                    volume: model.alarmVolume
                                )
                            }
                            previewing = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: previewing ? "stop.circle":"play.circle")
                            Text(previewing ? "Stop Sample":"Play Sample")
                        }
                    }
                    
                }
                // 5. 振动开关绑定到 model.snoozeOn
                Section {
                    Toggle("Haptic", isOn: $model.snoozeOn)
                }
            }
            
            
        } .navigationTitle("Alarm Settings")
            .listStyle(InsetGroupedListStyle())
    }
    
}

struct VolumeSlider: UIViewRepresentable {
    func makeUIView(context: Context) -> MPVolumeView {
            let view = MPVolumeView(frame: .zero)
            // 隐藏 AirPlay 路由按钮
            for sub in view.subviews {
                if let btn = sub as? UIButton { btn.isHidden = true }
            }
            return view
        }
        func updateUIView(_ uiView: MPVolumeView, context: Context) {}
}

struct AlarmSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AlarmSettingsView()
    }
}
