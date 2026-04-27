# Firebase setup

This PR wires Firebase Auth, Firestore, App Check and Vertex AI (via
`FirebaseAI`). Before the app can talk to any of these services, three
short manual steps are required in Xcode and the Firebase Console.

---

## 1. Add Firebase iOS SDK packages

In Xcode 26+:

1. **File → Add Package Dependencies…**
2. Paste `https://github.com/firebase/firebase-ios-sdk` and click *Add Package*.
3. When the product list appears, tick the following targets and add them
   to `Stepper`:
    - `FirebaseAuth`
    - `FirebaseFirestore`
    - `FirebaseAI`
    - `FirebaseAppCheck`
    - `FirebaseAnalytics` (optional, useful for funnel debugging)
4. Wait for SPM resolution to finish, then build (`⌘B`).

The Swift code in this PR is wrapped in `#if canImport(FirebaseCore)`
guards, so the project compiles even before this step. The Firebase code
paths only activate after the packages are linked.

## 2. Firebase Console — one-time configuration

In your project (`serzhanovich-ecosystem-ce700`):

### 2.1 Authentication

- **Authentication → Sign-in method → Apple → Enable**
- Service ID / Team ID can stay blank for native iOS — Apple's identity
  token + raw nonce is enough.

### 2.2 Firestore

- **Build → Firestore Database → Create database**
- Pick a regional location (`eur3` recommended for EU+CIS users, `nam5`
  for North America).
- Start in **production mode**.
- Replace the default rules with the contents of
  [`firestore.rules`](./firestore.rules) (committed in this PR), then
  *Publish*.

### 2.3 App Check

- **Build → App Check → Apps → iOS app → Register → DeviceCheck.**
- Once registered, App Check will start enforcing. For development on
  simulator (no DeviceCheck attestation), the SDK uses
  `AppCheckDebugProviderFactory`. The first run prints a debug token to
  the Xcode console:

  ```
  [Firebase/AppCheck][I-FAA002001] Firebase App Check Debug Token:
  ABCDEFGH-1234-5678-...
  ```

  Paste that token into **App Check → Apps → iOS → ⋮ → Manage debug
  tokens → Add debug token**.

### 2.4 Vertex AI

- **Build → AI → Get started → Vertex AI**
- Click *Enable Vertex AI*. This turns on the `aiplatform.googleapis.com`
  API in the underlying GCP project automatically.
- The default region (`us-central1`) is fine; latency to EU is ~150 ms.
- Pick **billing**: Vertex requires a billing account on the GCP project.
  `gemini-2.5-flash` is currently $0.10 / 1M input tokens — a typical
  user message + response burns ~500 tokens, so cost per chat reply is
  fractions of a cent.

## 3. `GoogleService-Info.plist`

Already committed at `Stepper/GoogleService-Info.plist` and auto-bundled
by the synchronized file group (no manual `Copy Bundle Resources` step
needed).

If you ever rotate the iOS app credentials, replace the file in place —
the bundle ID inside it (`com.borisdev.Stepper`) and the
`GOOGLE_APP_ID` keep `FirebaseApp.configure()` aligned with the project.

---

## What this enables

| Surface | What changed |
| --- | --- |
| Sign in with Apple | `AccountManager` now bridges to `FirebaseAuth.signIn(with: OAuthCredential)`. Your Firebase users dashboard will start filling up. |
| Account deletion | `AccountManager.deleteAccount()` wipes the Firebase user, the SIWA refresh token, all `users/{uid}/workouts` documents, and the local SwiftData copy. Apple Guideline 5.1.1(v) compliant. |
| Workout history | `WorkoutRecorder.stop` writes the new `WorkoutSession` to `users/{uid}/workouts/{sessionId}` in parallel with the HealthKit write. On a fresh device the app pulls the entire collection back on launch. |
| AI Coach (`AICoachChatView`) | First tab inside the existing Neural Core hub. Real Gemini 2.5 Flash responses through `FirebaseAI` — never embeds the service-account JSON in the binary. |

## Threat model

- Vertex billing is gated by App Check (`DeviceCheck` on prod, debug
  provider in DEBUG). Without a valid attestation token, `FirebaseAI`
  refuses to dispatch the request.
- Firestore rules below restrict every read/write to documents owned by
  the authenticated user (`request.auth.uid == userId`).
- The `GoogleService-Info.plist` is **not** a secret (it's a public
  identifier + API key gated by AppCheck). Apple ships these in millions
  of `.ipa`s. The danger is the *service-account JSON* — that one stays
  on Google's side, never in this repo or the binary.
