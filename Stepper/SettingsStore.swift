//
//  SettingsStore.swift
//  Stepper
//
//  Centralised, observable preferences. Backed by `UserDefaults` so values
//  survive app restarts; exposed as `@Observable` so SwiftUI views in iOS
//  17+ refresh automatically without `@AppStorage` ceremony.
//

import Foundation
import SwiftUI

enum DistanceUnit: String, Codable, CaseIterable, Identifiable {
    case kilometres
    case miles

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .kilometres: return "km"
        case .miles: return "mi"
        }
    }

    /// Convert metres → user's preferred unit.
    func format(meters: Double) -> String {
        switch self {
        case .kilometres:
            return String(format: "%.2f", meters / 1000.0)
        case .miles:
            return String(format: "%.2f", meters / 1609.344)
        }
    }
}

enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case system
    case english
    case russian

    var id: String { rawValue }

    var localeID: String? {
        switch self {
        case .system: return nil
        case .english: return "en"
        case .russian: return "ru"
        }
    }

    var displayName: String {
        switch self {
        case .system: return NSLocalizedString("settings.language.system", value: "System", comment: "")
        case .english: return "English"
        case .russian: return "Русский"
        }
    }
}

@MainActor
@Observable
final class SettingsStore {
    var distanceUnit: DistanceUnit {
        didSet { defaults.set(distanceUnit.rawValue, forKey: Keys.unit) }
    }

    var language: AppLanguage {
        didSet { defaults.set(language.rawValue, forKey: Keys.language) }
    }

    var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: Keys.haptics) }
    }

    var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: Keys.notifications) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let unitRaw = defaults.string(forKey: Keys.unit) ?? DistanceUnit.kilometres.rawValue
        self.distanceUnit = DistanceUnit(rawValue: unitRaw) ?? .kilometres
        let langRaw = defaults.string(forKey: Keys.language) ?? AppLanguage.system.rawValue
        self.language = AppLanguage(rawValue: langRaw) ?? .system
        self.hapticsEnabled = (defaults.object(forKey: Keys.haptics) as? Bool) ?? true
        self.notificationsEnabled = (defaults.object(forKey: Keys.notifications) as? Bool) ?? true
    }

    private enum Keys {
        static let unit = "settings.distanceUnit"
        static let language = "settings.language"
        static let haptics = "settings.haptics"
        static let notifications = "settings.notifications"
    }
}
