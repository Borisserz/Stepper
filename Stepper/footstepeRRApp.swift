import SwiftUI

@main
struct footstepeRRApp: App {
    @StateObject private var routeManager = RouteManager()

    init() {
        // Делаем нижнюю панель (TabBar) прозрачной, чтобы не было "темной сетки"
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        // Опционально: легкое размытие (раскомментируй строку ниже, если захочешь)
        // appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                MainScreenView()
                    .tabItem { Label("Сводка", systemImage: "flame.fill") }
                
                GPSTabView()
                    .tabItem { Label("GPS Трекинг", systemImage: "map.fill") }
            }
            .environmentObject(routeManager)
            .preferredColorScheme(.dark)
        }
    }
}
