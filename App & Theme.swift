import SwiftUI
import MapKit
import CoreLocation
import Combine

// MARK: - EXTENSIONS (ДОСТАЕМ ИЗВИЛИСТЫЙ МАРШРУТ ИЗ APPLE MAPS)
extension MKRoute {
    var coordinates: [CLLocationCoordinate2D] {
        let pointCount = self.polyline.pointCount
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: pointCount)
        self.polyline.getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        return coords
    }
}

func triggerImpact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) { UIImpactFeedbackGenerator(style: style).impactOccurred() }
func triggerNotification(type: UINotificationFeedbackGenerator.FeedbackType) { UINotificationFeedbackGenerator().notificationOccurred(type) }

@main
struct EKRANApp: App {
    @StateObject private var routeManager = RouteManager()
    var body: some Scene {
        WindowGroup {
            GPSTabView()
                .environmentObject(routeManager)
                .preferredColorScheme(.dark)
        }
    }
}

struct AppTheme {
    static let bgDark = Color(red: 0.06, green: 0.06, blue: 0.11)
    static let accentRed = Color(red: 0.91, green: 0.27, blue: 0.38)
    static let accentOrange = Color(red: 1.0, green: 0.5, blue: 0.0)
    static let accentBlue = Color(red: 0.06, green: 0.20, blue: 0.88)
    static let accentCyan = Color(red: 0.0, green: 0.8, blue: 1.0)
    static let accentPurple = Color(red: 0.30, green: 0.30, blue: 0.89)
    static let neonGreen = Color(red: 0.2, green: 0.9, blue: 0.5)
    static let gold = Color(red: 1.0, green: 0.84, blue: 0.0)
    static let fireGradient = LinearGradient(colors: [accentOrange, accentRed, accentPurple], startPoint: .leading, endPoint: .trailing)
    static let glassGradient = LinearGradient(colors: [.white.opacity(0.3), .white.opacity(0.05), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let epicGradient = LinearGradient(colors: [gold, accentOrange, accentRed], startPoint: .bottom, endPoint: .top)
}
