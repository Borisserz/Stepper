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

    /// Raw nonce generated for the current SIWA challenge. Apple requires
    /// `request.nonce = sha256(rawNonce)`; Firebase later wants the *raw*
    /// nonce + identity token to verify the credential. We hold it here
    /// between `configureAppleRequest` and `handleAppleResult`.
    private var currentRawNonce: String?

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
        let raw = FirebaseAuthBridge.makeRandomNonce()
        currentRawNonce = raw
        request.nonce = FirebaseAuthBridge.sha256(raw)
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

            // Bridge to Firebase Auth so the canonical UID powers Firestore
            // security rules and FirebaseAI App Check. The local snapshot
            // remains usable offline regardless of the Firebase outcome.
            if let token = credential.identityToken,
               let rawNonce = currentRawNonce {
                Task { [weak self] in
                    do {
                        _ = try await FirebaseAuthBridge.signInWithApple(
                            identityToken: token,
                            rawNonce: rawNonce,
                            fullName: credential.fullName
                        )
                    } catch {
                        // Surface the error but keep the local session.
                        self?.lastError = error.localizedDescription
                    }
                }
            }
            currentRawNonce = nil

        case .failure(let error as ASAuthorizationError) where error.code == .canceled:
            // User cancelled — not an error worth showing.
            currentRawNonce = nil
            return

        case .failure(let error):
            currentRawNonce = nil
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
        FirebaseAuthBridge.signOut()
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
        // 1. Wipe cloud copy of workouts so deletion is total per Apple
        //    Guideline 5.1.1(v) ("all data must be deleted").
        await FirestoreSyncService.shared.deleteAllForCurrentUser()

        // 2. Delete the Firebase user record (revokes the SIWA refresh
        //    token automatically when the session is fresh).
        do {
            try await FirebaseAuthBridge.deleteAccount()
        } catch {
            // Common case: token requires re-auth. The local session is
            // still cleared so the UX is consistent.
            lastError = error.localizedDescription
        }

        // 3. Best-effort: clear known per-user UserDefaults keys so opening
        //    the app post-deletion shows a fresh onboarding flow.
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
