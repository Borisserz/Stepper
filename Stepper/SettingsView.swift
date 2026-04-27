//
//  SettingsView.swift
//  Stepper
//
//  Top-level Settings screen. Surfaces the four areas Apple Review checks:
//  Account (sign in / out / delete), Subscription (restore — wired in PR #4),
//  Preferences (units, language, haptics) and Legal (Privacy / Terms /
//  Support). The Account-Deletion flow is required by Guideline 5.1.1(v)
//  whenever the app offers account creation.
//

import AuthenticationServices
import SwiftUI

struct SettingsView: View {
    @Environment(AccountManager.self) private var account
    @Environment(SettingsStore.self) private var settings
    @Environment(HealthKitManager.self) private var health
    @Environment(SubscriptionManager.self) private var subscriptions

    @State private var showDeleteConfirm = false
    @State private var isDeleting = false
    @State private var legalSheet: LegalSheetKind?
    @State private var restoreState: RestoreState = .idle
    @State private var showHistory = false

    fileprivate enum RestoreState { case idle, restoring, restored, alreadyPremium, noPurchases, failed(String) }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bgDark.ignoresSafeArea()
                Form {
                    accountSection
                    subscriptionSection
                    preferencesSection
                    healthSection
                    workoutsSection
                    legalSection
                    aboutSection
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(Text("settings.title"))
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $legalSheet) { kind in
                LegalSheet(kind: kind)
            }
            .sheet(isPresented: $showHistory) {
                WorkoutHistoryView()
            }
            .alert(Text("settings.account.delete.title"),
                   isPresented: $showDeleteConfirm) {
                Button(role: .destructive) {
                    Task { await performDelete() }
                } label: {
                    Text("settings.account.delete.confirm")
                }
                Button("common.cancel", role: .cancel) { }
            } message: {
                Text("settings.account.delete.message")
            }
            .alert(Text("settings.subscription.restore"),
                   isPresented: Binding(
                    get: { restoreState.shouldShowAlert },
                    set: { if !$0 { restoreState = .idle } }
                   )) {
                Button("common.continue", role: .cancel) { restoreState = .idle }
            } message: {
                Text(restoreState.alertMessage)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Sections

    private var accountSection: some View {
        Section {
            if let snapshot = account.account {
                LabeledRow(title: Text("settings.account.signedIn"),
                           value: Text(snapshot.displayName ?? snapshot.email ?? snapshot.userID))
                LabeledRow(title: Text("settings.account.method"),
                           value: Text(methodLabel(snapshot.method)))

                Button(role: .destructive) {
                    account.signOut()
                } label: {
                    Label {
                        Text("settings.account.signOut")
                    } icon: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                }

                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label {
                        Text("settings.account.deleteAccount")
                    } icon: {
                        Image(systemName: "trash")
                    }
                }
                .disabled(isDeleting)
            } else {
                SignInWithAppleButton { request in
                    account.configureAppleRequest(request)
                } onCompletion: { result in
                    account.handleAppleResult(result)
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 50)
                .listRowBackground(Color.clear)
            }
        } header: {
            Text("settings.account.title")
        } footer: {
            if account.isGuest {
                Text("settings.account.guestNote")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var subscriptionSection: some View {
        Section("settings.subscription.title") {
            HStack {
                Label {
                    Text(subscriptions.isPremium
                         ? "settings.subscription.status.active"
                         : "settings.subscription.status.inactive")
                } icon: {
                    Image(systemName: subscriptions.isPremium ? "checkmark.seal.fill" : "seal")
                        .foregroundStyle(subscriptions.isPremium ? .green : .secondary)
                }
                Spacer()
            }
            Button {
                Task { await runRestore() }
            } label: {
                HStack {
                    Label {
                        Text("settings.subscription.restore")
                    } icon: {
                        Image(systemName: "arrow.clockwise")
                    }
                    Spacer()
                    if case .restoring = restoreState {
                        ProgressView()
                    }
                }
            }
            .disabled(restoreStateIsBusy)
        }
    }

    private var restoreStateIsBusy: Bool {
        if case .restoring = restoreState { return true }
        return false
    }

    private func runRestore() async {
        let wasPremium = subscriptions.isPremium
        restoreState = .restoring
        await subscriptions.restore()
        if let err = subscriptions.lastError {
            restoreState = .failed(err)
            return
        }
        if subscriptions.isPremium {
            restoreState = wasPremium ? .alreadyPremium : .restored
        } else {
            restoreState = .noPurchases
        }
    }

    private var preferencesSection: some View {
        @Bindable var settings = settings
        return Section("settings.preferences.title") {
            Picker(selection: $settings.distanceUnit) {
                ForEach(DistanceUnit.allCases) { unit in
                    Text(unit == .kilometres ? "settings.units.km" : "settings.units.mi")
                        .tag(unit)
                }
            } label: {
                Label {
                    Text("settings.units.title")
                } icon: {
                    Image(systemName: "ruler")
                }
            }

            Picker(selection: $settings.language) {
                ForEach(AppLanguage.allCases) { lang in
                    Text(lang.displayName).tag(lang)
                }
            } label: {
                Label {
                    Text("settings.language.title")
                } icon: {
                    Image(systemName: "globe")
                }
            }

            Toggle(isOn: $settings.hapticsEnabled) {
                Label {
                    Text("settings.haptics.title")
                } icon: {
                    Image(systemName: "waveform")
                }
            }

            Toggle(isOn: $settings.notificationsEnabled) {
                Label {
                    Text("settings.notifications.title")
                } icon: {
                    Image(systemName: "bell")
                }
            }
        }
    }

    private var healthSection: some View {
        Section("settings.health.title") {
            if health.isAvailable {
                Button {
                    Task { await health.requestAuthorization() }
                } label: {
                    Label {
                        Text(health.hasRequestedAuthorization
                             ? "settings.health.refresh"
                             : "settings.health.connect")
                    } icon: {
                        Image(systemName: "heart.text.square")
                    }
                }
                if let steps = health.todaySteps {
                    LabeledRow(title: Text("settings.health.todaySteps"),
                               value: Text("\(Int(steps))"))
                }
            } else {
                Text("settings.health.unavailable")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var workoutsSection: some View {
        Section("settings.workouts.title") {
            Button {
                showHistory = true
            } label: {
                Label("settings.workouts.history", systemImage: "list.bullet.clipboard")
            }
        }
    }

    private var legalSection: some View {
        Section("settings.legal.title") {
            Button { legalSheet = .privacy } label: {
                Label("settings.legal.privacyPolicy", systemImage: "lock.shield")
            }
            Button { legalSheet = .terms } label: {
                Label("settings.legal.termsOfService", systemImage: "doc.text")
            }
            Button { legalSheet = .support } label: {
                Label("settings.legal.support", systemImage: "questionmark.circle")
            }
        }
    }

    private var aboutSection: some View {
        Section("settings.about.title") {
            LabeledRow(title: Text("settings.about.version"),
                       value: Text(Self.versionString))
        }
    }

    // MARK: - Helpers

    private static var versionString: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "—"
        let build = info?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }

    private func methodLabel(_ method: AuthMethod) -> String {
        switch method {
        case .apple:
            return NSLocalizedString("settings.account.method.apple",
                                     value: "Sign in with Apple",
                                     comment: "")
        case .guest:
            return NSLocalizedString("settings.account.method.guest",
                                     value: "Guest",
                                     comment: "")
        }
    }

    /// Clears local data and signs the user out. `RootRouterView` watches
    /// `account.isSignedIn` and automatically routes back to the onboarding
    /// flow once it flips to `false`, so we don't need to dismiss anything
    /// from this view.
    private func performDelete() async {
        isDeleting = true
        defer { isDeleting = false }
        await account.deleteAccount()
    }
}

private struct LabeledRow: View {
    let title: Text
    let value: Text

    var body: some View {
        HStack {
            title
            Spacer()
            value.foregroundStyle(.secondary)
        }
    }
}

private extension SettingsView.RestoreState {
    var shouldShowAlert: Bool {
        switch self {
        case .idle, .restoring: return false
        default: return true
        }
    }

    var alertMessage: LocalizedStringKey {
        switch self {
        case .restored:        return "settings.subscription.restore.restored"
        case .alreadyPremium:  return "settings.subscription.restore.alreadyPremium"
        case .noPurchases:     return "settings.subscription.restore.none"
        case .failed:          return "settings.subscription.restore.failed"
        case .idle, .restoring: return "settings.subscription.restore.placeholder"
        }
    }
}
