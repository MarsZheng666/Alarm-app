//
//  ContentView.swift
//  Alarm
//
//  Created by 郑席明 on 02/04/2025.
//

import SwiftUI


struct global_variable{
    static var ringSize: CGFloat = 300
    static var knobSize: CGFloat = 30
}

/// 自定义形状，用于绘制圆弧（表示睡眠区间）
struct SleepArc: Shape {
    var startAngle: Angle
    var endAngle: Angle
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        return Path { path in
            // SwiftUI 的圆弧是从右侧 0° 开始，这里减去 90° 让 0° 对应顶部
            path.addArc(
                center: center,
                radius: radius,
                startAngle: startAngle - Angle(degrees: 90),
                endAngle: endAngle - Angle(degrees: 90),
                clockwise: false
            )
        }
    }
}

struct BedtimeWakeupView: View {
    //@EnvironmentObject var state: AppState
    /// 开始与结束角度（0~360）
    @State private var startAngle: Double = 0  // 默认让开始角度在顶部（270° 对应 0°减去 90°）
    @State private var endAngle: Double   = 120   // 对应顶部相对的下半圈
    @State private var isStartKnobActive: Bool = false
    @State private var isEndKnobActive: Bool = false
    // 控制弹窗显示状态
    @State private var showPicker = false
    // 用户选择的小时和分钟
    @State private var selectedHour = 6
    @State private var selectedMinute = 30
    //当前选择时间是否满足sleep goal
    @State private var if_satisfied :Bool = true
    
    
    lazy var initEndAngle: Double = {
        return timeToAngle(formatTimeHour(selectedHour, selectedMinute))
    }()
    //var endAngle = initEndAngle
    
    /// 圆环宽度
    let ringLineWidth: CGFloat = 50
    
    /// 拖动时的最小时间步长（单位：小时），用于防止两个滑块重合
    let minTimeDelta: Double = 1
    
    var body: some View {
        //@EnvironmentObject var AppState
        VStack(spacing: 30) {
            //顶部
            Header_view(startAngle: startAngle, endAngle: endAngle)
            
            ClockRingView(startAngle: $startAngle,
                          endAngle: $endAngle,
                          isStartKnobActive: $isStartKnobActive,
                          isEndKnobActive: $isEndKnobActive,
                          if_satisfied: $if_satisfied,
                          selectedHour: $selectedHour,
                          selectedMinute: $selectedMinute,
                          ringSize: global_variable.ringSize,
                          ringLineWidth: ringLineWidth,
                          knobSize: global_variable.knobSize,
                          minTimeDelta: minTimeDelta)
           
            BottomView(
                startAngle: startAngle,
                endAngle: endAngle,
                selectedHour: $selectedHour,
                selectedMinute: $selectedMinute,
                showPicker: $showPicker,
                if_satisfied: $if_satisfied,
        )
        }
//        .onChange(of: endAngle) {
//            let wakeHourDouble = angleToTime(endAngle)
//            let wakeHour = Int(wakeHourDouble)
//            let wakeMinute = Int((wakeHourDouble - Double(wakeHour)) * 60)
//            scheduleAlarmNotification(hour24: wakeHour, minute: wakeMinute)
    //}
       
    }
}

// 顶部：显示 BEDTIME / WAKE UP
struct Header_view: View {
    let startAngle: Double
    let endAngle: Double
    
    var body: some View {
        
        HStack(spacing: 50) {
            // 左侧：就寝时间
            VStack(spacing: 8) {
                // 标题 + 图标
                HStack {
                    Image(systemName: "bed.double.fill")
                        .foregroundColor(.mint)
                    Text("BEDTIME")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                
                // 动态时间（示例使用 24 小时制格式化）
                let bedHour24 = angleToTime(startAngle) // 计算滑块对应的 24 小时制数值
                Text(formatTimeHHmm(bedHour24))
                    .font(.system(size: 36, weight: .semibold))
                
                // 显示 Today / Tomorrow
                Text(dayString(for: bedHour24))
                    .foregroundColor(.gray)
            }
            
            // 右侧：起床时间
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "alarm.fill")
                        .foregroundColor(.yellow)
                    Text("WAKE UP")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                
                let wakeHour24 = angleToTime(endAngle)
                Text(formatTimeHHmm(wakeHour24))
                    .font(.system(size: 36, weight: .semibold))
                
                Text(dayString(for: wakeHour24))
                    .foregroundColor(.gray)
            }
        }.padding()
        
    }
}

//中部圆环
struct ClockRingView:View {
    @Binding var startAngle: Double
    @Binding var endAngle: Double
    @Binding var isStartKnobActive: Bool
    @Binding var isEndKnobActive: Bool
    @Binding var if_satisfied:Bool
    @Binding var selectedHour: Int
    @Binding var selectedMinute: Int
    
    @State private var activeKnob: Knob? = nil
    @State private var pendingScheduleWorkItem: DispatchWorkItem?
    @StateObject private var model = AlarmModel.shared
    
    /// 最大睡眠时长（小时）
    private let maxSleepHours: Double = 20
    /// 最大对应的角度差
    private var maxAngleDelta: Double { maxSleepHours * 15 }
    
    enum Knob { case start, end }
    //let isActive: Bool
    let ringSize: CGFloat
    let ringLineWidth: CGFloat
    let knobSize: CGFloat
    let minTimeDelta: Double
    
    private var sleepGoalSatisfied: Bool {
        let goal = formatTimeHour(selectedHour, selectedMinute)
        let sleepH = calculateSleepHours(start: startAngle, end: endAngle)
        return sleepH >= goal
    }
    
    var body: some View {
        ZStack {
            // 1. 背景圆环
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: ringLineWidth)
                .frame(width: global_variable.ringSize, height: global_variable.ringSize)
            
            // 睡眠区间弧
            SleepArc(
                startAngle: Angle(degrees: startAngle),
                endAngle: Angle(degrees: endAngle)
            )
            .stroke(
                sleepGoalSatisfied ? Color.white:Color.orange,
                style: StrokeStyle(lineWidth: ringLineWidth-15, lineCap: .round)
            )
            .frame(width: global_variable.ringSize, height: global_variable.ringSize)
            .shadow(color: .gray,radius:2)
            .animation(.easeInOut(duration: 0.2), value: sleepGoalSatisfied)
            
            //睡眠区间弧里的刻度
            // 计算两个滑块之间的角度差（保证为正值）
            let rawAngleDiff = calculateSleepAngles(start: startAngle, end: endAngle)
            let Angle = rawAngleDiff * 15
            // 每 3 分钟对应的角度（1 分钟 = 0.25°，3 分钟 = 0.75°）
            let tickAngleIncrement = 3.75
            // 计算刻度数量（向下取整，不包括终点）
            let tickCount = Int(Angle / tickAngleIncrement)
            
            ForEach(0...tickCount, id: \.self) { i in
                // 计算当前刻度的角度（超过360度时可不做特殊处理，因为视图会自动归位）
                let tickAngle = startAngle + Double(i) * tickAngleIncrement
                // 在内圆外侧绘制小刻度（调整 offset 使其位于圆环内部）
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(red: 220/255, green: 220/255, blue: 220/255))
                    .frame(width: 2, height: 15)
                    .rotationEffect(.degrees(tickAngle))
                    .offset(
                        x: (global_variable.ringSize / 2 + 2) * cos(CGFloat(tickAngle) * .pi / 180 - .pi/2),
                        y: (global_variable.ringSize / 2 + 2) * sin(CGFloat(tickAngle) * .pi / 180 - .pi/2)
                    )
            }
            
            // 3. 睡眠开始时间滑块
            knobView(color: .white, isActive: isStartKnobActive,centerDotColor:.mint)
                .offset(
                    // 根据角度计算滑块在圆周上的 x, y
                    x: (global_variable.ringSize / 2) * cos(CGFloat(startAngle) * .pi/180 - .pi/2),
                    y: (global_variable.ringSize / 2) * sin(CGFloat(startAngle) * .pi/180 - .pi/2)
                )
          
            // 4. 起床时间滑块
            knobView(color: .white, isActive: isEndKnobActive,centerDotColor:.yellow)
                .offset(
                    x: (global_variable.ringSize / 2) * cos(CGFloat(endAngle) * .pi/180 - .pi/2),
                    y: (global_variable.ringSize / 2) * sin(CGFloat(endAngle) * .pi/180 - .pi/2)
                )
            
            // 内圆尺寸参数
            let innerCirclePadding: CGFloat = 60
            let innerCircleSize = global_variable.ringSize - innerCirclePadding
            let innerRadius = innerCircleSize / 2
            
            Group {
                // 24个大刻度（内圆区域）
                ForEach(0..<24) { i in
                    VStack {
                        Rectangle()
                            .fill(Color.secondary)
                            .frame(width: 2, height: 10)
                        Spacer()
                    }
                    .rotationEffect(.degrees(Double(i) * 15))
                    .frame(width: innerCircleSize, height: innerCircleSize)
                    // 将内圆刻度居中显示在外圆内
                    .position(x: global_variable.ringSize / 2, y: global_variable.ringSize / 2)
                }
                
                // 每个大刻度之间5个小刻度
                ForEach(0..<24) { i in
                    ForEach(1..<4) { j in
                        VStack {
                            Rectangle()
                                .fill(Color.secondary)
                                .frame(width: 1, height: 3)
                            Spacer()
                        }
                        .rotationEffect(.degrees(Double(i) * 15 + Double(j) * (15.0 / 4.0)))
                        .frame(width: innerCircleSize, height: innerCircleSize)
                        .position(x: global_variable.ringSize / 2, y: global_variable.ringSize / 2)
                    }
                }
                
                // 偶数小时标数字，放置在内圆边缘（内圆区域）
                ForEach(0..<24) { i in
                    if i % 2 == 0 {
                        Text("\(i)")
                            .font(.caption2)
                            .foregroundColor(.primary)
                        // 保持数字正向显示
                            .position(
                                x: global_variable.ringSize / 2 + (innerRadius - 20) * cos((Double(i) * 15 - 90) * .pi / 180),
                                y: global_variable.ringSize / 2 + (innerRadius - 20) * sin((Double(i) * 15 - 90) * .pi / 180)
                            )
                    }
                }//group结束
            }//圆环zstack结束
            // 扩大可拖拽区域到整个圆
            .frame(width: ringSize, height: ringSize)
            // Make the entire circle tappable/dragable
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let angle = calculateAngle(from: value.location)
                        
                        // Lock which knob on first drag event
                        if activeKnob == nil {
                            let dStart = abs(shortestAngleDiff(angle, startAngle))
                            let dEnd   = abs(shortestAngleDiff(angle, endAngle))
                            activeKnob = (dStart < dEnd) ? .start : .end
                        }
                        
                        switch activeKnob {
                        case .start:
                            isStartKnobActive = true
                            updateStartAngle(to: angle)
                        case .end:
                            isEndKnobActive = true
                            updateEndAngle(to: angle)
                        case .none:
                            break
                        }
                    }
                    .onEnded { _ in
                        isStartKnobActive = false
                        isEndKnobActive   = false
                        activeKnob        = nil
                        
//                        // 计算当前 endAngle 对应的小时和分钟
//                        let wakeHourDouble = angleToTime(endAngle)
//                        let hour   = Int(wakeHourDouble)
//                        let minute = Int((wakeHourDouble - Double(hour)) * 60)
//                        
//                        // 调度本地通知
//                        scheduleAlarmNotification(hour24: hour, minute: minute)
                        // 计算小时/分钟并写入模型
                            let wakeHourDouble = angleToTime(endAngle)
                            model.wakeHour   = Int(wakeHourDouble)
                            model.wakeMinute = Int((wakeHourDouble - Double(model.wakeHour)) * 60)
                    }
            )
            
            Group{
                Image(systemName: "moon.stars.fill")
                    .foregroundColor(.mint)
                    .position(x:global_variable.ringSize/2,y:70)
                Image(systemName: "sun.max.fill")
                    .foregroundColor(.yellow)
                    .position(x:global_variable.ringSize/2,y:global_variable.ringSize - 70)
            }//group结束
            
        }//圆环上Vstack结束
        .frame(width: global_variable.ringSize, height: global_variable.ringSize)
    }
    
    private func updateStartAngle(to angle: Double) {
        let newSleepTime = angle / 15.0
        let wakeTime     = angleToTime(endAngle)
        var duration     = wakeTime - newSleepTime
        if duration < 0 { duration += 24 }

        if duration < minTimeDelta {
            // 最小间隔：推 endAngle
            let clampedWakeTime = newSleepTime + minTimeDelta
            startAngle = angle
            endAngle   = timeToAngle(clampedWakeTime)
        } else if duration > maxSleepHours {
            // 最大间隔：推 endAngle
            let clampedWakeTime = newSleepTime + maxSleepHours
            startAngle = angle
            endAngle   = timeToAngle(clampedWakeTime)
        } else {
            // 自由区间
            startAngle = angle
        }
    }

    private func updateEndAngle(to angle: Double) {
        let newWakeTime = angle / 15.0
        let sleepTime   = angleToTime(startAngle)
        var duration    = newWakeTime - sleepTime
        if duration < 0 { duration += 24 }

        if duration < minTimeDelta {
            // 最小间隔：推 startAngle
            let clampedSleepTime = newWakeTime - minTimeDelta
            endAngle   = angle
            startAngle = timeToAngle(clampedSleepTime)
        } else if duration > maxSleepHours {
            // 最大间隔：推 startAngle
            let clampedSleepTime = newWakeTime - maxSleepHours
            endAngle   = angle
            startAngle = timeToAngle(clampedSleepTime)
        } else {
            // 自由区间
            endAngle = angle
        }
    }
}


//圆环之下
struct BottomView:View {
    let startAngle: Double
    let endAngle: Double
    @Binding var selectedHour: Int
    @Binding var selectedMinute: Int
    @Binding var showPicker: Bool
    @Binding var if_satisfied:Bool
    
    var body: some View {
        VStack{
            // 5. 计算并显示睡眠时长
            let sleepHours = calculateSleepHours(start: startAngle, end: endAngle)
            let sleepTimes = caculate_Hours_and_minutes(hours: sleepHours)
            Text(sleepTimes)
                .font(.title2)
                .foregroundColor(.primary)
            Spacer()
            
            let sleep_goal_hour = formatTimeHour(selectedHour, selectedMinute)
            Text(
                sleepHours >= sleep_goal_hour
                ? "This schedule meets your sleep goal"
                : "This schedule does not meet your sleep goal"
            )
            .font(.footnote)
            .foregroundStyle(.gray)
            
            NavigationView {
                Form {
                    // 点击这行，会弹出“下拉”样式的轮式选择器
                    Button {
                        showPicker.toggle()
                    } label: {
                        HStack {
                            Text("Sleep Goal").foregroundColor(.black)
                            Spacer()
                            Text("\(selectedHour) hr \(selectedMinute) min")
                                .foregroundColor(.gray)
                        }
                    }
                }.scrollContentBackground(.hidden)  // 隐藏默认背景
                    .background(Color.white)           // 设置背景为白色
                    .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 2)
                // 弹窗：在 iPhone 上会从底部出现，在 iPad 上则可能是表单样式
                    .sheet(isPresented: $showPicker) {
                        SleepGoalSheetView(
                            selectedHour: $selectedHour,
                            selectedMinute: $selectedMinute)
                    }
            }//Vstack结束
            .padding()
        }
    }
}
    struct BedtimeWakeupView_Previews: PreviewProvider {
        static var previews: some View {
            BedtimeWakeupView()
        }
    }
    
