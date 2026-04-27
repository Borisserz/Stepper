//
//  OnboardingMetricsView.swift
//  Stepper
//
//  Created by Boris Serzhanovich on 27.04.26.
//

import SwiftUI

enum UserActivityLevel: String, CaseIterable {
    case none = "Не выбрано"
    case office = "Офисный режим"
    case light = "Легкая активность"
    case active = "Активный"
    case beast = "Кибер-Атлет"
    
    var emoji: String {
        switch self {
        case .none: return "❓"
        case .office: return "☕️"
        case .light: return "🚶‍♂️"
        case .active: return "🏃‍♂️"
        case .beast: return "🔥"
        }
    }
    
    var description: String {
        switch self {
        case .none: return ""
        case .office: return "Минимум движений, сидячая работа"
        case .light: return "Регулярные прогулки, иногда зарядка"
        case .active: return "Тренировки 2-3 раза в неделю"
        case .beast: return "Ежедневный спорт, высокие нагрузки"
        }
    }
}

struct UserMetrics {
    var age: Int = 25
    var height: Int = 175
    var weight: Int = 75
    var activityLevel: UserActivityLevel = .none
}

struct OnboardingMetricsView: View {
    var onComplete: () -> Void
    
    enum Step {
        case metrics
        case activity
        case finish
    }
    
    @State private var step: Step = .metrics
    @State private var metrics = UserMetrics()
    
    var body: some View {
        ZStack {
            Color(red: 0.02, green: 0.03, blue: 0.06).ignoresSafeArea()
            
            if step == .metrics || step == .activity {
                AnimatedCyberBackground()
            }
            
            VStack {
                switch step {
                case .metrics:
                    MetricsScreen(metrics: $metrics, onNext: { navigate(to: .activity) })
                        .transition(pushTransition)
                case .activity:
                    ActivityScreen(metrics: $metrics, onNext: { navigate(to: .finish) })
                        .transition(pushTransition)
                case .finish:
                    FinishScreen(onCalculationComplete: onComplete)
                }
            }
            .frame(maxWidth: 430)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: step)
        }
        .preferredColorScheme(.dark)
    }
    
    private var pushTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
    
    private func navigate(to nextStep: Step) {
        CyberHapticManager.playLightImpact()
        step = nextStep
    }
}

// MARK: - ЭКРАНЫ КАЛИБРОВКИ МЕТРИК
private struct MetricsScreen: View {
    @Binding var metrics: UserMetrics
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("Калибровка Аватара")
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                
                Text("Ввод базовых физических параметров")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.6))
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
            }
            .padding(.top, 40)
            
            Spacer()
            
            HStack(spacing: 0) {
                WheelColumn(title: "Возраст", range: 14...100, suffix: "лет", selection: $metrics.age)
                WheelColumn(title: "Рост", range: 140...230, suffix: "см", selection: $metrics.height)
                WheelColumn(title: "Вес", range: 40...200, suffix: "кг", selection: $metrics.weight)
            }
            .frame(height: 220)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.cyan.opacity(0.05))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.cyan.opacity(0.3), lineWidth: 1))
            )
            .padding(.horizontal, 24)
            
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "cpu")
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(.cyan)
                
                Text("Нейронный процессор использует эти данные для точного расчета длины шага и сжигаемых калорий.")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(.cyan.opacity(0.8))
                    .lineSpacing(2)
            }
            .padding(16)
            .background(Color.cyan.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, 24)
            .padding(.top, 30)
            
            Spacer()
            
            CyberMetricButton(title: "Подтвердить параметры", action: onNext)
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
        }
    }
}

private struct WheelColumn: View {
    let title: String
    let range: ClosedRange<Int>
    let suffix: String
    @Binding var selection: Int
    
    var body: some View {
        VStack(spacing: -10) {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(.cyan.opacity(0.6))
                .padding(.bottom, 10)
                .minimumScaleFactor(0.8)
            
            Picker(title, selection: $selection) {
                ForEach(range, id: \.self) { value in
                    Text("\(value) \(suffix)")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .tag(value)
                }
            }
            #if os(iOS)
            .pickerStyle(.wheel)
            #else
            .pickerStyle(.automatic)
            #endif
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ActivityScreen: View {
    @Binding var metrics: UserMetrics
    let onNext: () -> Void
    
    let levels: [UserActivityLevel] = [.office, .light, .active, .beast]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Кинетика")
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                Text("Оцени свой ежедневный паттерн движения.")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(.horizontal, 24)
            .padding(.top, 40)
            .padding(.bottom, 30)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(levels, id: \.self) { type in
                        ActivityCard(type: type, isSelected: metrics.activityLevel == type) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                metrics.activityLevel = type
                                CyberHapticManager.playSelection()
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
            
            Spacer(minLength: 0)
            
            CyberMetricButton(title: "Подключить трекер", action: onNext, isDisabled: metrics.activityLevel == .none)
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
                .padding(.top, 10)
        }
    }
}

private struct ActivityCard: View {
    let type: UserActivityLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Text(type.emoji)
                    .font(.system(size: 24))
                    .frame(width: 46, height: 46)
                    .background(isSelected ? Color.cyan.opacity(0.2) : Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(type.rawValue)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                    
                    Text(type.description)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                        .minimumScaleFactor(0.8)
                        .lineLimit(2)
                }
                
                Spacer(minLength: 0)
                
                if isSelected {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.cyan)
                        .transition(.scale)
                }
            }
            .padding(14)
            .background(isSelected ? Color.cyan.opacity(0.1) : Color.white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.cyan : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

private struct FinishScreen: View {
    let onCalculationComplete: () -> Void
    
    @State private var animateUI = false
    @State private var isAbsorbing = false
    @State private var fadeOutToNext = false
    @State private var engine = AICalibrationEngine()
    
    var body: some View {
        ZStack {
            Color(red: 0.02, green: 0.03, blue: 0.06).ignoresSafeArea()
            
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    engine.update(time: timeline.date.timeIntervalSinceReferenceDate)
                    engine.draw(context: &context, size: size)
                }
            }
            .ignoresSafeArea()
            .opacity(animateUI ? 1 : 0)
            
            VStack(spacing: 24) {
                Spacer()
                
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.cyan.opacity(0.15))
                        .frame(width: 100, height: 100)
                        .blur(radius: 15)
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 46))
                        .foregroundStyle(LinearGradient(colors: [.cyan, .purple], startPoint: .top, endPoint: .bottom))
                }
                
                VStack(spacing: 8) {
                    Text("Алгоритмы настроены")
                        .font(.system(size: 26, weight: .black, design: .monospaced))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    Text("Биомеханический профиль загружен.\nИИ готов отслеживать каждый твой шаг.\n\nСистема переведена в активный режим.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .lineSpacing(4)
                        .minimumScaleFactor(0.8)
                }
                
                Spacer()
                
                CyberMetricButton(title: "Запустить сканирование") {
                    startAICalibration()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
            }
            .scaleEffect(isAbsorbing ? 0.001 : (animateUI ? 1 : 0.9))
            .opacity(isAbsorbing ? 0 : (animateUI ? 1 : 0))
            
            Rectangle()
                .fill(Color(red: 0.02, green: 0.03, blue: 0.06))
                .ignoresSafeArea()
                .opacity(fadeOutToNext ? 1 : 0)
        }
        .onAppear {
            CyberHapticManager.playSuccess()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animateUI = true
            }
        }
    }
    
    private func startAICalibration() {
        CyberHapticManager.playLightImpact()
        withAnimation(.easeIn(duration: 1.5)) {
            isAbsorbing = true
        }
        engine.startCalibration()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { CyberHapticManager.playLightImpact() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { CyberHapticManager.playMediumImpact() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            CyberHapticManager.playHeavyImpact()
            withAnimation(.easeInOut(duration: 1.0)) { fadeOutToNext = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { onCalculationComplete() }
    }
}

// MARK: - РАДАР (Canvas)
private class AICalibrationEngine {
    struct DataPacket {
        var angle: Double; var radius: Double; var speed: Double; var color: Color; var length: Double
    }
    
    var packets: [DataPacket] = []
    var startTime: TimeInterval = 0
    var currentTime: TimeInterval = 0
    var isCalibrating = false
    var calibrationProgress: Double = 0.0
    
    init() {
        let colors: [Color] = [.cyan, .purple, .blue, .white]
        for _ in 0..<150 {
            packets.append(
                DataPacket(
                    angle: Double.random(in: 0...2 * .pi),
                    radius: Double.random(in: 150...1000),
                    speed: Double.random(in: 20...60),
                    color: colors.randomElement()!,
                    length: Double.random(in: 10...40)
                )
            )
        }
    }
    
    func startCalibration() {
        isCalibrating = true
    }
    
    func update(time: TimeInterval) {
        if startTime == 0 { startTime = time }
        currentTime = time
        let dt = 0.016
        
        if isCalibrating {
            calibrationProgress = min((time - startTime) / 3.5, 1.0)
        }
        
        let suckMultiplier = 1.0 + (calibrationProgress * 15.0)
        
        for i in 0..<packets.count {
            if isCalibrating {
                packets[i].radius -= packets[i].speed * suckMultiplier * dt
                if packets[i].radius < 20 && calibrationProgress < 0.8 {
                    packets[i].radius = Double.random(in: 500...1000)
                    packets[i].angle = Double.random(in: 0...2 * .pi)
                }
            } else {
                packets[i].radius -= packets[i].speed * 0.1 * dt
                if packets[i].radius < 50 {
                    packets[i].radius = Double.random(in: 800...1000)
                }
            }
        }
    }
    
    func draw(context: inout GraphicsContext, size: CGSize) {
        let cx = Double(size.width / 2)
        let cy = Double(size.height / 2)
        
        for p in packets {
            if p.radius < 30 { continue }
            let tailRadius = p.radius + (p.length * (1.0 + calibrationProgress * 2))
            let px = cx + cos(p.angle) * p.radius
            let py = cy + sin(p.angle) * p.radius
            let tx = cx + cos(p.angle) * tailRadius
            let ty = cy + sin(p.angle) * tailRadius
            
            var path = Path()
            path.move(to: CGPoint(x: px, y: py))
            path.addLine(to: CGPoint(x: tx, y: ty))
            
            let fadeOut = calibrationProgress > 0.8 ? (1.0 - calibrationProgress) * 5.0 : 1.0
            let alpha = (isCalibrating ? min(0.8, 0.2 + calibrationProgress) : 0.2) * fadeOut
            
            context.stroke(path, with: .color(p.color.opacity(alpha)), style: StrokeStyle(lineWidth: 1.5, lineCap: .square))
        }
        
        if calibrationProgress > 0.05 {
            let scale = 1 + 2.70158 * pow(calibrationProgress - 1, 3) + 1.70158 * pow(calibrationProgress - 1, 2) * 1.5
            var coreContext = context
            coreContext.translateBy(x: CGFloat(cx), y: CGFloat(cy))
            coreContext.scaleBy(x: CGFloat(scale), y: CGFloat(scale))
            coreContext.opacity = calibrationProgress > 0.8 ? (1.0 - calibrationProgress) * 5.0 : 1.0
            
            if calibrationProgress > 0.1 {
                var hexCtx = coreContext
                hexCtx.rotate(by: Angle.degrees(currentTime * 30))
                let p1 = max(0, (calibrationProgress - 0.1) * 1.2)
                var hex = Path()
                let radius = 35.0 * p1
                for i in 0..<6 {
                    let angle = Double(i) * (.pi / 3)
                    let pt = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
                    if i == 0 { hex.move(to: pt) } else { hex.addLine(to: pt) }
                }
                hex.closeSubpath()
                hexCtx.fill(hex, with: .color(.cyan.opacity(0.3)))
                hexCtx.stroke(hex, with: .color(.cyan), style: StrokeStyle(lineWidth: 2))
            }
            
            if calibrationProgress > 0.3 {
                let p2 = max(0, (calibrationProgress - 0.3) * 1.4)
                var ring1Ctx = coreContext
                ring1Ctx.rotate(by: Angle.degrees(-currentTime * 90))
                var ring1 = Path()
                ring1.addArc(center: .zero, radius: CGFloat(60 * p2), startAngle: Angle.zero, endAngle: Angle.degrees(360), clockwise: true)
                ring1Ctx.stroke(ring1, with: .color(.purple.opacity(0.8)), style: StrokeStyle(lineWidth: 4, dash: [15, 10, 5, 10]))
            }
            
            if calibrationProgress > 0.5 {
                let p3 = max(0, (calibrationProgress - 0.5) * 2.0)
                var radarCtx = coreContext
                radarCtx.rotate(by: Angle.degrees(currentTime * 45))
                var radarRing = Path()
                radarRing.addArc(center: .zero, radius: CGFloat(100 * p3), startAngle: Angle.zero, endAngle: Angle.degrees(360), clockwise: true)
                radarCtx.stroke(radarRing, with: .color(.cyan.opacity(0.4)), style: StrokeStyle(lineWidth: 1))
                for i in 0..<4 {
                    let angle = Double(i) * (.pi / 2)
                    var tick = Path()
                    tick.move(to: CGPoint(x: cos(angle) * 90 * p3, y: sin(angle) * 90 * p3))
                    tick.addLine(to: CGPoint(x: cos(angle) * 110 * p3, y: sin(angle) * 110 * p3))
                    radarCtx.stroke(tick, with: .color(.cyan), style: StrokeStyle(lineWidth: 3))
                }
            }
            
            if calibrationProgress > 0.6 {
                let p4 = max(0, (calibrationProgress - 0.6) * 2.5)
                var nodeCtx = coreContext
                nodeCtx.rotate(by: Angle.degrees(-currentTime * 15))
                for i in 0..<3 {
                    let angle = Double(i) * ((2 * .pi) / 3)
                    var line = Path()
                    line.move(to: CGPoint(x: cos(angle) * 35, y: sin(angle) * 35))
                    line.addLine(to: CGPoint(x: cos(angle) * 150 * p4, y: sin(angle) * 150 * p4))
                    nodeCtx.stroke(line, with: .color(.purple.opacity(0.5)), style: StrokeStyle(lineWidth: 1.5))
                    var dot = Path()
                    dot.addArc(center: CGPoint(x: cos(angle) * 150 * p4, y: sin(angle) * 150 * p4), radius: 4, startAngle: Angle.zero, endAngle: Angle.degrees(360), clockwise: true)
                    nodeCtx.fill(dot, with: .color(.cyan))
                }
            }
            
            if calibrationProgress > 0.7 {
                let flashP = max(0, (calibrationProgress - 0.7) * 3.3)
                var halo = Path()
                halo.addArc(center: .zero, radius: CGFloat(150 * flashP), startAngle: Angle.zero, endAngle: Angle.degrees(360), clockwise: true)
                var haloContext = coreContext
                haloContext.addFilter(.blur(radius: 30))
                haloContext.fill(halo, with: .color(.cyan.opacity(0.15 * flashP)))
            }
        }
    }
}

// MARK: - ХЕЛПЕРЫ ДЛЯ МЕТРИК
private struct AnimatedCyberBackground: View {
    @State private var move1 = false
    @State private var move2 = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.cyan.opacity(0.1))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: move1 ? 100 : -100, y: move1 ? -150 : 0)
            
            Circle()
                .fill(Color.purple.opacity(0.1))
                .frame(width: 350, height: 350)
                .blur(radius: 100)
                .offset(x: move2 ? -150 : 150, y: move2 ? 200 : 50)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) { move1 = true }
            withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) { move2 = true }
        }
    }
}

private struct CyberMetricButton: View {
    let title: String
    let action: () -> Void
    var isDisabled: Bool = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundStyle(isDisabled ? Color.white.opacity(0.3) : .black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    isDisabled
                    ? AnyShapeStyle(Color.white.opacity(0.05))
                    : AnyShapeStyle(LinearGradient(colors: [.cyan, .cyan.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: isDisabled ? .clear : .cyan.opacity(0.4), radius: 10, y: 0)
        }
        .disabled(isDisabled)
        .buttonStyle(CyberBouncyButtonStyle())
    }
}
