# App Store Connect — submission checklist & metadata

This document holds everything you need to fill in App Store Connect when
submitting footstepeR for review. Update the `TODO` markers and copy the
fields into ASC at the time of submission.

---

## App information

| Field | Value |
|-------|-------|
| Bundle ID | `com.borisdev.Stepper` |
| App name | **footstepeR** |
| Subtitle | Cyberpunk fitness tracker |
| Primary category | Health & Fitness |
| Secondary category | Lifestyle |
| Content rights | Yes — does not contain third-party content |
| Age rating | 4+ |
| Privacy Policy URL | `https://borisserz.github.io/Stepper/privacy-policy.html` *(once GitHub Pages is enabled)* |
| Terms of Use URL | `https://borisserz.github.io/Stepper/terms-of-service.html` |
| Support URL | `https://borisserz.github.io/Stepper/support.html` |
| Marketing URL | `https://borisserz.github.io/Stepper/` |

---

## Localizations

We ship with English (Primary) and Russian.

### English — App Store description

> footstepeR turns your daily activity into a cyberpunk RPG. Real-time GPS
> tracking, an AI Coach you can talk to, neural-style charts of your sleep and
> heart rate, and gamified leagues that keep you moving. Every step you take is
> logged through Apple Health, drawn on a glowing dark map, and converted into
> in-app points you can spend on virtual implants.
>
> • Live GPS tracking with neon polylines and pace, distance, and calorie
>   read-outs.  
> • AI Coach: ask questions by voice or text, get advice based on your fitness
>   data.  
> • Cyber-clubs and global leaderboards: join a club, challenge rivals,
>   climb the leagues.  
> • Apple Health integration for accurate steps, distance, heart rate, and
>   workouts.  
> • Glassmorphism UI built natively in SwiftUI for iPhone and iPad.
>
> Subscription unlocks the AI Coach, advanced biometrics, and unlimited
> custom routes. Cancel any time in Settings → Apple ID → Subscriptions.

### English — keywords (100 chars total max)

```
fitness,run,walk,step,gps,tracker,coach,ai,health,workout
```

### English — promotional text (170 chars max)

> Track every step in style. Real GPS, real Apple Health data, an AI Coach you
> talk to, all wrapped in a cyberpunk UI made for the way you actually move.

### Russian — описание

> footstepeR превращает каждый ваш шаг в киберпанк-RPG. Живой GPS-трекинг,
> голосовой ИИ-коуч, графики сна и пульса в неоновом стиле, лиги и клубы,
> которые мотивируют двигаться. Apple Health на бэке, MapKit на фронте,
> SwiftUI повсюду.
>
> • Живой GPS с яркими полилиниями и метриками темпа, дистанции и калорий.  
> • Нейро-коуч: задавайте вопросы голосом или текстом, получайте советы на
>   основе ваших данных.  
> • Кибер-клубы и глобальные таблицы лидеров.  
> • Apple Health: точные шаги, дистанция, пульс, тренировки.  
> • Стеклянный (glassmorphism) интерфейс на нативном SwiftUI.
>
> Подписка открывает ИИ-коуча, продвинутую биометрию и безлимитные маршруты.

### Russian — ключевые слова

```
фитнес,бег,ходьба,шагомер,gps,трекер,ии,здоровье,тренировка
```

### Russian — рекламный текст

> Считайте шаги стильно: настоящий GPS, реальные данные Apple Health,
> голосовой ИИ-коуч и киберпанк-интерфейс под ваш ритм.

---

## What's new in this version

```
v1.0 — first public release. Welcome to the grid.
```

---

## Screenshots required (per device)

You must provide at least one set per locale. Apple will derive smaller sizes
from the largest one when missing.

| Device class | Required size | How many |
|--------------|---------------|----------|
| iPhone 6.9" (iPhone 16 Pro Max, 17 Pro Max) | 1320 × 2868 px | 3–10 |
| iPhone 6.7" (iPhone 14/15/16 Plus) | 1290 × 2796 px | 3–10 *(optional if 6.9" present)* |
| iPad 13" (iPad Pro M4) | 2064 × 2752 px | 3–10 |

Suggested screens to capture:

1. Main dashboard (steps + activity ring).
2. Live GPS tracking with route polyline.
3. AI Coach chat.
4. Heart-rate / Bio-Sync screen.
5. Cyber-Hub with clubs and challenges.
6. Paywall (showing exact subscription terms — required since iOS 17 or it gets
   rejected under 3.1.2).

---

## App Privacy ("Nutrition Label" in App Store Connect)

Mirror the entries in `Stepper/PrivacyInfo.xcprivacy`:

| Data | Linked to user? | Used for tracking? | Purpose |
|------|-----------------|--------------------|---------|
| Precise location | Yes | No | App functionality, analytics |
| Health & Fitness | Yes | No | App functionality |
| Audio | No | No | App functionality |
| Email, Name, User ID | Yes | No | App functionality |
| Crash data, Performance data | No | No | App functionality, analytics |

---

## In-App Purchases (configure when StoreKit PR lands)

| Product ID | Type | Price tier | Free trial |
|------------|------|------------|------------|
| `com.borisdev.Stepper.weekly` | Auto-renewable, 1 week | TBD | none |
| `com.borisdev.Stepper.monthly` | Auto-renewable, 1 month | TBD | 7 days |
| `com.borisdev.Stepper.yearly` | Auto-renewable, 1 year | TBD | 7 days |

All three live in the same Subscription Group: **footstepeR Premium**.

The paywall must show the **exact** price, period, and trial terms before the
purchase button — Apple rejects subscriptions where this is hidden behind a
tooltip or modal (Guideline 3.1.2 (a)).

---

## App Review Information

| Field | Value |
|-------|-------|
| First name | Boris |
| Last name | Serzhanovich |
| Phone | TODO |
| Email | TODO |
| Demo account email | `appreview@footsteper.app` *(provision before submit)* |
| Demo account password | TODO |
| Notes | "App requires location, microphone, and Apple Health permissions to demonstrate full functionality. AI Coach uses Vertex AI through our Cloud Function proxy — keys are not stored in the app." |

---

## Pre-submission checklist

- [ ] Apple Developer Program membership active
- [ ] App ID created with Sign in with Apple, HealthKit, In-App Purchase capabilities
- [ ] Bundle ID matches `com.borisdev.Stepper`
- [ ] Privacy Policy / Terms / Support URLs return 200 (GitHub Pages enabled)
- [ ] All `INFOPLIST_KEY_NS*UsageDescription` strings reviewed and human-readable
- [ ] `PrivacyInfo.xcprivacy` matches the App Privacy answers in ASC
- [ ] At least one App Icon variant present (light, dark, tinted)
- [ ] App Store screenshots uploaded for iPhone 6.9", iPhone 6.7", iPad 13"
- [ ] Demo account works without a real user signing up
- [ ] Account deletion flow works end-to-end and leaves no orphaned data
- [ ] Subscription paywall shows price, period, and trial terms before tap
- [ ] StoreKit Configuration tested with `xcrun simctl --set-environment`
- [ ] Build uploaded via Xcode → Organizer → Distribute App
- [ ] Export Compliance: `ITSAppUsesNonExemptEncryption = NO` set
- [ ] Age rating questionnaire completed (4+, no objectionable content)
- [ ] App Tracking Transparency NOT used (we don't track) — no ATT prompt shown
