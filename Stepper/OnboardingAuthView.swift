//
//  OnboardingAuthView.swift
//  Stepper
//
//  Created by Boris Serzhanovich on 27.04.26.
//

import SwiftUI

struct OnboardingAuthView: View {
    var onComplete: () -> Void
    
    enum Step {
        case welcome
        case googleSignUp
    }
    
    @Environment(\.openURL) var openURL
    @State private var step: Step = .welcome
    @State private var showGuestModal = false
    @State private var showAppleAlert = false
    @State private var showGoogleAlert = false
    
    var body: some View {
        ZStack {
            Color(red: 0.02, green: 0.03, blue: 0.06).ignoresSafeArea()
            FloatingCyberShapes()
            
            VStack {
                switch step {
                case .welcome:
                    WelcomeStepView(
                        onAppleTap: { showAppleAlert = true },
                        onGoogleTap: { showGoogleAlert = true },
                        onGuestTap: { showGuestModal = true }
                    )
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    
                case .googleSignUp:
                    GoogleRegistrationView(
                        onBack: { withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) { step = .welcome } },
                        onComplete: onComplete
                    )
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .frame(maxWidth: 420)
        }
        .animation(.easeInOut(duration: 0.28), value: step)
        .sheet(isPresented: $showGuestModal) {
            GuestWarningView(
                onStayGuest: { showGuestModal = false; onComplete() },
                onSignIn: { showGuestModal = false; onComplete() }
            )
            .presentationDetents([.fraction(0.48), .medium])
            .presentationDragIndicator(.visible)
            .background(Color(red: 0.05, green: 0.06, blue: 0.1).ignoresSafeArea())
        }
        .alert("Инициализация Apple", isPresented: $showAppleAlert) {
            Button("Продолжить") { onComplete() }
            Button("Отмена", role: .cancel) { }
        } message: { Text("Точка входа Apple Sign In.") }
        .alert("Инициализация Google", isPresented: $showGoogleAlert) {
            Button("Войти") { step = .googleSignUp }
            Button("Отмена", role: .cancel) { }
        } message: { Text("Точка входа Google Sign In.") }
    }
}

// MARK: - КОМПОНЕНТЫ АВТОРИЗАЦИИ
private struct FloatingCyberShapes: View {
    @State private var moveX = false; @State private var moveY = false; @State private var floatZ = false
    var body: some View {
        ZStack {
            Circle().fill(Color.cyan.opacity(0.15)).frame(width: 350, height: 350).blur(radius: 80).offset(x: moveX ? 150 : -100, y: moveY ? -250 : 50).scaleEffect(floatZ ? 1.1 : 0.9)
            CyberEnergyCylinder().scaleEffect(floatZ ? 0.75 : 0.85).rotationEffect(.degrees(-15)).rotation3DEffect(.degrees(moveX ? 7 : -7), axis: (x: 1, y: 0.5, z: 0)).offset(x: moveX ? -110 : -50, y: moveY ? -200 : -140).shadow(color: .cyan.opacity(0.3), radius: 20, x: -10, y: 15)
            HolographicHexagon().scaleEffect(floatZ ? 0.95 : 1.1).rotationEffect(.degrees(moveX ? 15 : -10)).rotation3DEffect(.degrees(moveY ? 12 : -12), axis: (x: 0.5, y: 1, z: 0.2)).offset(x: moveY ? 110 : 160, y: moveX ? -70 : -10).shadow(color: .purple.opacity(0.4), radius: 25, x: -10, y: 15)
            NeuralCoreSphere().scaleEffect(floatZ ? 0.85 : 1.0).rotationEffect(.degrees(-20)).rotation3DEffect(.degrees(moveX ? 8 : -8), axis: (x: 1, y: 0.2, z: 0.5)).offset(x: moveX ? 30 : 90, y: moveY ? 170 : 230).shadow(color: .black.opacity(0.5), radius: 25, x: -15, y: 20)
        }.onAppear {
            withAnimation(.easeInOut(duration: 8.3).repeatForever(autoreverses: true)) { moveX = true }
            withAnimation(.easeInOut(duration: 10.7).repeatForever(autoreverses: true)) { moveY = true }
            withAnimation(.easeInOut(duration: 12.1).repeatForever(autoreverses: true)) { floatZ = true }
        }
    }
}

private struct CyberEnergyCylinder: View {
    var body: some View { ZStack { Capsule().fill(LinearGradient(colors: [.cyan.opacity(0.1), .blue.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 60, height: 180); Capsule().fill(LinearGradient(colors: [.cyan.opacity(0.8), .purple.opacity(0.6)], startPoint: .top, endPoint: .bottom)).frame(width: 40, height: 140).blur(radius: 3); Capsule().fill(Color.white.opacity(0.9)).frame(width: 6, height: 120).blur(radius: 2).shadow(color: .cyan, radius: 10); VStack(spacing: 140) { RoundedRectangle(cornerRadius: 6).fill(LinearGradient(colors: [.gray, .white, .gray], startPoint: .leading, endPoint: .trailing)).frame(width: 64, height: 16); RoundedRectangle(cornerRadius: 6).fill(LinearGradient(colors: [.gray, .white, .gray], startPoint: .leading, endPoint: .trailing)).frame(width: 64, height: 16) }; Capsule().stroke(LinearGradient(colors: [.cyan.opacity(0.8), .purple.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2).frame(width: 60, height: 180) } }
}

private struct HolographicHexagon: View {
    var body: some View { ZStack { PolygonShape(sides: 6).fill(LinearGradient(colors: [.purple.opacity(0.6), .cyan.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 130, height: 130).shadow(color: .purple.opacity(0.5), radius: 15); PolygonShape(sides: 6).fill(Color(red: 0.05, green: 0.05, blue: 0.1)).frame(width: 110, height: 110); PolygonShape(sides: 6).stroke(Color.cyan.opacity(0.8), style: StrokeStyle(lineWidth: 2, dash: [6, 4])).frame(width: 90, height: 90); Circle().fill(Color.white).frame(width: 20, height: 20).shadow(color: .cyan, radius: 10); PolygonShape(sides: 6).stroke(LinearGradient(colors: [.white.opacity(0.8), .clear], startPoint: .top, endPoint: .bottom), lineWidth: 2).frame(width: 130, height: 130) } }
}

private struct NeuralCoreSphere: View {
    var body: some View { ZStack { Circle().fill(RadialGradient(gradient: Gradient(colors: [Color(red: 0.1, green: 0.1, blue: 0.2), .black]), center: .center, startRadius: 10, endRadius: 60)).frame(width: 110, height: 110); Ellipse().stroke(Color.cyan.opacity(0.7), lineWidth: 3).frame(width: 150, height: 40).rotationEffect(.degrees(30)); Ellipse().stroke(Color.purple.opacity(0.7), lineWidth: 2).frame(width: 140, height: 30).rotationEffect(.degrees(-45)); Circle().fill(Color.white).frame(width: 8, height: 8).offset(x: 65, y: 35).shadow(color: .cyan, radius: 5); Circle().fill(Color.white).frame(width: 6, height: 6).offset(x: -50, y: -45).shadow(color: .purple, radius: 5); Circle().trim(from: 0.1, to: 0.35).stroke(Color.cyan.opacity(0.6), style: StrokeStyle(lineWidth: 3, lineCap: .round)).frame(width: 100, height: 100).rotationEffect(.degrees(-160)).blur(radius: 2) } }
}

private struct PolygonShape: Shape {
    var sides: Int
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.width / 2, y: rect.height / 2); let radius = min(rect.width, rect.height) / 2; var path = Path(); let angle = (Double.pi * 2) / Double(sides)
        for i in 0..<sides { let currentAngle = angle * Double(i) - Double.pi / 2; let point = CGPoint(x: center.x + CGFloat(cos(currentAngle)) * radius, y: center.y + CGFloat(sin(currentAngle)) * radius)
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) } }
        path.closeSubpath(); return path
    }
}

private struct WelcomeStepView: View {
    let onAppleTap: () -> Void; let onGoogleTap: () -> Void; let onGuestTap: () -> Void; @State private var buttonPulse = false
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Spacer(minLength: 8)
            VStack(alignment: .leading, spacing: 10) { Text("Нейросеть\nТвоего\nДвижения.").font(.system(size: 52, weight: .black, design: .monospaced)).foregroundStyle(LinearGradient(colors: [.white, .cyan, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)).lineSpacing(-5).minimumScaleFactor(0.5); Text("Забудь про обычные шагомеры. Наш ИИ анализирует твою биомеханику, паттерны ходьбы и расход кинетической энергии. Синхронизируй тело с машиной.").font(.system(size: 15, weight: .medium, design: .rounded)).lineSpacing(3).foregroundStyle(.white.opacity(0.7)).fixedSize(horizontal: false, vertical: true).minimumScaleFactor(0.8).padding(.trailing, 20) }
            Spacer()
            VStack(spacing: 12) { SignInButton(title: "Войти через Apple", subtitle: "Безопасный протокол", icon: "apple.logo", accent: Color.cyan, action: onAppleTap).scaleEffect(buttonPulse ? 1.02 : 1.0); SignInButton(title: "Войти через Google", subtitle: "Глобальная сеть", icon: "globe", accent: Color.purple, action: onGoogleTap); Button(action: onGuestTap) { Text("Локальный режим (Гость)").font(.system(size: 14, weight: .bold, design: .monospaced)).foregroundStyle(.white.opacity(0.7)).lineLimit(1).minimumScaleFactor(0.6).frame(maxWidth: .infinity).padding(.vertical, 16).background(Color.clear).overlay { RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.15), lineWidth: 1.5) } } }
            .onAppear { withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) { buttonPulse = true } }
        }.padding(.horizontal, 24).padding(.bottom, 30)
    }
}

private struct SignInButton: View {
    let title: String; let subtitle: String; let icon: String; let accent: Color; let action: () -> Void
    var body: some View {
        Button(action: action) { HStack(spacing: 14) { ZStack { RoundedRectangle(cornerRadius: 10).fill(accent.opacity(0.15)).frame(width: 40, height: 40); Image(systemName: icon).font(.system(size: 18, weight: .bold)).foregroundStyle(accent) }; VStack(alignment: .leading, spacing: 2) { Text(title).font(.system(size: 14, weight: .bold, design: .monospaced)).foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.8); Text(subtitle).font(.system(size: 11, weight: .medium)).foregroundStyle(.white.opacity(0.5)).lineLimit(1) }; Spacer(minLength: 0); Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold)).foregroundStyle(.white.opacity(0.3)) }.padding(.horizontal, 16).padding(.vertical, 12).frame(maxWidth: .infinity).background(Color(red: 0.1, green: 0.12, blue: 0.18).opacity(0.8)).clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous)).overlay { RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(LinearGradient(colors: [accent.opacity(0.6), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5) }.shadow(color: accent.opacity(0.15), radius: 10, x: 0, y: 5) }
    }
}

private struct GuestWarningView: View {
    let onStayGuest: () -> Void; let onSignIn: () -> Void
    var body: some View {
        ZStack {
            Color.clear
            VStack(alignment: .leading, spacing: 14) { Text("Автономный режим?").font(.system(size: 24, weight: .black, design: .monospaced)).foregroundStyle(.white).minimumScaleFactor(0.8).lineLimit(1); Text("Если продолжить без синхронизации, твоя биомеханика и логи шагов не будут выгружены на сервер. При сбросе устройства данные сотрутся.").font(.system(size: 13, design: .rounded)).lineSpacing(2).foregroundStyle(.white.opacity(0.8)).fixedSize(horizontal: false, vertical: true); Text("Преимущества синхронизации:").font(.system(size: 13, weight: .bold, design: .monospaced)).foregroundStyle(.cyan).padding(.top, 4); VStack(alignment: .leading, spacing: 8) { bullet("Облачное хранение логов движения"); bullet("Доступ к нейросети на всех устройствах"); bullet("Глубокая аналитика паттернов ИИ") }; Spacer(minLength: 8)
                HStack(spacing: 12) { Button(action: onStayGuest) { Text("Офлайн").font(.system(size: 14, weight: .bold, design: .monospaced)).foregroundStyle(.white.opacity(0.8)).frame(maxWidth: .infinity).padding(.vertical, 14).background(Color.white.opacity(0.05)).clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous)) }; Button(action: onSignIn) { Text("Подключить").font(.system(size: 14, weight: .bold, design: .monospaced)).foregroundStyle(.black).frame(maxWidth: .infinity).padding(.vertical, 14).background(LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)).clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous)).shadow(color: .cyan.opacity(0.3), radius: 8, y: 4) } }
            }.padding(.horizontal, 24).padding(.vertical, 24)
        }
    }
    private func bullet(_ text: String) -> some View { HStack(alignment: .center, spacing: 10) { Circle().fill(Color.purple).frame(width: 6, height: 6).shadow(color: .purple, radius: 4); Text(text).font(.system(size: 13, design: .rounded)).foregroundStyle(.white.opacity(0.9)).minimumScaleFactor(0.8) } }
}

private struct GoogleRegistrationView: View {
    @State private var fullName = ""; @State private var email = ""; @State private var password = ""
    let onBack: () -> Void; let onComplete: () -> Void
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                Button(action: onBack) { HStack(spacing: 6) { Image(systemName: "chevron.left"); Text("Терминал") }.font(.system(size: 14, weight: .bold, design: .monospaced)).foregroundStyle(.cyan).padding(.horizontal, 12).padding(.vertical, 8).background(Color.cyan.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 8)) }.padding(.top, 10)
                Text("Создание профиля").font(.system(size: 28, weight: .black, design: .monospaced)).foregroundStyle(.white).minimumScaleFactor(0.8).lineLimit(1).padding(.top, 8)
                Text("Введи идентификационные данные для создания защищенного узла связи с сервером.").font(.system(size: 13, design: .rounded)).lineSpacing(2).foregroundStyle(.white.opacity(0.7))
                VStack(spacing: 12) {
                    TextField("Позывной (Имя)", text: $fullName).fieldCyberStyle()
                    #if os(iOS)
                    TextField("Шифр-канал (Email)", text: $email).keyboardType(.emailAddress).textInputAutocapitalization(.never).fieldCyberStyle()
                    #else
                    TextField("Шифр-канал (Email)", text: $email).fieldCyberStyle()
                    #endif
                    SecureField("Код доступа (Пароль)", text: $password).fieldCyberStyle()
                }.padding(.vertical, 8)
                
                Button { CyberHapticManager.playSuccess(); onComplete() } label: { Text("ИНИЦИАЛИЗИРОВАТЬ").font(.system(size: 15, weight: .black, design: .monospaced)).foregroundStyle(.black).frame(maxWidth: .infinity).padding(.vertical, 16).background(LinearGradient(colors: [.cyan, .purple.opacity(0.8)], startPoint: .leading, endPoint: .trailing)).clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous)).shadow(color: .cyan.opacity(0.4), radius: 10, y: 5) }.padding(.top, 10)
                Text("Инициализируя связь, ты принимаешь директивы использования и протокол конфиденциальности.").font(.system(size: 10, design: .rounded)).foregroundStyle(.white.opacity(0.4)).multilineTextAlignment(.center).frame(maxWidth: .infinity).padding(.top, 8)
                Spacer(minLength: 40)
            }.padding(.horizontal, 24)
        }
    }
}

private extension View {
    func fieldCyberStyle() -> some View { self.font(.system(size: 15, design: .monospaced)).padding(.horizontal, 16).padding(.vertical, 14).background(Color(red: 0.05, green: 0.06, blue: 0.1)).clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous)).overlay { RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.cyan.opacity(0.3), lineWidth: 1) }.foregroundStyle(.cyan).accentColor(.cyan) }
}
