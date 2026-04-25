import SwiftUI
import CoreLocation

struct CustomRoute: Identifiable { let id = UUID(); let name: String; let points: [CLLocationCoordinate2D]; let activity: ActivityType; let distance: Double; let isUserCreated: Bool; let desc: String; let popularity: Int }
struct ClubModel: Identifiable, Hashable { let id = UUID(); let name: String; let desc: String; var hashtags: String = "#cyber #run"; var members: Int; let color: Color; let icon: String; var points: Int = 10000; var isOwner: Bool = false; var hqLevel: Int = 1 }

enum ActivityType: String, CaseIterable {
    case walk = "Walk", run = "Run", hike = "Hike", ride = "Ride"
    var burnRate: Double { switch self { case .walk: return 0.08; case .run: return 0.25; case .hike: return 0.15; case .ride: return 0.18 } }
    var icon: String { switch self { case .walk: return "figure.walk"; case .run: return "figure.run"; case .hike: return "figure.hiking"; case .ride: return "bicycle" } }
}

struct League: Identifiable, Equatable { let id = UUID(); let name: String; let pointsReq: Int; let color: Color; let motivation: String }
let leagues = [ League(name: "Бронза", pointsReq: 0, color: .orange, motivation: "Начало пути!"), League(name: "Золото", pointsReq: 5000, color: AppTheme.gold, motivation: "Держи темп! 🏆"), League(name: "Бриллиант", pointsReq: 15000, color: AppTheme.accentCyan, motivation: "Ты машина! 💎"), League(name: "Чемпионы", pointsReq: 50000, color: AppTheme.accentPurple, motivation: "Легенда! 👑") ]

struct AppChallenge: Identifiable, Hashable { let id = UUID(); let title: String; let desc: String; let story: String; let hashtags: String; let type: String; let target: Int; var current: Int; let joined: Int; let color: Color }
let generatedChallenges = [
    AppChallenge(title: "April Steps", desc: "Делаем шаги!", story: "Весна пробуждает город. Твоя миссия — показать всем, что твои ноги готовы к бесконечным прогулкам.", hashtags: "#AprilSteps #CyberWalk", type: "Walk", target: 200, current: 85, joined: 1450, color: AppTheme.accentOrange),
    AppChallenge(title: "Speed Demon", desc: "На скорость.", story: "Скорость — твое второе имя. Выжимай максимум из своих имплантов.", hashtags: "#SpeedDemon #Sprint", type: "Run", target: 10, current: 9, joined: 890, color: AppTheme.accentRed)
]

struct FriendUser: Identifiable { let id = UUID(); let name: String; let points: Int; let isOnline: Bool; let location: String; let clubIcon: String?; let clubColor: Color?; let avatarColor: Color; var isSOSActive: Bool = false }
let mockFriends = [ FriendUser(name: "Елена (Жена)", points: 45000, isOnline: true, location: "Парк Победы", clubIcon: "heart.fill", clubColor: .pink, avatarColor: AppTheme.accentPurple), FriendUser(name: "Макс (Сын)", points: 12000, isOnline: false, location: "Дом", clubIcon: "bolt.fill", clubColor: AppTheme.gold, avatarColor: AppTheme.neonGreen), FriendUser(name: "АндрейСмаев", points: 100000, isOnline: true, location: "Тренажерный зал", clubIcon: "flame.fill", clubColor: AppTheme.accentRed, avatarColor: AppTheme.accentOrange) ]

struct FriendRoutePreview: Identifiable { let id = UUID(); let title: String; let points: [CLLocationCoordinate2D]; let distance: Double; let desc: String }

enum CyberWeatherState: String, CaseIterable { case clear = "Ясно 🌤", rain = "Кислотный дождь 🌧", snow = "Неоновый снег ❄️" }
struct DailyWeatherModel: Identifiable { let id = UUID(); let dayIndex: Int; let condition: CyberWeatherState; let temp: Int; let wind: Double; let humidity: Int }
enum WeatherSuitability { case perfect, acceptable, bad; var color: Color { switch self { case .perfect: return AppTheme.neonGreen; case .acceptable: return AppTheme.accentOrange; case .bad: return AppTheme.accentRed } }; var title: String { switch self { case .perfect: return "СИСТЕМА ОДОБРЯЕТ 🟢"; case .acceptable: return "ПОВЫШЕННЫЙ РИСК 🟡"; case .bad: return "КРИТИЧЕСКАЯ УГРОЗА 🔴" } } }
struct SportSuitabilityCheck { let status: WeatherSuitability; let message: String; let gear: [String]; let alternative: ActivityType? }
