# Privacy Policy — footstepeR

**Effective date:** 2026-04-27  
**Contact:** support@footsteper.app *(replace before App Store submission)*

footstepeR ("we", "us", "the app") respects your privacy. This Privacy Policy
explains what data the app collects, how we use it, with whom we share it, and
the rights you have over your data.

---

## 1. Data we collect

| Category | Data | Source | Purpose |
|----------|------|--------|---------|
| **Account** | Email, name, optional avatar | You, when you sign up via Sign in with Apple or Google | Identify your account, sync data across devices, social features |
| **Fitness & Health** | Step count, distance, calories, heart rate, workout type and duration | Apple Health (HealthKit) / Core Motion (only if you grant permission) | Display your activity, calculate goals, render charts |
| **Location** | Precise GPS coordinates while you use the GPS Tracking feature | Your device, only after you grant Location permission and start a workout | Draw your route on the map, calculate pace and distance |
| **Voice (AI Coach)** | Audio captured by the microphone, transcribed text | Your device, only when you tap the mic button | Send your question to the AI Coach and return an answer |
| **Usage analytics** | Anonymous events such as "screen viewed", crash reports | Automatic | Detect bugs and improve the app |

We do **not** collect financial information, contacts, browsing history, or any
data the app does not need to function.

---

## 2. How we use your data

- **App functionality** — track your workouts, render maps, calculate
  statistics, sync between your devices.
- **AI Coach** — your transcribed text (and optionally a short summary of your
  recent fitness data) is sent to our AI provider, Google Vertex AI, solely to
  generate the coach's response. Audio is **not** stored after transcription.
- **Account management** — authentication, password-less sign-in, account
  deletion.
- **Bug fixing & analytics** — anonymous, aggregated.

We do **not** sell your data, share it with advertisers, or use it for tracking
across other apps and websites.

---

## 3. Third-party services

| Service | Purpose | Data shared |
|---------|---------|-------------|
| Apple Sign in with Apple | Authentication | Email (optional, may be relay), name |
| Google Firebase Authentication | Authentication | Email, name, hashed user ID |
| Google Firebase Firestore | Cloud database | Workout records, club membership |
| Google Vertex AI (Gemini) | AI Coach responses | Transcribed text, optional fitness summary |
| Apple MapKit | Map rendering | Coordinates (processed on-device) |

Each provider has its own privacy policy. Data sent to these services is
encrypted in transit (TLS 1.2+) and at rest.

---

## 4. Data retention and deletion

- We keep your account data while your account is active.
- You can **delete your account** at any time from
  Settings → Account → Delete Account. This removes:
  - Your authentication record.
  - All workouts, routes, and club memberships from the cloud database.
  - Local data on your device when you uninstall the app.
- Crash and analytics data is retained for 90 days.

---

## 5. Children's privacy

footstepeR is rated 4+ but is **not** directed at children under 13. We do not
knowingly collect personal data from children under 13. If you believe we have
collected such data, contact us and we will delete it.

---

## 6. International users

Data is stored on Google Cloud servers in the European Union and the United
States. By using the app you consent to this transfer.

---

## 7. Your rights (GDPR / CCPA)

If you reside in the EU, the UK, or California you have the right to:

- Access the data we hold about you.
- Rectify inaccurate data.
- Erase your data (right to be forgotten).
- Restrict or object to processing.
- Receive your data in a portable format.

Email **support@footsteper.app** with your request. We respond within 30 days.

---

## 8. Security

We use industry-standard measures:

- TLS encryption for all network traffic.
- At-rest encryption on managed cloud infrastructure.
- Authentication tokens stored in iOS Keychain, never in plain UserDefaults.
- The app never stores third-party API keys on the device.

No system is 100 % secure; we cannot guarantee absolute protection.

---

## 9. Changes to this policy

We will post any change here and update the "Effective date". Material changes
will be announced inside the app.

---

## 10. Contact

**Email:** support@footsteper.app  
**Developer:** Boris Serzhanovich
