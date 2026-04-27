import SwiftUI
import SwiftData

@main
struct footstepeRRApp: App {
    @StateObject private var routeManager = RouteManager()
    @State private var account = AccountManager()
    @State private var settings = SettingsStore()
    @State private var health = HealthKitManager()
    @State private var recorder = WorkoutRecorder()
    @State private var subscriptions = SubscriptionManager()
    let modelContainer: ModelContainer

    init() {
        // Firebase boots before *any* UI state is constructed so Auth /
        // Firestore / FirebaseAI are usable from the very first render.
        FirebaseBootstrap.configure()

        // Настройка прозрачного TabBar
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance

        // Инициализация базы данных SwiftData
        do {
            let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.borisdev.FootStepper") ?? FileManager.default.temporaryDirectory
            let dbURL = groupURL.appendingPathComponent("StepperDatabase.sqlite")
            let config = ModelConfiguration(url: dbURL)

            modelContainer = try ModelContainer(
                for: AppUser.self, StepLog.self, AIRoute.self, BiomechanicData.self,
                WorkoutSession.self, WorkoutLocation.self,
                configurations: config
            )
        } catch {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            // swiftlint:disable:next force_try
            modelContainer = try! ModelContainer(
                for: AppUser.self, StepLog.self, AIRoute.self, BiomechanicData.self,
                WorkoutSession.self, WorkoutLocation.self,
                configurations: config
            )
        }
    }

    var body: some Scene {
        WindowGroup {
            RootRouterView()
                .environmentObject(routeManager)
                .environment(account)
                .environment(settings)
                .environment(health)
                .environment(recorder)
                .environment(subscriptions)
                .modelContainer(modelContainer)
                .task { await subscriptions.loadProducts() }
                .preferredColorScheme(.dark)
                #if os(macOS)
                .frame(width: 393, height: 852)
                #endif
        }
        #if os(macOS)
        .windowResizability(.contentSize)
        #endif
    }
}

// MARK: - РОУТЕР ПРИЛОЖЕНИЯ
enum AppFlowState {
    case auth
    case metrics
    case paywall
    case main
}

struct RootRouterView: View {
    @Environment(AccountManager.self) private var account
    @Environment(\.modelContext) private var modelContext
    // Состояние сбрасывается при каждом запуске, поэтому экраны будут показываться всегда
    @State private var flowState: AppFlowState = .auth

    var body: some View {
        ZStack {
            switch flowState {
            case .auth:
                OnboardingAuthView {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        flowState = .metrics
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                
            case .metrics:
                OnboardingMetricsView {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        flowState = .paywall
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                
            case .paywall:
                PremiumPaywallScreen {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        flowState = .main
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                
            case .main:
                MainTabsView()
                    .transition(.opacity)
            }
        }
        .onChange(of: account.isSignedIn) { _, signedIn in
            // When the user signs out or deletes their account from Settings,
            // SettingsView's `dismiss()` is a no-op inside a TabView. Watch the
            // auth state at the root and bounce the user back to onboarding.
            if !signedIn && flowState != .auth {
                // Wipe per-user SwiftData so when the next user signs in on
                // the same device, `FirestoreSyncService.pullIfNeeded` doesn't
                // mistake the previous user's local cache for a populated
                // store and skip the cloud restore. Without this, User B
                // would see User A's workout history.
                LocalDataPurger.purgeWorkouts(in: modelContext)

                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    flowState = .auth
                }
            }
        }
    }
}

/// Owns the "wipe local SwiftData" responsibility so it's testable
/// and not duplicated between the sign-out, delete-account, and
/// future "switch account" flows.
enum LocalDataPurger {
    static func purgeWorkouts(in context: ModelContext) {
        do {
            try context.delete(model: WorkoutLocation.self)
            try context.delete(model: WorkoutSession.self)
            try context.save()
        } catch {
            // Best-effort: an unflushed delete is preferable to crashing
            // during a sign-out. The next pull will reconcile state.
            #if DEBUG
            print("[LocalDataPurger] purge failed: \(error)")
            #endif
        }
    }
}

/// Hosts the bottom tab bar plus the one-shot Firestore pull on first
/// launch (or first launch on a restored device). Lives at this level so
/// it has access to the `\.modelContext` env value seeded by
/// `.modelContainer` on the root.
private struct MainTabsView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            MainScreenView()
                .tabItem { Label("tab.summary", systemImage: "flame.fill") }

            GPSTabView()
                .tabItem { Label("tab.gps", systemImage: "map.fill") }

            SettingsView()
                .tabItem { Label("tab.settings", systemImage: "gearshape.fill") }
        }
        .task {
            // Best-effort cloud restore on fresh installs / new devices.
            // Bails out instantly if SwiftData already has rows.
            await FirestoreSyncService.shared.pullIfNeeded(into: modelContext)
        }
    }
}

// MARK: - ЗАГЛУШКИ ДЛЯ SWIFTDATA
@Model final class AppUser { init() {} }
@Model final class StepLog { init() {} }
@Model final class AIRoute { init() {} }
@Model final class BiomechanicData { init() {} }
