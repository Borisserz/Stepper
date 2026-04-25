import SwiftUI
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var isAuthorized = false
    override init() {
        super.init()
        manager.delegate = self; manager.desiredAccuracy = kCLLocationAccuracyBest; manager.distanceFilter = 10
    }
    func requestAuth() { manager.requestWhenInUseAuthorization() }
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways { isAuthorized = true; manager.startUpdatingLocation() } else { isAuthorized = false }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        DispatchQueue.main.async { self.location = loc }
    }
}

class RouteManager: ObservableObject {
    @Published var savedRoutes: [CustomRoute] = []
    @Published var activeRoute: CustomRoute? = nil
    @Published var previewRoute: CustomRoute? = nil
    @Published var isTracking = false
    @Published var traveledProgress: CGFloat = 0.0
    
    @Published var joinedChallenges: Set<UUID> = []
    @Published var challengeProgress: [UUID: Double] = [:]
    @Published var userChallenges: [AppChallenge] = []
    
    @Published var isHubPresented = false
    @Published var activeHubTab: String = "Routes"
    
    @Published var myOwnedClub: ClubModel? = nil
    @Published var incomingWarPopup: Bool = false
    @Published var challengedClubs: Set<UUID> = []
    
    @Published var showLiveTracking = false
    @Published var joinedClubId: UUID? = nil
    @Published var globalToastMessage: String? = nil
    
    init() {
        let baseLat = 53.9006, baseLon = 27.5590; let activities: [ActivityType] = [.walk, .run, .hike, .ride]
        let names = ["Лесное озеро", "Центральный даш", "Горный перевал", "Ночной велопробег", "Парк Победы", "Загородная трасса", "Речная тропа", "Старый город"]
        let descriptions = [
            "Дыхание леса очистит ваш разум. Отличный выбор для медитативной пробежки.",
            "Ритм неонового города. Максимальная скорость на асфальтированных дорожках.",
            "Испытание для сильных духом. Крутые подъемы и невероятные виды.",
            "Оседлайте свой байк. Ночные магистрали ждут покорителей скорости.",
            "Классика для кардио. Исторические памятники и ровный асфальт.",
            "Побег из мегаполиса. Длинная прямая трасса для проверки выносливости.",
            "Шум воды и свежий ветер. Идеально для утренней активности.",
            "Сплетение узких улочек. Почувствуйте атмосферу истории в каждом шаге."
        ]
        
        for i in 0..<8 {
            let p1 = CLLocationCoordinate2D(latitude: baseLat + Double.random(in: -0.05...0.05), longitude: baseLon + Double.random(in: -0.05...0.05))
            let p2 = CLLocationCoordinate2D(latitude: p1.latitude + Double.random(in: 0.01...0.03), longitude: p1.longitude + Double.random(in: 0.01...0.03))
            let pm = CLLocationCoordinate2D(latitude: (p1.latitude+p2.latitude)/2 + 0.01, longitude: (p1.longitude+p2.longitude)/2 - 0.01)
            savedRoutes.append(CustomRoute(name: names[i], points: [p1, pm, p2], activity: activities[i % 4], distance: Double.random(in: 2.0...15.0), isUserCreated: false, desc: descriptions[i], popularity: Int.random(in: 500...15000)))
        }
    }
    
    func addRoute(_ route: CustomRoute) { savedRoutes.insert(route, at: 0) }
    func addChallengeProgress(amount: Double) { for id in joinedChallenges { challengeProgress[id, default: 0.0] += amount } }
    func difficulty(for distance: Double) -> (title: String, color: Color) {
        if distance < 5.0 { return ("Лёгкий", AppTheme.neonGreen) }
        else if distance < 10.0 { return ("Средний", AppTheme.accentOrange) }
        else { return ("Хардкор", AppTheme.accentRed) }
    }
}
