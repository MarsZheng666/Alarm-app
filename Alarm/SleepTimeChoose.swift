import SwiftUI

struct SleepGoalSheetView: View {
    // 与主视图绑定的状态，用于双向更新
    @Binding var selectedHour: Int
    @Binding var selectedMinute: Int
    
    // 你也可以在这里设置小时/分钟的取值范围
    private let hoursRange = 0..<24
    private let minutesRange = [0, 5,10,15,20,25, 30,25,40, 45,50,55]
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            // 横向放置两个 Picker，分别选择小时和分钟
            HStack(spacing: 0) {
                Picker("Hour", selection: $selectedHour) {
                    ForEach(hoursRange, id: \.self) { hour in
                        Text("\(hour) hr").tag(hour)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                
                Picker("Minute", selection: $selectedMinute) {
                    ForEach(minutesRange, id: \.self) { minute in
                        Text("\(minute) min").tag(minute)
                    }
                }
                .pickerStyle(WheelPickerStyle())
            }
            .navigationTitle("Select Sleep Goal")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        // 关闭弹窗，更新主界面
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SleepGoalSheetView_Previews: PreviewProvider {
    static var previews: some View {
        SleepGoalSheetView(
            selectedHour: .constant(6),
            selectedMinute: .constant(30)
        )
    }
}
