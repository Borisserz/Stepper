//
//  CyberShared.swift
//  Stepper
//
//  Created by Boris Serzhanovich on 27.04.26.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - КАСТОМНЫЕ ЦВЕТА
extension Color {
    static let cyberCyan = Color(red: 0.0, green: 0.85, blue: 1.0)
    static let cyberPurple = Color(red: 0.6, green: 0.3, blue: 1.0)
    static let cyberNeon = Color(red: 0.1, green: 0.95, blue: 0.6)
    static let cyberDark = Color(red: 0.07, green: 0.09, blue: 0.15)
    static let cyberPanel = Color(red: 0.15, green: 0.18, blue: 0.25)
    static let textLight = Color.white
}

extension ShapeStyle where Self == Color {
    static var cyberCyan: Color { Color.cyberCyan }
    static var cyberPurple: Color { Color.cyberPurple }
    static var cyberNeon: Color { Color.cyberNeon }
    static var cyberDark: Color { Color.cyberDark }
    static var cyberPanel: Color { Color.cyberPanel }
    static var textLight: Color { Color.textLight }
}

// MARK: - HAPTIC МЕНЕДЖЕР
class CyberHapticManager {
    static func playLightImpact() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
    
    static func playMediumImpact() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }
    
    static func playHeavyImpact() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        #endif
    }
    
    static func playSelection() {
        #if os(iOS)
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }
    
    static func playSuccess() {
        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }
}

// MARK: - КНОПКИ
struct CyberBouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
