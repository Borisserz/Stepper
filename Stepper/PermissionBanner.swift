//
//  PermissionBanner.swift
//  Stepper
//
//  Reusable cyber-styled banner for permission denied / undetermined
//  empty-states. Shown on top of MainScreenView when HealthKit isn't
//  granting step data and on top of GPSTabView when CoreLocation is
//  denied. Tapping the CTA opens the iOS Settings app deep-link.
//

import SwiftUI

struct PermissionBanner: View {
    enum Kind {
        case healthDenied
        case healthNotAsked
        case locationDenied
        case locationNotAsked

        var iconName: String {
            switch self {
            case .healthDenied, .healthNotAsked: return "heart.text.square"
            case .locationDenied, .locationNotAsked: return "location.slash.fill"
            }
        }

        var titleKey: LocalizedStringKey {
            switch self {
            case .healthDenied: return "permission.health.denied.title"
            case .healthNotAsked: return "permission.health.notAsked.title"
            case .locationDenied: return "permission.location.denied.title"
            case .locationNotAsked: return "permission.location.notAsked.title"
            }
        }

        var subtitleKey: LocalizedStringKey {
            switch self {
            case .healthDenied: return "permission.health.denied.subtitle"
            case .healthNotAsked: return "permission.health.notAsked.subtitle"
            case .locationDenied: return "permission.location.denied.subtitle"
            case .locationNotAsked: return "permission.location.notAsked.subtitle"
            }
        }

        var ctaKey: LocalizedStringKey {
            switch self {
            case .healthDenied, .locationDenied:
                return "permission.cta.openSettings"
            case .healthNotAsked, .locationNotAsked:
                return "permission.cta.allow"
            }
        }

        var accent: Color {
            switch self {
            case .healthDenied, .healthNotAsked: return AppTheme.accentRed
            case .locationDenied, .locationNotAsked: return AppTheme.accentCyan
            }
        }
    }

    let kind: Kind
    let onAction: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(kind.accent.opacity(0.18)).frame(width: 44, height: 44)
                Image(systemName: kind.iconName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(kind.accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(kind.titleKey)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(kind.subtitleKey)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            Button(action: {
                triggerImpact()
                onAction()
            }) {
                Text(kind.ctaKey)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(kind.accent, in: Capsule())
            }
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(kind.accent.opacity(0.5), lineWidth: 1.5)
        )
        .shadow(color: kind.accent.opacity(0.25), radius: 12, y: 4)
    }
}

/// Convenience: opens iOS Settings → app entry. Use when permission was
/// `denied` and we can't re-prompt programmatically.
@MainActor
func openAppSettings() {
    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
    UIApplication.shared.open(url)
}
