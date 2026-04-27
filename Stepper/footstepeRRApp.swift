import SwiftUI
import SwiftData

@main
struct footstepeRRApp: App {
    @StateObject private var routeManager = RouteManager()
    let modelContainer: ModelContainer

    init() {
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
                configurations: config
            )
        } catch {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            modelContainer = try! ModelContainer(for: AppUser.self, StepLog.self, AIRoute.self, BiomechanicData.self, configurations: config)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootRouterView()
                .environmentObject(routeManager)
                .modelContainer(modelContainer)
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
                TabView {
                    MainScreenView()
                        .tabItem { Label("Сводка", systemImage: "flame.fill") }
                    
                    GPSTabView()
                        .tabItem { Label("GPS Трекинг", systemImage: "map.fill") }
                }
                .transition(.opacity)
            }
        }
    }
}

// MARK: - ЗАГЛУШКИ ДЛЯ SWIFTDATA
@Model final class AppUser { init() {} }
@Model final class StepLog { init() {} }
@Model final class AIRoute { init() {} }
@Model final class BiomechanicData { init() {} }
