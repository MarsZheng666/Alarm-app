//
//  Function.swift
//  Alarm
//
//  Created by 郑席明 on 07/04/2025.
//

import Foundation
import SwiftUI


/// 将拖拽位置转换为 [0, 360) 范围的角度（顶部为 0°, 顺时针增加）
func pointToAngle(_ point: CGPoint) -> Double {
    // 圆心在容器中心，这里把坐标原点视为容器中心(0,0)
    // 需要先将拖拽位置从绝对坐标转换为以容器中心为原点的坐标
    let center = CGPoint(x:global_variable.ringSize / 2, y: global_variable.ringSize / 2)
    let dx = point.x - center.x
    let dy = point.y - center.y
    
    // atan2 的 0° 是在 x 轴正方向，这里我们想让顶部是 0°
    // 所以先算出弧度后，再转换成度数，并进行角度修正
    let radians = atan2(dy, dx)  // [-π, π]
    var degreesValue = radians * 180 / .pi
    
    // 让顶部 ( -π/2 ) = 0°
    // 所以需要先加 90° (因为顶部比 x 轴正方向少了 90°)
    degreesValue += 90
    
    // 将角度限制在 [0, 360) 范围内
    if degreesValue < 0 {
        degreesValue += 360
    }
    
    return degreesValue
}

/// 将角度转换为时间（小时，范围 0～12）
func angleToTime(_ angle: Double) -> Double {
    // 调整角度：让顶部（-90°偏移）对应 0 小时
    let adjusted = (angle).truncatingRemainder(dividingBy: 360)
    return adjusted / 15.0  // 每 15°对应 1 小时
    }

/// 将时间转换为角度（0～360）
func timeToAngle(_ time: Double) -> Double {
    // 公式反推：time = ((angle+90)%360)/30  => angle = time*30 - 90
    let angle = time * 15
    let modAngle = (angle.truncatingRemainder(dividingBy:360)+360).truncatingRemainder(dividingBy: 360)
    return modAngle
    }

/// 根据开始角度和结束角度，计算对应小时差
func calculateSleepHours(start: Double, end: Double) -> Double {
    // 1. 计算角度差
    var angleDiff = end - start
    if angleDiff < 0 {
        angleDiff += 360
    }
    // 2. 将角度转换为小时
    // 360° 对应 12 小时 => 1 小时对应 30°
    // 如果你想对应 24 小时，可自行调整换算公式
    let hours = angleDiff / 15.0
    return hours
}

func calculateSleepAngles(start: Double, end: Double) -> Double {
    var angleDiff = end - start
    if angleDiff < 0 {
        angleDiff += 360
    }
    return angleDiff / 15.0
}

//根据小时差计算分钟
func caculate_Hours_and_minutes(hours:Double)-> String{
    // 将小时转换为总分钟数
        let totalMinutes = hours * 60
        // 四舍五入到最近的 5 分钟
        let roundedMinutes = Int((totalMinutes / 5).rounded() * 5)
        // 分解为小时和分钟
        var hoursPart = roundedMinutes / 60
        var minutesPart = roundedMinutes % 60
        // 如果分钟数达到60，则转换为下一个整点
        if minutesPart == 60 {
            hoursPart += 1
            minutesPart = 0
        }
        if minutesPart == 0 {
            return "\(hoursPart)hr"
        } else {
            return "\(hoursPart)hr \(minutesPart)min"
        }
}

/// 滑块视图
func knobView(color: Color, isActive: Bool = false,centerDotColor:Color? = nil) -> some View {
    return Circle()
        .fill(Color.white)
        .overlay(
                Group {
                        if let dotColor = centerDotColor {
                            Circle()
                                .fill(dotColor)
                                .frame(width: global_variable.knobSize / 2+3, height: global_variable.knobSize / 2+3)
                        }
                    }
                )
        .shadow(radius: isActive ? 5 : 3)
        .frame(width: global_variable.knobSize, height: global_variable.knobSize)
                .scaleEffect(isActive ? 1.3 : 1.0)
}

// 将 24 小时制数值转换为 "HH:mm" 格式的字符串
func formatTimeHHmm(_ hour24: Double) -> String {
    let totalMinutes = Int(hour24 * 60)
    let hh = totalMinutes / 60
    let mm = totalMinutes % 60
    return String(format: "%02d:%02d", hh, mm)
}

/// 获取当前系统小时
func decimalHour(from date: Date = Date()) -> Double {
    let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
    let hour = Double(comps.hour ?? 0)
    let minute = Double(comps.minute ?? 0)
    return hour + minute / 60.0
}

// 根据小时数返回 Today 或 Tomorrow
func dayString(for hour24: Double) -> String {
    let nowHour = decimalHour()
    if(hour24 > nowHour && hour24 < 24){
        return "Today"
    }
    else{
        return "Tomorrow"
    }
   
}

//把小时+分钟转成小时
func formatTimeHour(_ hour: Int, _ minute: Int) -> Double {
    return Double(hour) + Double(minute) / 60.0
}



/// 计算最短的角度差（带符号，范围 ±180°）
    func shortestAngleDiff(_ a: Double, _ b: Double) -> Double {
        var diff = a - b
        if diff > 180 { diff -= 360 }
        if diff < -180 { diff += 360 }
        return diff
    }

// 计算触摸点到角度的辅助
   func calculateAngle(from point: CGPoint) -> Double {
       let center = CGPoint(x: global_variable.ringSize/2, y: global_variable.ringSize/2)
       let dx = point.x - center.x
       let dy = point.y - center.y
       var deg = atan2(dy, dx) * 180 / .pi + 90
       if deg < 0 { deg += 360 }
       return deg
   }
