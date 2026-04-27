//
//  AccountManager.swift
//  Stepper
//
//  Owns the user-account state of the app: who is signed in, how the user
//  signed in (Apple / guest), and the destructive flows (sign out and
//  account deletion). Sign-in with Apple is required by Apple Guideline
//  4.8 whenever third-party sign-in is offered, and an in-app account
//  deletion flow is required by Guideline 5.1.1(v).
//
//  This file is intentionally backend-agnostic: it persists the user
//  identity locally so the rest of the UI works today. PR #5 will wire the
//  signed-in user up to Firebase Auth + Firestore.
//

import AuthenticationServices
import Foundation
import SwiftUI

enum AuthMethod: String, Codable {
    case apple
    case guest
}

struct AccountSnapshot: Codable, Equatable {
    var userID: String
    var displayName: String?
    var email: String?
    var method: AuthMethod
    var signedInAt: Date
}

@MainActor
@Observable
final class AccountManager {
    /// Currently signed-in account, if any. `nil` means signed-out.
    private(set) var account: AccountSnapshot?

    /// Last error surfaced by an authorization flow. Cleared on success.
    var lastError: String?

    /// True while a Sign-in-with-Apple flow is in progress.
    private(set) var isAuthorizing: Bool = false

    private let storageKey = "com.borisdev.Stepper.account"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.account = Self.load(defaults: defaults, key: storageKey)
    }

    // MARK: - Convenience

    var isSignedIn: Bool { account != nil }
    var isGuest: Bool { account?.method == .guest }

    // MARK: - Apple sign-in

    /// Builds an `ASAuthorizationAppleIDRequest` configured for full-name +
    /// email scope. Pass into `SignInWithAppleButton(onRequest:onCompletion:)`.
    func configureAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
        isAuthorizing = true
        lastError = nil
    }

    /// Handles the result of `SignInWithAppleButton`'s `onCompletion`.
    func handleAppleResult(_ result: Result<ASAuthorization, Error>) {
        isAuthorizing = false
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                lastError = NSLocalizedString("auth.error.unknownCredential",
                                              value: "Unknown credential type",
                                              comment: "")
                return
            }
            let snapshot = AccountSnapshot(
                userID: credential.user,
                displayName: credential.fullName.flatMap(Self.formatPersonName),
                email: credential.email,
                method: .apple,
                signedInAt: Date()
            )
            persist(snapshot)

        case .failure(let error as ASAuthorizationError) where error.code == .canceled:
            // User cancelled — not an error worth showing.
            return

        case .failure(let error):
            lastError = error.localizedDescription
        }
    }

    // MARK: - Guest

    /// Used by "Continue as guest" — creates a local-only account with a UUID.
    func continueAsGuest() {
        let snapshot = AccountSnapshot(
            userID: "guest-" + UUID().uuidString,
            displayName: nil,
            email: nil,
            method: .guest,
            signedInAt: Date()
        )
        persist(snapshot)
    }

    // MARK: - Sign out / Delete account

    /// Removes the locally stored account. The Settings screen calls this.
    func signOut() {
        account = nil
        defaults.removeObject(forKey: storageKey)
        lastError = nil
    }

    /// Required by Apple Guideline 5.1.1(v). Deletes the local account and
    /// clears app-side data. Server-side deletion is wired in PR #5 once
    /// Firebase is connected.
    ///
    /// - Returns: `true` when the deletion completed locally.
    @discardableResult
    func deleteAccount() async -> Bool {
        // Best-effort: clear known per-user UserDefaults keys so opening the
        // app post-deletion shows a fresh onboarding flow.
        for key in ["dailyStepGoal", "userHeight", "userWeight", "userAge"] {
            defaults.removeObject(forKey: key)
        }
        signOut()
        return true
    }

    // MARK: - Persistence

    private func persist(_ snapshot: AccountSnapshot) {
        if let data = try? JSONEncoder().encode(snapshot) {
            defaults.set(data, forKey: storageKey)
        }
        account = snapshot
    }

    private static func load(defaults: UserDefaults, key: String) -> AccountSnapshot? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(AccountSnapshot.self, from: data)
    }

    private static func formatPersonName(_ components: PersonNameComponents) -> String? {
        let formatter = PersonNameComponentsFormatter()
        formatter.style = .default
        let result = formatter.string(from: components)
        return result.isEmpty ? nil : result
    }
}
