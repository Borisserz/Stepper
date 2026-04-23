import SwiftUI
import MapKit

struct LiveTrackingSheet: View {
    @State private var searchText = ""; @Environment(\.dismiss) var dismiss; @State private var pulse = false; @State private var mySOSActive = false
    @State private var selectedFriend: FriendUser? = nil
    var filtered: [FriendUser] { if searchText.isEmpty { return mockFriends.filter { $0.name != "АндрейСмаев" } } else { return mockFriends.filter { $0.name.lowercased().contains(searchText.lowercased()) } } }
    
    var body: some View {
        ZStack {
            AppTheme.bgDark.ignoresSafeArea(); MeshGradientBackground(); FloatingParticlesView()
            if mySOSActive { Rectangle().fill(Color.red.opacity(0.3)).ignoresSafeArea().animation(.easeInOut(duration: 0.5).repeatForever(), value: pulse) }
            
            if mySOSActive { VStack { Text("ПЕРЕДАЧА КООРДИНАТ БЛИЖАЙШИМ АТЛЕТАМ...").font(.caption.bold()).foregroundColor(.white).padding(8).background(Color.red).cornerRadius(10).shadow(color: .red, radius: 10).scaleEffect(pulse ? 1.05 : 0.95).padding(.top, 50); Spacer() }.zIndex(100) }
            
            VStack(spacing: 0) {
                VStack(spacing: 15) {
                    Capsule().fill(Color.gray.opacity(0.5)).frame(width: 40, height: 5).padding(.top, 15)
                    VStack(spacing: 8) { Text("Live Track 📡").font(.system(size: 34, weight: .black, design: .rounded)).foregroundColor(.white); Text("Для семьи и друзей. Отслеживайте геолокацию близких.").font(.subheadline).foregroundColor(.gray).multilineTextAlignment(.center).padding(.horizontal, 20) }
                    HStack { Image(systemName: "magnifyingglass").foregroundColor(AppTheme.neonGreen); TextField("Поиск по нику...", text: $searchText).foregroundColor(.white).tint(AppTheme.neonGreen) }.padding(15).background(.ultraThinMaterial).cornerRadius(20).overlay(RoundedRectangle(cornerRadius: 20).stroke(AnyShapeStyle(AppTheme.glassGradient), lineWidth: 1)).padding(.horizontal).padding(.top, 10)
                }.padding(.bottom, 20).background(Color.black.opacity(0.3))
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 15) {
                        HStack { Text(searchText.isEmpty ? "Мои близкие ❤️" : "Результаты 🔍").font(.title2.bold()).foregroundColor(.white); Spacer() }.padding(.horizontal).padding(.top, 15)
                        ForEach(filtered) { f in
                            Button(action: { triggerImpact(); selectedFriend = f }) {
                                HStack(spacing: 15) {
                                    ZStack(alignment: .bottomTrailing) { Circle().strokeBorder(f.avatarColor, lineWidth: 2).background(Circle().fill(.ultraThinMaterial)).frame(width: 55, height: 55); Image(systemName: "person.crop.circle.fill").font(.system(size: 55)).foregroundColor(f.avatarColor); ZStack { Circle().fill(f.isOnline ? AppTheme.neonGreen : Color.gray).frame(width: 16, height: 16); if f.isOnline { Circle().stroke(AppTheme.neonGreen, lineWidth: 2).frame(width: 24, height: 24).opacity(pulse ? 0 : 1).scaleEffect(pulse ? 1.5 : 0.5) } }.overlay(Circle().stroke(AppTheme.bgDark, lineWidth: 3)).offset(x: 2, y: 2) }
                                    VStack(alignment: .leading, spacing: 6) { Text(f.name).font(.headline.bold()).foregroundColor(.white); HStack(spacing: 4) { Image(systemName: f.isOnline ? "location.fill" : "clock.fill").font(.caption2).foregroundColor(f.isOnline ? AppTheme.accentCyan : .gray); Text(f.isOnline ? f.location : "Был: \(f.location)").font(.caption).foregroundColor(.gray) } }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 6) { HStack(spacing: 4) { Image(systemName: "star.fill").font(.caption2).foregroundColor(AppTheme.gold); Text("\(f.points)").font(.subheadline.bold()).foregroundColor(.white) }; if let ci = f.clubIcon, let cc = f.clubColor { HStack(spacing: 4) { Image(systemName: "shield.fill").font(.system(size: 8)).foregroundColor(.gray); Image(systemName: ci).font(.caption).foregroundColor(cc) }.padding(.horizontal, 8).padding(.vertical, 4).background(cc.opacity(0.2)).cornerRadius(8).overlay(RoundedRectangle(cornerRadius: 8).stroke(cc.opacity(0.5), lineWidth: 1)) } }
                                }.padding(15).background(.ultraThinMaterial).cornerRadius(20).overlay(RoundedRectangle(cornerRadius: 20).stroke(AnyShapeStyle(AppTheme.glassGradient), lineWidth: 1)).shadow(color: f.isOnline ? f.avatarColor.opacity(0.15) : .clear, radius: 15).padding(.horizontal)
                            }.buttonStyle(BouncyButton())
                        }
                        Button(action: { triggerImpact(style: .heavy); withAnimation { mySOSActive.toggle() } }) { HStack { Image(systemName: "exclamationmark.triangle.fill"); Text(mySOSActive ? "ОТМЕНИТЬ СИГНАЛ SOS" : "БРОСИТЬ СИГНАЛ SOS") }.font(.headline.bold()).foregroundColor(.white).frame(maxWidth: .infinity).padding().background(mySOSActive ? Color.gray : Color.red).cornerRadius(20).shadow(color: mySOSActive ? .clear : .red, radius: 10) }.buttonStyle(BouncyButton()).padding(20)
                    }
                }.padding(.bottom, 50)
            }
        }.onAppear { withAnimation(.easeInOut(duration: 1).repeatForever()) { pulse = true } }.sheet(item: $selectedFriend) { friend in FriendDetailSheet(friend: friend) }
    }
}

struct FriendDetailSheet: View {
    let friend: FriendUser; @State private var pulse = false; @State private var radarRotate = 0.0; @State private var showFilterToast = false; @State private var showChallengesSheet = false
    let friendRoutes = [
        FriendRoutePreview(title: "Лесное кольцо", points: [CLLocationCoordinate2D(latitude: 53.90, longitude: 27.55), CLLocationCoordinate2D(latitude: 53.91, longitude: 27.56), CLLocationCoordinate2D(latitude: 53.89, longitude: 27.57)], distance: 4.2, desc: "Отличный круговой маршрут по лесной зоне для поддержания темпа."),
        FriendRoutePreview(title: "Городской спринт", points: [CLLocationCoordinate2D(latitude: 53.92, longitude: 27.50), CLLocationCoordinate2D(latitude: 53.90, longitude: 27.52)], distance: 2.8, desc: "Прямая трасса без светофоров для рекордов скорости."),
        FriendRoutePreview(title: "Горный хайкинг", points: [CLLocationCoordinate2D(latitude: 53.95, longitude: 27.60), CLLocationCoordinate2D(latitude: 53.96, longitude: 27.65), CLLocationCoordinate2D(latitude: 53.98, longitude: 27.62)], distance: 7.5, desc: "Сложный рельеф с большим перепадом высот. Только для профи.")
    ]
    @State private var selectedPreview: FriendRoutePreview? = nil

    var body: some View {
        ZStack {
            AppTheme.bgDark.ignoresSafeArea(); MeshGradientBackground(); FloatingParticlesView()
            VStack {
                ScrollView {
                    VStack(spacing: 25) {
                        Capsule().fill(Color.gray).frame(width: 40, height: 5).padding(.top)
                        ZStack { Circle().stroke(friend.avatarColor.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [10, 5])).frame(width: 150, height: 150).rotationEffect(.degrees(radarRotate)).animation(.linear(duration: 10).repeatForever(autoreverses: false), value: radarRotate); Circle().stroke(friend.avatarColor.opacity(0.1), lineWidth: 10).frame(width: 130, height: 130).scaleEffect(pulse ? 1.05 : 0.95).animation(.easeInOut(duration: 1.5).repeatForever(), value: pulse); Image(systemName: "person.crop.circle.fill").font(.system(size: 100)).foregroundColor(friend.avatarColor).shadow(color: friend.avatarColor, radius: 20) }.padding(.top, 20)
                        VStack(spacing: 5) { Text(friend.name).font(.system(size: 32, weight: .black, design: .rounded)).foregroundColor(.white); HStack { Circle().fill(friend.isOnline ? AppTheme.neonGreen : Color.gray).frame(width: 10, height: 10); Text(friend.isOnline ? "В сети (\(friend.location))" : "Не в сети").font(.subheadline).foregroundColor(.gray) } }
                        HStack(spacing: 15) { StatBox(title: "Пройдено", value: "\(Int.random(in: 100...2000)) км", color: AppTheme.accentCyan); StatBox(title: "Сожжено", value: "\(Int.random(in: 10000...90000))", color: AppTheme.accentOrange); Button(action: { triggerImpact(); showChallengesSheet = true }) { StatBox(title: "Челленджи", value: "3 🏆", color: AppTheme.gold) }.buttonStyle(BouncyButton()) }.padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Любимые тропы 📍").font(.title3.bold()).foregroundColor(.white).padding(.horizontal)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(friendRoutes) { r in Button(action: { triggerImpact(); selectedPreview = r }) { VStack(alignment: .leading) { ZStack { RoundedRectangle(cornerRadius: 15).fill(Color.white.opacity(0.1)).frame(width: 160, height: 100); Map(interactionModes: []) { MapPolyline(coordinates: r.points).stroke(friend.avatarColor, style: StrokeStyle(lineWidth: 3, lineCap: .round)) }.opacity(0.5).allowsHitTesting(false); Image(systemName: "map.fill").font(.largeTitle).foregroundColor(.white).shadow(color: .black, radius: 5) }.frame(width: 160, height: 100).cornerRadius(15); Text(r.title).font(.caption.bold()).foregroundColor(.white).padding(.top, 5) }.padding(10).background(.ultraThinMaterial).cornerRadius(20).overlay(RoundedRectangle(cornerRadius: 20).stroke(AnyShapeStyle(AppTheme.glassGradient), lineWidth: 1)) }.buttonStyle(BouncyButton()) }
                                }.padding(.horizontal)
                            }
                        }
                    }
                }
                Button(action: { triggerImpact(style: .heavy); withAnimation { showFilterToast = true }; DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { withAnimation { showFilterToast = false } } }) { Text("Запросить отслеживание 📡").font(.title3.bold()).padding().frame(maxWidth: .infinity).background(AppTheme.neonGreen).foregroundColor(.black).cornerRadius(20).shadow(color: AppTheme.neonGreen.opacity(pulse ? 0.8 : 0.3), radius: 10).scaleEffect(pulse ? 1.02 : 1.0).animation(.easeInOut(duration: 1.5).repeatForever(), value: pulse) }.buttonStyle(BouncyButton()).padding(.horizontal).padding(.bottom, 20)
            }
            if showFilterToast { VStack { CyberToast(message: "Вы запросили безопасное отслеживание, ожидайте ответа."); Spacer() }.zIndex(100) }
        }.onAppear { radarRotate = 360; pulse = true }.sheet(item: $selectedPreview) { route in FriendRoutePreviewSheet(route: route, avatarColor: friend.avatarColor) }.sheet(isPresented: $showChallengesSheet) { FriendChallengesSheet(friend: friend) }
    }
}

struct FriendChallengesSheet: View {
    let friend: FriendUser; @Environment(\.dismiss) var dismiss
    let friendChallenges = [ AppChallenge(title: "April Steps", desc: "Весенний марафон шагов", story: "", hashtags: "", type: "Walk", target: 200, current: Int.random(in: 120...190), joined: 0, color: AppTheme.accentOrange), AppChallenge(title: "Speed Demon", desc: "Спринт на скорость", story: "", hashtags: "", type: "Run", target: 10, current: 10, joined: 0, color: AppTheme.accentRed), AppChallenge(title: "Neon Rider", desc: "Ночные заезды", story: "", hashtags: "", type: "Ride", target: 50, current: Int.random(in: 15...45), joined: 0, color: AppTheme.accentPurple) ]
    var body: some View {
        ZStack {
            AppTheme.bgDark.ignoresSafeArea(); MeshGradientBackground(); FloatingParticlesView()
            VStack(spacing: 20) {
                Capsule().fill(Color.gray).frame(width: 40, height: 5).padding(.top)
                HStack(spacing: 15) { Image(systemName: "person.crop.circle.fill").font(.system(size: 45)).foregroundColor(friend.avatarColor); VStack(alignment: .leading) { Text("Челленджи").font(.title2.bold()).foregroundColor(.white); Text(friend.name).font(.caption).foregroundColor(.gray) }; Spacer() }.padding(.horizontal).padding(.top, 10)
                ScrollView(showsIndicators: false) { VStack(spacing: 15) { ForEach(friendChallenges) { chal in FriendChallengeCard(challenge: chal) } }.padding(.horizontal).padding(.bottom, 30) }
            }
        }
    }
}

struct FriendChallengeCard: View {
    let challenge: AppChallenge
    var body: some View {
        let isCompleted = challenge.current >= challenge.target
        HStack(spacing: 0) {
            ZStack { challenge.color.opacity(0.8); Image(systemName: "figure.\(challenge.type.lowercased())").font(.system(size: 40)).foregroundColor(.white) }.frame(width: 90)
            VStack(alignment: .leading, spacing: 8) { HStack { Text(challenge.title).font(.headline.bold()).foregroundColor(.white).lineLimit(1); Spacer(); if isCompleted { Image(systemName: "checkmark.seal.fill").foregroundColor(AppTheme.neonGreen) } else { Image(systemName: "flame.fill").foregroundColor(challenge.color) } }; Text(challenge.desc).font(.caption).foregroundColor(.gray).lineLimit(1)
                VStack(spacing: 4) { HStack { Text("\(challenge.current)").font(.caption2.bold()).foregroundColor(isCompleted ? AppTheme.neonGreen : challenge.color); Spacer(); Text("\(challenge.target)").font(.caption2).foregroundColor(.gray) }; GeometryReader { geo in ZStack(alignment: .leading) { Capsule().fill(Color.white.opacity(0.1)).frame(height: 6); Capsule().fill(isCompleted ? AppTheme.neonGreen : challenge.color).frame(width: geo.size.width * min(CGFloat(challenge.current) / CGFloat(challenge.target), 1.0), height: 6).shadow(color: isCompleted ? AppTheme.neonGreen.opacity(0.5) : challenge.color.opacity(0.5), radius: 5) } }.frame(height: 6) }.padding(.top, 5)
            }.padding(12)
        }.background(.ultraThinMaterial).cornerRadius(20).overlay(RoundedRectangle(cornerRadius: 20).stroke(isCompleted ? AnyShapeStyle(AppTheme.neonGreen.opacity(0.5)) : AnyShapeStyle(AppTheme.glassGradient), lineWidth: isCompleted ? 2 : 1)).shadow(color: isCompleted ? AppTheme.neonGreen.opacity(0.2) : .clear, radius: 10)
    }
}

struct FriendRoutePreviewSheet: View {
    let route: FriendRoutePreview; let avatarColor: Color
    @Environment(\.dismiss) var dismiss; @EnvironmentObject var routeManager: RouteManager
    var body: some View {
        ZStack {
            AppTheme.bgDark.ignoresSafeArea()
            Map(initialPosition: .automatic) { MapPolyline(coordinates: route.points).stroke(avatarColor, style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)); if let start = route.points.first { Annotation("Start", coordinate: start) { Circle().fill(AppTheme.neonGreen).frame(width: 15) } }; if let end = route.points.last { Annotation("Finish", coordinate: end) { Circle().fill(AppTheme.accentRed).frame(width: 15) } } }.colorScheme(.dark).ignoresSafeArea().allowsHitTesting(false)
            LinearGradient(colors: [.clear, AppTheme.bgDark.opacity(0.8), AppTheme.bgDark], startPoint: .top, endPoint: .bottom).ignoresSafeArea().allowsHitTesting(false)
            VStack {
                Capsule().fill(Color.white.opacity(0.5)).frame(width: 40, height: 5).padding(.top, 10); Spacer()
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 5) { Text(route.title).font(.system(size: 32, weight: .black, design: .rounded)).foregroundColor(.white); Text(route.desc).font(.subheadline).foregroundColor(.gray) }.frame(maxWidth: .infinity, alignment: .leading)
                    HStack { VStack { Text("Дистанция").font(.caption).foregroundColor(.gray); Text(String(format: "%.1f км", route.distance)).font(.title2.bold()).foregroundColor(AppTheme.accentCyan) }; Spacer(); VStack { Text("Автор").font(.caption).foregroundColor(.gray); Image(systemName: "person.fill").font(.title2).foregroundColor(avatarColor) } }.padding().background(.ultraThinMaterial).cornerRadius(20).overlay(RoundedRectangle(cornerRadius: 20).stroke(AnyShapeStyle(AppTheme.glassGradient), lineWidth: 1))
                    Button("Перейти на маршрут 🗺️") { triggerImpact(style: .heavy); let mappedRoute = CustomRoute(name: route.title, points: route.points, activity: .walk, distance: route.distance, isUserCreated: false, desc: route.desc, popularity: 1); routeManager.previewRoute = mappedRoute; routeManager.showLiveTracking = false }.font(.title3.bold()).padding().frame(maxWidth: .infinity).background(AppTheme.neonGreen).foregroundColor(.black).cornerRadius(20).buttonStyle(BouncyButton())
                }.padding(25).background(.ultraThinMaterial).cornerRadius(30).overlay(RoundedRectangle(cornerRadius: 30).stroke(avatarColor.opacity(0.3), lineWidth: 1)).padding(.bottom, 20)
            }
        }
    }
}
