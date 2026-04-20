import SwiftUI

@main
struct footstepeRRApp: App {
    var body: some Scene {
        WindowGroup {
            MainScreenView()
                .preferredColorScheme(.dark) // Принудительно включаем темную Dribbble-тему!
        }
    }
}
