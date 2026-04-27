//
//  FirebaseBootstrap.swift
//  Stepper
//
//  Single entry-point for initialising Firebase. Called from
//  `footstepeRRApp.init()` before any other state is built. Wraps every
//  Firebase symbol in `#if canImport` so the project compiles even before
//  the SPM packages are added in Xcode (`FirebaseAuth`, `FirebaseFirestore`,
//  `FirebaseAI`, `FirebaseAppCheck`). Once the packages are added the code
//  paths activate automatically — no further wiring needed.
//
//  Why App Check? Vertex AI calls through `FirebaseAI` need attestation,
//  otherwise Google bills your project for any binary that scrapes the
//  GoogleService-Info.plist out of the .ipa. `DeviceCheck` is the
//  zero-configuration option for iOS — no APNs, no extra entitlement.
//

import Foundation

#if canImport(FirebaseCore)
import FirebaseCore
#endif
#if canImport(FirebaseAppCheck)
import FirebaseAppCheck
#endif

enum FirebaseBootstrap {

    /// True once `configure()` has succeeded. Used by other services to
    /// short-circuit cleanly when Firebase isn't available (e.g. unit tests
    /// or when the SPM packages haven't been added yet).
    static private(set) var isConfigured: Bool = false

    /// Idempotent. Safe to call from `App.init()`.
    static func configure() {
        #if canImport(FirebaseCore)
        guard FirebaseApp.app() == nil else {
            isConfigured = true
            return
        }

        // App Check must be installed *before* `FirebaseApp.configure()` so
        // the very first auth/firestore/AI request uses an attested token.
        #if canImport(FirebaseAppCheck)
        #if DEBUG
        // Locally we use the debug provider — the printed token must be
        // pasted into Firebase Console → App Check → Apps → iOS → debug
        // tokens. Without it, debug builds get 403 from Vertex.
        AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
        #else
        AppCheck.setAppCheckProviderFactory(DeviceCheckProviderFactory())
        #endif
        #endif

        FirebaseApp.configure()
        isConfigured = true
        #else
        // Firebase SDK not yet linked — no-op so the rest of the app runs.
        isConfigured = false
        #endif
    }
}
