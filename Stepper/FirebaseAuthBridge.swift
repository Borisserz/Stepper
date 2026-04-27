//
//  FirebaseAuthBridge.swift
//  Stepper
//
//  Bridges the local `AccountManager` Sign-in-with-Apple flow to Firebase
//  Auth. The local snapshot stays the source of truth for offline
//  experience (so the app keeps working with no network), while Firebase
//  Auth holds the canonical UID used by Firestore security rules and
//  Firebase AI App Check.
//
//  All Firebase symbols are wrapped in `#if canImport` so the project
//  compiles before the `FirebaseAuth` SPM package is added.
//

import AuthenticationServices
import CryptoKit
import Foundation

#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

@MainActor
enum FirebaseAuthBridge {

    /// Current Firebase UID, if signed in. Used by `FirestoreSyncService` to
    /// scope every read/write to `users/{uid}/...` collections.
    static var currentUID: String? {
        #if canImport(FirebaseAuth)
        return Auth.auth().currentUser?.uid
        #else
        return nil
        #endif
    }

    /// Exchanges an Apple ID identity token + raw nonce for a Firebase
    /// session. Returns the Firebase UID on success, nil if Firebase isn't
    /// configured or the SDK isn't linked.
    @discardableResult
    static func signInWithApple(
        identityToken: Data,
        rawNonce: String,
        fullName: PersonNameComponents?
    ) async throws -> String? {
        #if canImport(FirebaseAuth)
        guard FirebaseBootstrap.isConfigured,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            return nil
        }
        let provider = OAuthProvider.appleCredential(
            withIDToken: tokenString,
            rawNonce: rawNonce,
            fullName: fullName
        )
        let result = try await Auth.auth().signIn(with: provider)
        return result.user.uid
        #else
        _ = (identityToken, rawNonce, fullName)
        return nil
        #endif
    }

    static func signOut() {
        #if canImport(FirebaseAuth)
        try? Auth.auth().signOut()
        #endif
    }

    /// Removes the Firebase user record. Required by Apple Guideline
    /// 5.1.1(v) — and unlike a server-side delete, this revokes the SIWA
    /// refresh token automatically when called from a re-authenticated
    /// session.
    static func deleteAccount() async throws {
        #if canImport(FirebaseAuth)
        try await Auth.auth().currentUser?.delete()
        #endif
    }

    // MARK: - Nonce helpers (kept in sync with `OnboardingAuthView`)

    /// Generates a cryptographically random nonce; the sha256 of this
    /// value is what we pass to ASAuthorizationAppleIDRequest. The raw
    /// nonce is what Firebase later wants to verify identity.
    static func makeRandomNonce(length: Int = 32) -> String {
        precondition(length > 0)
        let chars: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            var randoms = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
            guard status == errSecSuccess else { continue }
            for byte in randoms where remaining > 0 {
                let idx = Int(byte) % chars.count
                result.append(chars[idx])
                remaining -= 1
            }
        }
        return result
    }

    static func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
