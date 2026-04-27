
//
//  PremiumPaywallScree.swift
//  Stepper
//
//  Created by Boris Serzhanovich on 27.04.26.
//

import SwiftUI
import Combine

struct PremiumPlan: Identifiable, Equatable {
    let id = UUID(); let name: String; let price: String; let duration: String; let badge: String?
}

struct PremiumFeature: Identifiable, Equatable {
    let id = UUID(); let title: String; let subtitle: String; let icon: String; let colors: [Color]; let detail: String
}

struct PremiumPaywallScreen: View {
    var onComplete: () -> Void
    
    @State private var selectedPlan: String = "Цикл (Год)"
    @State private var selectedFeature: PremiumFeature? = nil
    @State private var showWelcomeOverlay: Bool = false
    
    let plans: [PremiumPlan] = [
        PremiumPlan(name: "Микро (Нед)", price: "290 ₽", duration: "/ нед", badge: nil),
        PremiumPlan(name: "Макро (Мес)", price: "990 ₽", duration: "/ мес", badge: "БАЗОВЫЙ УЗЕЛ"),
        PremiumPlan(name: "Цикл (Год)", price: "5 990 ₽", duration: "/ год", badge: "МАКС. ЭФФЕКТИВНОСТЬ (-60%)")
    ]
    
    var body: some View {
        ZStack {
            CyberBackgroundView()
            
            VStack(spacing: 0) {
                TopHeaderBar(onComplete: onComplete)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 35) {
                        AnalyzingProgressView()
                        CyberHeaderView()
                        ProfileReadyBadgeView()
                        FeatureCarouselView(selectedFeature: $selectedFeature)
                        CyberBentoGrid()
                        ProsConsCyberView()
                        PricingPlansView(plans: plans, selectedPlan: $selectedPlan)
                        SafeTrialTimelineView()
                        Spacer().frame(height: 180)
                    }
                    .padding(.top, 10)
                }
            }
            .frame(maxWidth: 430)
            
            PremiumCTA(selectedPlan: selectedPlan, plans: plans) {
                CyberHapticManager.playMediumImpact()
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { showWelcomeOverlay = true }
            }
            
            if let feature = selectedFeature {
                FeatureDetailOverlay(feature: feature) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { selectedFeature = nil; CyberHapticManager.playLightImpact() }
                }.transition(.scale(scale: 0.8).combined(with: .opacity)).zIndex(100)
            }
            
            if showWelcomeOverlay {
                WelcomePremiumOverlay {
                    CyberHapticManager.playHeavyImpact()
                    // Передача управления в главное приложение!
                    onComplete()
                }.transition(.scale(scale: 0.8).combined(with: .opacity)).zIndex(200)
            }
        }
    }
}

// MARK: - КОМПОНЕНТЫ PAYWALL
private struct CyberBackgroundView: View {
    @State private var isAnimating = false
    var body: some View {
        ZStack {
            Color.cyberDark.ignoresSafeArea()
            GeometryReader { geo in Path { path in
                for x in stride(from: 0, to: geo.size.width, by: 40) { path.move(to: CGPoint(x: x, y: 0)); path.addLine(to: CGPoint(x: x, y: geo.size.height)) }
                for y in stride(from: 0, to: geo.size.height, by: 40) { path.move(to: CGPoint(x: 0, y: y)); path.addLine(to: CGPoint(x: geo.size.width, y: y)) }
            }.stroke(Color.white.opacity(0.06), lineWidth: 1) }.ignoresSafeArea()
            Circle().fill(Color.cyberCyan.opacity(0.25)).frame(width: 300).blur(radius: 60).offset(x: isAnimating ? 100 : -50, y: isAnimating ? -100 : -200)
            Circle().fill(Color.cyberPurple.opacity(0.2)).frame(width: 350).blur(radius: 80).offset(x: isAnimating ? -100 : 150, y: isAnimating ? 200 : 100)
        }.onAppear { withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) { isAnimating = true } }
    }
}

private struct TopHeaderBar: View {
    var onComplete: () -> Void
    var body: some View { HStack { Spacer(); Button("Пропустить") { onComplete() }.font(.system(size: 13, weight: .bold, design: .monospaced)).foregroundStyle(.white.opacity(0.5)).padding(.trailing, 20).padding(.top, 10) } }
}

private struct AnalyzingProgressView: View {
    @State private var progress: CGFloat = 0.0
    var body: some View { HStack { Text("СИНХРОНИЗАЦИЯ").font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundStyle(.white.opacity(0.8)); GeometryReader { geo in ZStack(alignment: .leading) { Capsule().fill(Color.white.opacity(0.2)); Capsule().fill(LinearGradient(colors: [.cyberCyan, .cyberNeon], startPoint: .leading, endPoint: .trailing)).frame(width: geo.size.width * progress).shadow(color: .cyberCyan.opacity(0.8), radius: 5) } }.frame(height: 6); Text("\(Int(progress * 100))%").font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundStyle(.cyberCyan) }.padding(.horizontal, 20).onAppear { withAnimation(.easeInOut(duration: 2.0)) { progress = 1.0 } } }
}

private struct CyberHeaderView: View {
    var body: some View { VStack(spacing: 12) { Text("AI KINETIC CORE").font(.system(size: 14, weight: .bold, design: .monospaced)).foregroundStyle(.cyberNeon).tracking(2); Text("Оцифруй каждый шаг.\nСжигай калории.").font(.system(size: 32, weight: .black, design: .monospaced)).foregroundStyle(.white).multilineTextAlignment(.center).minimumScaleFactor(0.5).lineLimit(2).padding(.horizontal, 10); Text("Нейросеть анализирует твою биомеханику, маршруты и темп, создавая идеальный план активности.").font(.system(size: 15, weight: .medium, design: .rounded)).foregroundStyle(.white.opacity(0.8)).multilineTextAlignment(.center).padding(.horizontal, 20) } }
}

private struct ProfileReadyBadgeView: View {
    var body: some View { HStack(spacing: 12) { Image(systemName: "checkmark.seal.fill").font(.system(size: 22)).foregroundStyle(.cyberNeon); VStack(alignment: .leading, spacing: 2) { Text("КИНЕТИКА ПРОАНАЛИЗИРОВАНА").font(.system(size: 12, weight: .black, design: .monospaced)).foregroundStyle(.cyberNeon); Text("Алгоритм шагов адаптирован под вас").font(.system(size: 13, weight: .medium)).foregroundStyle(.white) }; Spacer() }.padding(.horizontal, 16).padding(.vertical, 14).background(Color.cyberNeon.opacity(0.15)).clipShape(RoundedRectangle(cornerRadius: 12)).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cyberNeon.opacity(0.6), lineWidth: 1.5)).shadow(color: .cyberNeon.opacity(0.2), radius: 10).padding(.horizontal, 20) }
}

private struct FeatureCarouselView: View {
    @Binding var selectedFeature: PremiumFeature?
    let features = [
        PremiumFeature(title: "AI Анти-Чит", subtitle: "Фильтрация мусора", icon: "shield.lefthalf.filled", colors: [.cyberCyan, .blue], detail: "Нейросеть с точностью 99.9% отличает реальные шаги от поездки в авто, метро или случайной тряски телефоном в кармане."),
        PremiumFeature(title: "Биомеханика", subtitle: "Анализ походки", icon: "figure.walk.arrival", colors: [.cyberPurple, .pink], detail: "Интеграция с HealthKit для глубокого анализа: время двойной опоры, длина шага, асимметрия. ИИ выявит проблемы с суставами до появления боли."),
        PremiumFeature(title: "Smart Маршруты", subtitle: "Генератор локаций", icon: "map.fill", colors: [.cyberNeon, .green], detail: "Укажи желаемый расход калорий, и нейросеть построит идеальный маршрут по твоему городу, учитывая перепады высот и зеленые зоны."),
        PremiumFeature(title: "Нейро-Коуч", subtitle: "Мотиватор", icon: "brain", colors: [.orange, .yellow], detail: "ИИ анализирует твои спады активности и генерирует персональные аудио-подсказки.")
    ]
    var body: some View { ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 16) { ForEach(features) { feature in FeatureCardCyber(feature: feature) { CyberHapticManager.playLightImpact(); withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { selectedFeature = feature } } } }.padding(.horizontal, 20).padding(.vertical, 10) } }
}

private struct FeatureCardCyber: View {
    let feature: PremiumFeature; let action: () -> Void
    var body: some View { let bgGradient = LinearGradient(colors: feature.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
        Button(action: action) { VStack(alignment: .leading, spacing: 16) { Image(systemName: feature.icon).font(.system(size: 32)).foregroundStyle(bgGradient).shadow(color: feature.colors[0].opacity(0.8), radius: 8); VStack(alignment: .leading, spacing: 4) { Text(feature.title).font(.system(size: 15, weight: .bold, design: .monospaced)).foregroundStyle(.white); Text(feature.subtitle).font(.system(size: 11, weight: .bold)).foregroundStyle(.white.opacity(0.7)) } }.padding(20).frame(width: 200, alignment: .leading).background(Color.white.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous)).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.2), lineWidth: 1.5)).shadow(color: .black.opacity(0.1), radius: 10, y: 4) }.buttonStyle(.plain)
    }
}

private struct FeatureDetailOverlay: View {
    let feature: PremiumFeature; let onClose: () -> Void; @State private var isPulsing = false
    var body: some View { let iconGradient = LinearGradient(colors: feature.colors, startPoint: .topLeading, endPoint: .bottomTrailing); let btnGradient = LinearGradient(colors: feature.colors, startPoint: .leading, endPoint: .trailing)
        ZStack { Color.black.opacity(0.5).ignoresSafeArea().onTapGesture { onClose() }
            VStack(spacing: 24) { Image(systemName: feature.icon).font(.system(size: 50)).foregroundStyle(iconGradient).shadow(color: feature.colors[0].opacity(0.8), radius: isPulsing ? 25 : 10).scaleEffect(isPulsing ? 1.05 : 1.0); VStack(spacing: 8) { Text(feature.title).font(.system(size: 26, weight: .black, design: .monospaced)).foregroundStyle(.white).multilineTextAlignment(.center); Text(feature.subtitle).font(.system(size: 14, weight: .bold, design: .monospaced)).foregroundStyle(feature.colors[0]) }; Text(feature.detail).font(.system(size: 15, weight: .medium, design: .rounded)).foregroundStyle(.white.opacity(0.8)).multilineTextAlignment(.center).lineSpacing(6).padding(.horizontal, 10); Button(action: onClose) { Text("ДАННЫЕ ПРИНЯТЫ").font(.system(size: 15, weight: .bold, design: .monospaced)).foregroundStyle(.black).frame(maxWidth: .infinity).frame(height: 56).background(btnGradient).clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous)).shadow(color: feature.colors[0].opacity(0.6), radius: 15, y: 5) }.padding(.top, 10) }.padding(32).background(Color.cyberPanel).clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous)).overlay(RoundedRectangle(cornerRadius: 24).stroke(feature.colors[0].opacity(0.6), lineWidth: 2)).shadow(color: feature.colors[0].opacity(0.2), radius: 30).padding(.horizontal, 24).onAppear { withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) { isPulsing = true } }
        }
    }
}

private struct CyberBentoGrid: View {
    var body: some View { VStack(spacing: 12) { HStack(spacing: 12) { BentoCardCyber(icon: "figure.walk", title: "Биомеханика", color: .cyberNeon); BentoCardCyber(icon: "brain", title: "100% ИИ", color: .cyberCyan) }; HStack(spacing: 12) { BentoCardCyber(icon: "map.fill", title: "Smart-Карты", color: .cyberPurple); BentoCardCyber(icon: "applewatch", title: "Health Sync", color: .blue) } }.padding(.horizontal, 20) }
}
private struct BentoCardCyber: View {
    let icon: String; let title: String; let color: Color
    var body: some View { HStack(spacing: 10) { Image(systemName: icon).font(.system(size: 18, weight: .bold)).foregroundStyle(color); Text(title).font(.system(size: 13, weight: .bold, design: .monospaced)).foregroundStyle(.white).minimumScaleFactor(0.8).lineLimit(1); Spacer() }.padding(16).background(Color.white.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 12)).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.2), lineWidth: 1)) }
}

private struct ProsConsCyberView: View {
    var body: some View {
        VStack(spacing: 16) { Text("АНАЛИЗ ЭФФЕКТИВНОСТИ").font(.system(size: 13, weight: .bold, design: .monospaced)).foregroundStyle(.gray.opacity(0.8)).tracking(2)
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 12) { HStack { Image(systemName: "xmark.circle.fill").foregroundStyle(.gray.opacity(0.8)); Text("ГЛУПЫЙ ШАГОМЕР").font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundStyle(.gray.opacity(0.9)).minimumScaleFactor(0.8).lineLimit(1) }.padding(.bottom, 4); ComparisonRowCyber(icon: "minus", color: .gray, text: "Считает тряску авто"); ComparisonRowCyber(icon: "minus", color: .gray, text: "Игнорирует темп"); ComparisonRowCyber(icon: "minus", color: .gray, text: "Мертвые цифры"); ComparisonRowCyber(icon: "minus", color: .gray, text: "Ноль мотивации"); Spacer() }.padding(16).frame(maxWidth: .infinity, alignment: .leading).background(Color.white.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 16)).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.15), lineWidth: 1))
                VStack(alignment: .leading, spacing: 12) { HStack { Image(systemName: "bolt.fill").foregroundStyle(.cyberCyan); Text("AI-КИНЕТИКА").font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundStyle(.cyberCyan).minimumScaleFactor(0.8).lineLimit(1) }.padding(.bottom, 4); ComparisonRowCyber(icon: "checkmark", color: .cyberCyan, text: "Анти-Чит ИИ"); ComparisonRowCyber(icon: "checkmark", color: .cyberCyan, text: "Анализ биомеханики"); ComparisonRowCyber(icon: "checkmark", color: .cyberCyan, text: "Smart-маршруты"); ComparisonRowCyber(icon: "checkmark", color: .cyberCyan, text: "Нейро-геймификация"); Spacer() }.padding(16).frame(maxWidth: .infinity, alignment: .leading).background(Color.cyberCyan.opacity(0.15)).clipShape(RoundedRectangle(cornerRadius: 16)).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.cyberCyan.opacity(0.8), lineWidth: 1.5)).shadow(color: .cyberCyan.opacity(0.2), radius: 15, y: 5).scaleEffect(1.02)
            }
        }.padding(.horizontal, 20)
    }
}
private struct ComparisonRowCyber: View { let icon: String; let color: Color; let text: String; var body: some View { HStack(alignment: .top, spacing: 8) { Image(systemName: icon).font(.system(size: 12, weight: .bold)).foregroundStyle(color).padding(.top, 2); Text(text).font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(.white).fixedSize(horizontal: false, vertical: true).lineLimit(2) } } }

private struct PricingPlansView: View {
    let plans: [PremiumPlan]; @Binding var selectedPlan: String
    var body: some View { VStack(spacing: 16) { ForEach(plans) { plan in PlanRowCyberView(plan: plan, isSelected: selectedPlan == plan.name) { withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { selectedPlan = plan.name; CyberHapticManager.playSelection() } } } }.padding(.horizontal, 20) }
}
private struct PlanRowCyberView: View {
    let plan: PremiumPlan; let isSelected: Bool; let action: () -> Void
    var body: some View { Button(action: action) { HStack { RoundedRectangle(cornerRadius: 6).stroke(isSelected ? .cyberCyan : .white.opacity(0.3), lineWidth: 2).frame(width: 22, height: 22).overlay(RoundedRectangle(cornerRadius: 3).fill(isSelected ? .cyberCyan : .clear).frame(width: 10, height: 10)); VStack(alignment: .leading, spacing: 4) { Text(plan.name).font(.system(size: 16, weight: .bold, design: .monospaced)).foregroundStyle(.white); if let badge = plan.badge { Text(badge).font(.system(size: 10, weight: .black, design: .monospaced)).padding(.horizontal, 8).padding(.vertical, 4).background(isSelected ? .cyberCyan : .white.opacity(0.2)).foregroundStyle(isSelected ? .black : .white).clipShape(RoundedRectangle(cornerRadius: 4)) } }.padding(.leading, 10); Spacer(); VStack(alignment: .trailing) { Text(plan.price).font(.system(size: 18, weight: .black, design: .monospaced)).foregroundStyle(.white); Text(plan.duration).font(.system(size: 12, weight: .medium, design: .monospaced)).foregroundStyle(.white.opacity(0.7)) } }.padding(20).background(isSelected ? Color.cyberCyan.opacity(0.15) : Color.white.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous)).shadow(color: isSelected ? .cyberCyan.opacity(0.3) : .clear, radius: 15, y: 5).overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(isSelected ? .cyberCyan : .white.opacity(0.15), lineWidth: isSelected ? 2 : 1)).scaleEffect(isSelected ? 1.02 : 1.0) }.buttonStyle(.plain) }
}

private struct PremiumCTA: View {
    let selectedPlan: String; let plans: [PremiumPlan]; let onActivate: () -> Void
    @State private var shimmerOffset: CGFloat = -200; @State private var buttonPulse = false; @State private var timeRemaining = 899
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 16) {
                HStack(spacing: 6) { Image(systemName: "timer").foregroundStyle(.cyberCyan); Text("ПОРТАЛ ЗАКРОЕТСЯ ЧЕРЕЗ: \(String(format: "%02d:%02d", timeRemaining / 60, timeRemaining % 60))").font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundStyle(.cyberCyan) }.padding(.horizontal, 16).padding(.vertical, 8).background(Color.cyberCyan.opacity(0.15)).clipShape(RoundedRectangle(cornerRadius: 8)).overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.cyberCyan.opacity(0.5), lineWidth: 1)).onReceive(timer) { _ in if timeRemaining > 0 { timeRemaining -= 1 } }
                Button(action: onActivate) { ZStack { LinearGradient(colors: [.cyberCyan, .cyberNeon], startPoint: .topLeading, endPoint: .bottomTrailing); LinearGradient(colors: [.clear, .white.opacity(0.8), .clear], startPoint: .leading, endPoint: .trailing).rotationEffect(.degrees(30)).offset(x: shimmerOffset); Text("ИНИЦИАЛИЗИРОВАТЬ").font(.system(size: 17, weight: .black, design: .monospaced)).foregroundStyle(.black) }.frame(height: 64).clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous)).shadow(color: .cyberCyan.opacity(0.6), radius: buttonPulse ? 20 : 10, y: 5).scaleEffect(buttonPulse ? 1.03 : 1.0) }.buttonStyle(.plain).onAppear { withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) { shimmerOffset = 400 }; withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) { buttonPulse = true } }
                Text("Затем \(plans.first(where: { $0.name == selectedPlan })?.price ?? ""). Отмена в 1 клик.").font(.system(size: 12, weight: .medium, design: .monospaced)).foregroundStyle(.gray)
                HStack(spacing: 30) { Text("Директивы").underline(); Text("Восстановить").underline(); Text("Протокол").underline() }.font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundStyle(.gray.opacity(0.7))
            }.padding(.horizontal, 20).padding(.top, 40).padding(.bottom, 20).background(LinearGradient(colors: [.cyberDark.opacity(0), .cyberDark, .cyberDark], startPoint: .top, endPoint: .bottom))
        }
    }
}

private struct WelcomePremiumOverlay: View {
    let onStart: () -> Void; @State private var isPulsing = false
    var body: some View {
        ZStack { Color.black.opacity(0.6).ignoresSafeArea(); VStack(spacing: 24) { ZStack { Circle().fill(Color.cyberCyan.opacity(0.2)).frame(width: 100, height: 100); Image(systemName: "figure.walk.motion").font(.system(size: 45)).foregroundStyle(.cyberCyan).shadow(color: .cyberCyan.opacity(0.8), radius: isPulsing ? 25 : 10).scaleEffect(isPulsing ? 1.08 : 1.0) }; VStack(spacing: 12) { Text("СИСТЕМА ОНЛАЙН").font(.system(size: 26, weight: .black, design: .monospaced)).foregroundStyle(.white).multilineTextAlignment(.center); Text("ДОСТУП К НЕЙРОСЕТИ ОТКРЫТ").font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundStyle(.cyberCyan).tracking(1) }; Text("ИИ проанализировал твои параметры. Тебе больше не нужно думать о норме шагов. Алгоритм сам подстроит цели под твой темп, погоду и рельеф.\n\nДелай шаги. Мы оцифруем результат.").font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(.white.opacity(0.8)).multilineTextAlignment(.center).lineSpacing(4).padding(.horizontal, 8); Button(action: onStart) { Text("ЗАПУСТИТЬ ТРЕКЕР").font(.system(size: 15, weight: .bold, design: .monospaced)).foregroundStyle(.black).frame(maxWidth: .infinity).frame(height: 56).background(LinearGradient(colors: [.cyberCyan, .cyberNeon], startPoint: .leading, endPoint: .trailing)).clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous)).shadow(color: .cyberCyan.opacity(0.6), radius: 15, y: 5) }.padding(.top, 16) }.padding(32).background(Color.cyberPanel).clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous)).overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.cyberCyan.opacity(0.5), lineWidth: 2)).shadow(color: .cyberCyan.opacity(0.2), radius: 30).padding(.horizontal, 24).onAppear { withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) { isPulsing = true } } }
    }
}

private struct SafeTrialTimelineView: View {
    var body: some View { VStack(alignment: .leading, spacing: 0) { Text("ПРОТОКОЛ ТЕСТОВОГО РЕЖИМА:").font(.system(size: 13, weight: .bold, design: .monospaced)).foregroundStyle(.gray.opacity(0.8)).padding(.bottom, 20); TimelineStepCyberView(icon: "lock.open.fill", color: .cyberNeon, title: "Фаза 1: Сейчас", subtitle: "Полный доступ к AI-ядру и GPS-картам. 0 ₽.", isLast: false); TimelineStepCyberView(icon: "bell.badge.fill", color: .orange, title: "Фаза 2: День 5", subtitle: "Системное push-уведомление о скором списании.", isLast: false); TimelineStepCyberView(icon: "star.fill", color: .cyberCyan, title: "Фаза 3: День 7", subtitle: "Активация подписки. Отмена в 1 клик в логах.", isLast: true) }.padding(24).background(Color.white.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 16)).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.15), lineWidth: 1)).shadow(color: .black.opacity(0.2), radius: 10, y: 5).padding(.horizontal, 20) }
}
private struct TimelineStepCyberView: View {
    let icon: String; let color: Color; let title: String; let subtitle: String; let isLast: Bool
    var body: some View { HStack(alignment: .top, spacing: 16) { VStack(spacing: 0) { ZStack { RoundedRectangle(cornerRadius: 8).fill(color.opacity(0.2)).frame(width: 32, height: 32); Image(systemName: icon).font(.system(size: 14, weight: .bold)).foregroundStyle(color) }; if !isLast { Rectangle().fill(Color.white.opacity(0.2)).frame(width: 2, height: 40).padding(.vertical, 4) } }; VStack(alignment: .leading, spacing: 4) { Text(title).font(.system(size: 15, weight: .bold, design: .monospaced)).foregroundStyle(.white); Text(subtitle).font(.system(size: 13, weight: .medium, design: .rounded)).foregroundStyle(.white.opacity(0.7)).fixedSize(horizontal: false, vertical: true) }.padding(.top, 6); Spacer() } }
}
