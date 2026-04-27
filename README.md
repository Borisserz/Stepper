# footstepeR: Cyberpunk Fitness Ecosystem 

![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg?style=for-the-badge&logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.10-orange.svg?style=for-the-badge&logo=swift)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-red.svg?style=for-the-badge)
![MapKit](https://img.shields.io/badge/Maps-MapKit_%26_CoreLocation-blue.svg?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Work_In_Progress-yellow.svg?style=for-the-badge)

**footstepeR** is a state-of-the-art, fully native iOS fitness tracker and pedometer designed with a deep Cyberpunk/Glassmorphism aesthetic. It transcends traditional step-counting by turning your daily activity into an RPG-like experience with neural implants, cyber-clubs, GPS anomalies, and a built-in AI Coach.

> [!]  
> 🚧 **PROJECT IS IN ACTIVE DEVELOPMENT (WORK IN PROGRESS)** 🚧
>
> - This repository currently showcases the **Frontend and UI/UX concept**.
> - The User Interface, complex particle animations, MapKit logic, and navigation are **90% complete**.
> - **AI Integration is pending:** The Neural Coach (Voice & Text chat) is fully designed but operates on mock data. Integration with an external LLM (e.g., OpenAI API) is planned for the next phase.
> - **Backend & Persistence:** Biometrics, club data, and step history are currently generated locally for demonstration purposes. CoreData/SwiftData and remote backend integration are in progress.

---

## 📸 Application Gallery

<table align="center">
  <tr>
    <td align="center"><b>Main Dashboard</b></td>
    <td align="center"><b>Bio-Sync (Heart Rate)</b></td>
    <td align="center"><b>Neuro-Sleep Analysis</b></td>
  </tr>
  <tr>
    <td><img src="Screenshots/1.png" width="250" style="border-radius: 15px;"></td>
    <td><img src="Screenshots/2.png" width="250" style="border-radius: 15px;"></td>
    <td><img src="Screenshots/3.png" width="250" style="border-radius: 15px;"></td>
  </tr>
  <tr>
    <td align="center"><b>CNS Regeneration</b></td>
    <td align="center"><b>Pro Cardio Protocols</b></td>
    <td align="center"><b>AI Goal Architect</b></td>
  </tr>
  <tr>
    <td><img src="Screenshots/4.png" width="250" style="border-radius: 15px;"></td>
    <td><img src="Screenshots/5.png" width="250" style="border-radius: 15px;"></td>
    <td><img src="Screenshots/6.png" width="250" style="border-radius: 15px;"></td>
  </tr>
  <tr>
    <td align="center"><b>Meteo-Radar & Forecast</b></td>
    <td align="center"><b>Live GPS Tracking</b></td>
    <td align="center"><b>Cyber Hub & Routes</b></td>
  </tr>
  <tr>
    <td><img src="Screenshots/7.png" width="250" style="border-radius: 15px;"></td>
    <td><img src="Screenshots/8.png" width="250" style="border-radius: 15px;"></td>
    <td><img src="Screenshots/9.png" width="250" style="border-radius: 15px;"></td>
  </tr>
</table>

---

## 🌟 Core Features

### 🧠 Neural AI Core (WIP)

- **Voice & Text Assistant:** Built-in chat interface for the AI Coach. Utilizes `Speech` and `AVFoundation` to capture and transcribe user voice in real-time. _(Awaiting LLM hookup)_.
- **Cross-Weather Analysis:** The AI scans the "Meteo-Radar" and determines the optimal activity. For instance, it warns against running during "Acid Rain" to prevent virtual joint damage.
- **Biometric Diagnostics:** Dedicated modules for CNS Recovery, Sleep Phases, and Hydration, featuring dynamic AI-generated text summaries of your current physical state.

### 🗺️ Cyberpunk GPS Tracking (MapKit)

- **Interactive Dark Map:** Fully customized Apple Maps integration displaying user location, custom gradient polylines for routes, and neon annotations.
- **Dynamic Events:** While running, the map generates random "Anomalies" (requiring a sudden pace increase to hack for bonus points) or "AI Ghosts" to race against.
- **Smart Routing:** Drop two pins on the map, and `MKDirections` instantly calculates the real-world pedestrian path, distance, and estimated time.

### 🏆 RPG Gamification & Cyber Hub

- **League System:** Global leaderboards ranging from Bronze to Champions tier. Steps are mined into cryptocurrency-like "points" to rank up.
- **Club Wars:** Create or join a Cyber-Club. Set colors, emblems, and challenge rival factions to step-battles.
- **The Black Market:** An in-app economy where users spend earned points on virtual "Implants" (e.g., Titanium Lungs) to boost their step multipliers permanently.

### 🎨 Advanced UI & Glassmorphism

- **Visual Effects:** Replaces standard iOS components with deep Glassmorphism (frosted glass), Mesh Gradients, and custom multi-layered shadows.
- **Particle Systems:** Custom-built `FloatingParticlesView`, Cyber-Snow, and Acid-Rain overlays that react to the current weather and app state.
- **Haptics Engine:** Extensive use of `UIImpactFeedbackGenerator`. Every tap, scan, and milestone achievement provides satisfying, physical tactile feedback.

---

## 🛠 Technical Architecture

This project strictly adheres to modern Apple development paradigms, prioritizing stunning visuals, smooth animations, and reactive code design.

- **UI/UX:** 100% `SwiftUI`. Built with reusable components, custom `ButtonStyle` implementations (for bouncy interactions), and complex `ZStack` geometry.
- **Location Services:** `MapKit` and `CoreLocation` handle real-time user tracking, route rendering (`MKPolyline`), and coordinate-to-path calculations.
- **Voice Recognition:** Pure `Speech` framework paired with `AVAudioEngine` for capturing audio buffers and live speech-to-text translation without blocking the main thread.
- **State Management:** Utilizes `Combine`, `@StateObject`, and `@EnvironmentObject` (`RouteManager`, `LocationManager`) for seamless data flow across the entire app hierarchy.
- **Reactive Simulation:** Uses `Timer.publish` extensively to simulate live heart rate fluctuations, workout progress, and map events smoothly before real HealthKit data is wired up.

---

## 🚀 Installation & Setup

You will need **macOS Sequoia** (15) and **Xcode 16+**. The deployment target is **iOS 17.0**, so any iPhone or iPad on iOS 17 or later will run the app.

1. **Clone the repository:**

   ```bash
   git clone https://github.com/Borisserz/Stepper.git
   cd Stepper
   ```

2. **Open in Xcode:**

   ```bash
   open Stepper.xcodeproj
   ```

3. **Set your signing team.** The repo intentionally ships **without** a development team. In Xcode:

   - Select the `Stepper` target → Signing & Capabilities → tick "Automatically manage signing" → choose your Personal Team (or paid Apple Developer team).

4. **Build & Run.** A physical iPhone is recommended to fully exercise MapKit, Haptics, the microphone, and HealthKit. The Simulator works for everything except real GPS/HealthKit/microphone.

5. **Permissions.** On first launch the app requests:

   - **Location** — for live GPS tracking and the map.
   - **Microphone** — for the AI Coach voice input.
   - **Speech Recognition** — for transcribing what you say.
   - **Motion & Fitness** — fallback step counter when Apple Health is unavailable.
   - **Apple Health** — primary source for steps, distance, heart rate (PR #2).

## 🛠 Developer Tooling

| File | Purpose |
|------|---------|
| `.swiftlint.yml` | SwiftLint configuration (relaxed; tightened in later PRs). |
| `.github/workflows/ci.yml` | Lints and builds on every push/PR. |
| `scripts/generate_appicon.py` | Regenerates the AppIcon variants from code. |
| `Stepper/PrivacyInfo.xcprivacy` | Apple privacy manifest. Keep in sync with the App Privacy questionnaire in App Store Connect. |
| `docs/` | Privacy Policy, Terms, Support, App Store metadata — also the GitHub Pages source. |

## 📲 App Store submission

See [`docs/app-store-connect.md`](docs/app-store-connect.md) for the full
metadata and pre-submission checklist.

Privacy Policy / Terms / Support are designed to be hosted via GitHub Pages
(Settings → Pages → Source: `docs/` on `main`). After enabling, the URLs you
need for App Store Connect become:

- `https://borisserz.github.io/Stepper/privacy-policy.html`
- `https://borisserz.github.io/Stepper/terms-of-service.html`
- `https://borisserz.github.io/Stepper/support.html`

---

## 📜 License & Copyright

Copyright (c) 2026 [Boris_Serzhanovich]. All rights reserved.

This project is showcased for **portfolio and demonstration purposes only**. The source code, UI designs, and custom aesthetic models are proprietary. They are not licensed for public, commercial use, redistribution, or modification without explicit written permission from the author.
