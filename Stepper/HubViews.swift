import SwiftUI
import MapKit

struct RoutesAndChallengesHub: View {
    @Environment(\.dismiss) var dismiss; @EnvironmentObject var routeManager: RouteManager; @State private var showQuest = false
    var body: some View {
        ZStack {
            AppTheme.bgDark.ignoresSafeArea(); MeshGradientBackground()
            VStack(spacing: 0) {
                VStack(spacing: 15) {
                    HStack { Button(action: { dismiss() }) { Image(systemName: "chevron.down").font(.title2).foregroundColor(.white).padding(5).background(.ultraThinMaterial).clipShape(Circle()) }.buttonStyle(BouncyButton()); Spacer(); Text("Cyber Hub 🌐").font(.title2.bold()).foregroundColor(.white); Spacer(); Image(systemName: "plus.circle.fill").font(.title2).foregroundColor(.clear) }.padding(.horizontal)
                    HStack(spacing: 15) { HubStatCard(title: "Шаги", value: "8,432", icon: "shoeprints.fill", color: AppTheme.neonGreen); HubStatCard(title: "Км", value: "5.2", icon: "point.topleft.down.curvedto.point.bottomright.up", color: AppTheme.accentCyan); HubStatCard(title: "Ранг", value: "Золото", icon: "crown.fill", color: AppTheme.gold) }.padding(.horizontal)
                    HStack(spacing: 15) { SubTabBtn(title: "Challenges", selected: $routeManager.activeHubTab); Button(action: { triggerImpact(); showQuest = true }) { Text("Quest 🔥").font(.subheadline.bold()).padding(.horizontal, 20).padding(.vertical, 10).background(AppTheme.accentPurple).cornerRadius(15).foregroundColor(.white) }.buttonStyle(BouncyButton()); SubTabBtn(title: "Clubs", selected: $routeManager.activeHubTab); SubTabBtn(title: "Routes", selected: $routeManager.activeHubTab) }.padding(.horizontal)
                }.padding(.top, 50).padding(.bottom, 10).background(.ultraThinMaterial)
                ScrollView(showsIndicators: false) {
                    if routeManager.activeHubTab == "Challenges" { ChallengesMainView() }
                    else if routeManager.activeHubTab == "Clubs" { ClubsMainView() }
                    else if routeManager.activeHubTab == "Routes" { RoutesMainView() }
                }
            }
        }.sheet(isPresented: $showQuest) { QuestSheet() }
    }
}
struct SubTabBtn: View { let title: String; @Binding var selected: String; var body: some View { Button(action: { triggerImpact(); withAnimation { selected = title } }) { Text(title).font(.subheadline.bold()).padding(.horizontal, 15).padding(.vertical, 10).background(selected == title ? Color.white : Color.white.opacity(0.1)).foregroundColor(selected == title ? .black : .white).cornerRadius(15) }.buttonStyle(BouncyButton()) } }

struct RoutesMainView: View {
    @EnvironmentObject var routeManager: RouteManager; @State private var selectedSavedRoute: CustomRoute? = nil
    var body: some View {
        VStack(spacing: 15) {
            Text("Доступные тропы 🔥").font(.title3.bold()).foregroundColor(.white).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal).padding(.top)
            ForEach(routeManager.savedRoutes) { route in
                let startPos = route.points.first ?? CLLocationCoordinate2D(latitude: 53.9, longitude: 27.5); let diff = routeManager.difficulty(for: route.distance)
                Button(action: { triggerImpact(); selectedSavedRoute = route }) {
                    VStack(spacing: 0) {
                        Map(initialPosition: .camera(MapCamera(centerCoordinate: startPos, distance: 3000, heading: 0, pitch: 45))) { MapPolyline(coordinates: route.points).stroke(AppTheme.neonGreen, style: StrokeStyle(lineWidth: 4, lineCap: .round)) }.frame(height: 100).allowsHitTesting(false).colorScheme(.dark).mask(LinearGradient(colors: [.white, .clear], startPoint: .top, endPoint: .bottom))
                        HStack(spacing: 15) {
                            ZStack { Circle().fill(route.isUserCreated ? AppTheme.accentPurple.opacity(0.3) : AppTheme.accentCyan.opacity(0.3)).frame(width: 50, height: 50); Image(systemName: route.activity.icon).foregroundColor(route.isUserCreated ? AppTheme.accentPurple : AppTheme.accentCyan) }
                            VStack(alignment: .leading) { HStack { Text(route.name).font(.headline).foregroundColor(.white); if route.isUserCreated { Text("Твоя").font(.caption2).padding(4).background(AppTheme.accentPurple).cornerRadius(5).foregroundColor(.white) } }; HStack { Text(String(format: "%.1f км", route.distance)).font(.caption).foregroundColor(.gray); Text("• \(diff.title)").font(.caption2.bold()).foregroundColor(diff.color) } }
                            Spacer()
                            Text("Открыть").font(.subheadline.bold()).padding(.horizontal, 15).padding(.vertical, 8).background(Color.white.opacity(0.1)).foregroundColor(.white).cornerRadius(10)
                        }.padding()
                    }.background(.ultraThinMaterial).cornerRadius(20).overlay(RoundedRectangle(cornerRadius: 20).stroke(AnyShapeStyle(AppTheme.glassGradient), lineWidth: 1)).padding(.horizontal)
                }.buttonStyle(BouncyButton())
            }
        }.padding(.bottom, 50).sheet(item: $selectedSavedRoute) { route in SavedRouteDetailSheet(route: route).environmentObject(routeManager) }
    }
}

struct SavedRouteDetailSheet: View {
    @EnvironmentObject var routeManager: RouteManager; @Environment(\.dismiss) var dismiss; let route: CustomRoute
    var body: some View {
        let startPos = route.points.first ?? CLLocationCoordinate2D(latitude: 53.9, longitude: 27.5); let endPos = route.points.last ?? startPos; let diff = routeManager.difficulty(for: route.distance)
        ZStack {
            Map(initialPosition: .camera(MapCamera(centerCoordinate: startPos, distance: 5000, heading: 0, pitch: 60))) { MapPolyline(coordinates: route.points).stroke(AppTheme.neonGreen, style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round)); Annotation("Start", coordinate: startPos) { Circle().fill(AppTheme.neonGreen).frame(width: 20) }; Annotation("Finish", coordinate: endPos) { Circle().fill(AppTheme.accentRed).frame(width: 20) } }.colorScheme(.dark).ignoresSafeArea().allowsHitTesting(false)
            LinearGradient(colors: [.clear, AppTheme.bgDark.opacity(0.8), AppTheme.bgDark], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            VStack {
                Capsule().fill(Color.white.opacity(0.5)).frame(width: 40, height: 5).padding(.top, 10); Spacer()
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 5) { HStack { Image(systemName: route.activity.icon).font(.title).foregroundColor(AppTheme.neonGreen); Text(route.name).font(.system(size: 32, weight: .black, design: .rounded)).foregroundColor(.white) }; Text(route.desc).font(.subheadline).foregroundColor(.gray) }.frame(maxWidth: .infinity, alignment: .leading)
                    HStack { VStack { Text("Дистанция").font(.caption).foregroundColor(.gray); Text(String(format: "%.1f км", route.distance)).font(.title2.bold()).foregroundColor(AppTheme.accentCyan) }; Spacer(); VStack { Text("Сложность").font(.caption).foregroundColor(.gray); Text(diff.title).font(.title2.bold()).foregroundColor(diff.color) } }.padding().background(.ultraThinMaterial).cornerRadius(20).overlay(RoundedRectangle(cornerRadius: 20).stroke(AnyShapeStyle(AppTheme.glassGradient), lineWidth: 1))
                    Button("Показать на карте 🗺️") { triggerImpact(style: .heavy); routeManager.previewRoute = route; routeManager.isHubPresented = false; dismiss() }.font(.title2.bold()).padding().frame(maxWidth: .infinity).background(AppTheme.accentBlue).foregroundColor(.white).cornerRadius(20).shadow(color: AppTheme.accentBlue, radius: 10).buttonStyle(BouncyButton())
                }.padding(25).background(.ultraThinMaterial).cornerRadius(30).overlay(RoundedRectangle(cornerRadius: 30).stroke(AnyShapeStyle(AppTheme.glassGradient), lineWidth: 1)).padding(.bottom, 20)
            }
        }
    }
}

struct ClubsMainView: View {
    @EnvironmentObject var routeManager: RouteManager; @State private var showCreateClub = false; @State private var selectedClub: ClubModel? = nil
    @State private var allClubs: [ClubModel] = [ ClubModel(name: "Night Runners", desc: "Бегаем после полуночи.", hashtags: "#night #speed #neon", members: 12450, color: AppTheme.accentPurple, icon: "moon.stars.fill", hqLevel: 4), ClubModel(name: "Mountain Goats", desc: "Только хардкорный хайкинг.", hashtags: "#hike #mountains #hard", members: 3200, color: AppTheme.accentOrange, icon: "mountain.2.fill", hqLevel: 2) ]
    var body: some View {
        VStack(spacing: 20) {
            if routeManager.myOwnedClub == nil { Button(action: { showCreateClub = true }) { HStack { Image(systemName: "plus.circle.fill"); Text("Создать свой Клуб 👑") }.font(.headline.bold()).foregroundColor(.black).frame(maxWidth: .infinity).padding().background(AppTheme.gold).cornerRadius(20).shadow(color: AppTheme.gold.opacity(0.5), radius: 10).padding(.horizontal) }.buttonStyle(BouncyButton()) } else { VStack(spacing: 5) { Text("Твой Клуб 👑").font(.headline).foregroundColor(AppTheme.gold); Button(action: { selectedClub = routeManager.myOwnedClub! }) { ClubCard(club: routeManager.myOwnedClub!) }.buttonStyle(BouncyButton()) } }
            Text("Рейтинг Клубов 🔥").font(.title3.bold()).foregroundColor(.white).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal)
            ForEach(allClubs) { club in Button(action: { selectedClub = club }) { ClubCard(club: club) }.buttonStyle(BouncyButton()) }
        }.sheet(isPresented: $showCreateClub) { CreateClubSheet() }.sheet(item: $selectedClub) { club in ClubDetailSheet(club: club).environmentObject(routeManager) }
    }
}

struct ClubCard: View {
    let club: ClubModel; @State private var pulse = false
    var body: some View {
        HStack { Image(systemName: club.icon).font(.system(size: 40)).foregroundColor(club.color).frame(width: 60); VStack(alignment: .leading) { Text(club.name).font(.title3.bold()).foregroundColor(.white); Text(club.desc).font(.caption).foregroundColor(.gray); HStack { Text("👥 \(club.members)").font(.caption2.bold()).foregroundColor(club.color); Text("💰 \(club.points)").font(.caption2.bold()).foregroundColor(AppTheme.gold) }; HStack(spacing: 4) { Image(systemName: "building.2.fill").font(.caption2).foregroundColor(.gray); Text("База ур. \(club.hqLevel)").font(.caption2.bold()).foregroundColor(.gray) } }; Spacer() }.padding().background(.ultraThinMaterial).cornerRadius(20).overlay(RoundedRectangle(cornerRadius: 20).stroke(club.isOwner ? AnyShapeStyle(club.color.opacity(pulse ? 0.8 : 0.2)) : AnyShapeStyle(AppTheme.glassGradient), lineWidth: club.isOwner ? 2 : 1)).shadow(color: club.isOwner ? club.color.opacity(pulse ? 0.5 : 0.1) : .clear, radius: 10).padding(.horizontal).onAppear { withAnimation(.easeInOut(duration: 1.5).repeatForever()) { pulse = true } }
    }
}

struct CreateClubSheet: View {
    @Environment(\.dismiss) var dismiss; @EnvironmentObject var routeManager: RouteManager; @State private var cName = ""; @State private var cDesc = ""; @State private var cHashtags = ""; @State private var selectedColor = AppTheme.gold; @State private var selectedIcon = "shield.fill"
    let colors: [Color] = [AppTheme.gold, AppTheme.accentPurple, AppTheme.neonGreen, AppTheme.accentRed, AppTheme.accentCyan]; let icons = ["shield.fill", "flame.fill", "bolt.fill", "star.fill", "moon.stars.fill"]
    var body: some View {
        ZStack {
            AppTheme.bgDark.ignoresSafeArea(); MeshGradientBackground()
            VStack(spacing: 25) {
                Capsule().fill(Color.gray).frame(width: 40, height: 5).padding(.top); Text("Основать Клуб 👑").font(.largeTitle.bold()).foregroundColor(.white)
                Image(systemName: selectedIcon).font(.system(size: 80)).foregroundColor(selectedColor).shadow(color: selectedColor, radius: 15).padding()
                TextField("Название Клуба...", text: $cName).padding().background(.ultraThinMaterial).cornerRadius(15).foregroundColor(.white).padding(.horizontal)
                TextField("Слоган / Описание...", text: $cDesc).padding().background(.ultraThinMaterial).cornerRadius(15).foregroundColor(.white).padding(.horizontal)
                TextField("Хэштеги (через пробел)...", text: $cHashtags).padding().background(.ultraThinMaterial).cornerRadius(15).foregroundColor(AppTheme.accentCyan).padding(.horizontal)
                Text("Цвет").font(.headline).foregroundColor(.white).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal); HStack { ForEach(colors, id: \.self) { c in Button(action: { selectedColor = c }) { Circle().fill(c).frame(width: 40, height: 40).overlay(Circle().stroke(Color.white, lineWidth: selectedColor == c ? 3 : 0)) } } }
                Text("Эмблема").font(.headline).foregroundColor(.white).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal); HStack { ForEach(icons, id: \.self) { i in Button(action: { selectedIcon = i }) { Image(systemName: i).font(.title).foregroundColor(.white).padding().background(selectedIcon == i ? selectedColor.opacity(0.5) : Color.white.opacity(0.1)).cornerRadius(15) } } }
                Spacer()
                Button("Создать Империю 🔥") { triggerNotification(type: .success); let newClub = ClubModel(name: cName.isEmpty ? "My Epic Club" : cName, desc: cDesc.isEmpty ? "We run the city." : cDesc, hashtags: cHashtags.isEmpty ? "#run #win" : cHashtags, members: 1, color: selectedColor, icon: selectedIcon, isOwner: true); routeManager.myOwnedClub = newClub; dismiss() }.font(.title2.bold()).padding().frame(maxWidth: .infinity).background(selectedColor).foregroundColor(.black).cornerRadius(20).padding(.horizontal).padding(.bottom, 20).buttonStyle(BouncyButton())
            }
        }
    }
}

struct ClubMatchRow: View { let enemy: String; let result: String; let score: String; let color: Color; var body: some View { HStack { Image(systemName: result.contains("Победа") ? "trophy.fill" : "skull").foregroundColor(color).font(.title3); VStack(alignment: .leading, spacing: 3) { Text("vs \(enemy)").font(.headline.bold()).foregroundColor(.white); Text(score).font(.caption).foregroundColor(.gray) }; Spacer(); Text(result).font(.subheadline.bold()).foregroundColor(color) }.padding(12).background(Color.white.opacity(0.05)).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.3), lineWidth: 1)) } }

struct ClubDetailSheet: View {
    let club: ClubModel; @EnvironmentObject var routeManager: RouteManager; @State private var pulse = false; @State private var showDuelSettings = false; @State private var isHistoryExpanded = false; @State private var isJoining = false
    var body: some View {
        let hasClub = routeManager.myOwnedClub != nil; let isChallenged = routeManager.challengedClubs.contains(club.id); let isMember = routeManager.joinedClubId == club.id
        ZStack {
            AppTheme.bgDark.ignoresSafeArea(); MeshGradientBackground(); FloatingParticlesView()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    Capsule().fill(Color.gray).frame(width: 40, height: 5).padding(.top)
                    ZStack { Circle().fill(club.color.opacity(0.2)).frame(width: 150, height: 150).scaleEffect(pulse ? 1.1 : 0.9).animation(.easeInOut(duration: 1.5).repeatForever(), value: pulse); Image(systemName: club.icon).font(.system(size: 80)).foregroundColor(club.color).shadow(color: club.color, radius: 15) }.padding(.top, 20)
                    Text(club.name).font(.system(size: 36, weight: .black, design: .rounded)).foregroundColor(.white); Text(club.hashtags).font(.caption.bold()).foregroundColor(AppTheme.accentCyan); Text(club.desc).font(.subheadline).foregroundColor(.gray).multilineTextAlignment(.center).padding(.horizontal)
                    HStack(spacing: 20) { VStack { Text("Участники").font(.caption).foregroundColor(.gray); Text("\(club.members + (isMember ? 1 : 0))").font(.title2.bold()).foregroundColor(.white) }.frame(maxWidth: .infinity).padding().background(.ultraThinMaterial).cornerRadius(15).overlay(RoundedRectangle(cornerRadius: 15).stroke(AnyShapeStyle(AppTheme.glassGradient), lineWidth: 1)); VStack { Text("Казна Клуба").font(.caption).foregroundColor(.gray); Text("\(club.points)").font(.title2.bold()).foregroundColor(AppTheme.gold) }.frame(maxWidth: .infinity).padding().background(.ultraThinMaterial).cornerRadius(15).overlay(RoundedRectangle(cornerRadius: 15).stroke(AnyShapeStyle(AppTheme.glassGradient), lineWidth: 1)) }.padding(.horizontal)
                    VStack(alignment: .leading, spacing: 10) { HStack { Image(systemName: "building.2.fill").foregroundColor(club.color); Text("Штаб-квартира: Уровень \(club.hqLevel)").font(.headline).foregroundColor(.white) }; Text("База позволяет получать больше очков за совместные пробежки.").font(.caption).foregroundColor(.gray) }.padding().frame(maxWidth: .infinity, alignment: .leading).background(.ultraThinMaterial).cornerRadius(15).overlay(RoundedRectangle(cornerRadius: 15).stroke(AnyShapeStyle(AppTheme.glassGradient), lineWidth: 1)).padding(.horizontal)
                    VStack(alignment: .leading, spacing: 10) {
                        Button(action: { triggerImpact(); withAnimation(.spring()) { isHistoryExpanded.toggle() } }) { VStack(alignment: .leading, spacing: 10) { HStack { Text("История Боев ⚔️").font(.headline).foregroundColor(.white); Spacer(); Image(systemName: isHistoryExpanded ? "chevron.up" : "chevron.down").foregroundColor(.gray) }; HStack(spacing: 15) { VStack(alignment: .leading) { Text("Победы").font(.caption).foregroundColor(.gray); Text("\(Int.random(in: 10...50))").font(.title2.bold()).foregroundColor(AppTheme.neonGreen) }; Spacer(); VStack(alignment: .leading) { Text("Поражения").font(.caption).foregroundColor(.gray); Text("\(Int.random(in: 0...20))").font(.title2.bold()).foregroundColor(AppTheme.accentRed) }; Spacer(); VStack(alignment: .leading) { Text("Винрейт").font(.caption).foregroundColor(.gray); Text("\(Int.random(in: 50...95))%").font(.title2.bold()).foregroundColor(AppTheme.accentCyan) } } } }.buttonStyle(BouncyButton())
                        if isHistoryExpanded { VStack(spacing: 10) { ClubMatchRow(enemy: "Neon Dashers", result: "Победа 🏆", score: "Шаги: 100k vs 95k", color: AppTheme.neonGreen); ClubMatchRow(enemy: "Urban Foxes", result: "Победа 🏆", score: "Дистанция: 50км vs 42км", color: AppTheme.neonGreen); ClubMatchRow(enemy: "Iron Walkers", result: "Поражение 💀", score: "Стрик: 12д vs 18д", color: AppTheme.accentRed) }.padding(.top, 10).transition(.opacity.combined(with: .move(edge: .top))) }
                    }.padding().frame(maxWidth: .infinity, alignment: .leading).background(.ultraThinMaterial).cornerRadius(15).overlay(RoundedRectangle(cornerRadius: 15).stroke(AnyShapeStyle(AppTheme.glassGradient), lineWidth: 1)).padding(.horizontal)
                    Spacer(minLength: 30)
                    if !club.isOwner {
                        HStack(spacing: 15) {
                            Button(action: { triggerImpact(style: .heavy); if isMember { routeManager.joinedClubId = nil; routeManager.globalToastMessage = "Вы покинули клуб \(club.name) 🛑" } else { isJoining = true; routeManager.globalToastMessage = "Вы успешно вступили в клуб \(club.name)! 🟢"; DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { withAnimation { isJoining = false; routeManager.joinedClubId = club.id } } } }) { Text(isJoining ? "ВСТУПЛЕНИЕ ✅" : (isMember ? "ПОКИНУТЬ ❌" : "Вступить 🚀")).font(.title3.bold()).padding().frame(maxWidth: .infinity).background(isJoining ? AppTheme.neonGreen : (isMember ? AppTheme.accentRed : club.color)).foregroundColor(isJoining ? .black : (isMember ? .white : .black)).cornerRadius(20).shadow(color: isJoining ? AppTheme.neonGreen : (isMember ? AppTheme.accentRed : club.color.opacity(0.5)), radius: 10) }.buttonStyle(BouncyButton())
                            Button(isChallenged ? "ВЫЗОВ ОТПРАВЛЕН ✅" : "Вызов ⚔️") { if isChallenged { return }; if hasClub { triggerImpact(style: .heavy); showDuelSettings = true } else { triggerImpact(style: .light) } }.font(isChallenged ? .headline.bold() : .title3.bold()).padding().frame(maxWidth: .infinity).background(isChallenged ? AppTheme.neonGreen : (hasClub ? AppTheme.accentRed : Color.gray.opacity(0.3))).foregroundColor(isChallenged ? .black : (hasClub ? .white : .gray)).cornerRadius(20).shadow(color: isChallenged ? AppTheme.neonGreen : (hasClub ? AppTheme.accentRed : .clear), radius: 10).buttonStyle(BouncyButton()).disabled(!hasClub || isChallenged)
                        }.padding(.horizontal).padding(.bottom, 30)
                    }
                }
            }
        }.onAppear { pulse = true }.sheet(isPresented: $showDuelSettings) { ClubDuelConfigSheet(targetClub: club).environmentObject(routeManager) }
    }
}

struct ClubDuelConfigSheet: View {
    let targetClub: ClubModel; @EnvironmentObject var routeManager: RouteManager; @Environment(\.dismiss) var dismiss; let duelDisciplines = ["Общая цель (Шаги)", "Соревнование (За пъедестал)", "Своя Тропа (GPS Маршрут)", "Серия дней (Стрик)", "Ультра-марафон (На дистанцию)"]
    @State private var selectedDiscipline = "Общая цель (Шаги)"; @State private var distance: Double = 5.0; @State private var wager: Double = 100.0
    var body: some View {
        let myPoints = Double(routeManager.myOwnedClub?.points ?? 1000)
        ZStack {
            AppTheme.bgDark.ignoresSafeArea(); MeshGradientBackground()
            VStack(spacing: 25) {
                Capsule().fill(Color.gray).frame(width: 40, height: 5).padding(.top); Text("Объявить Войну ⚔️").font(.largeTitle.bold()).foregroundColor(.white); Text("Против: \(targetClub.name)").font(.headline).foregroundColor(targetClub.color)
                VStack(alignment: .leading, spacing: 10) { Text("Выберите дисциплину").font(.subheadline).foregroundColor(.gray); Picker("Дисциплина", selection: $selectedDiscipline) { ForEach(duelDisciplines, id: \.self) { disc in Text(disc).tag(disc) } }.pickerStyle(.menu).padding().frame(maxWidth: .infinity).background(.ultraThinMaterial).cornerRadius(15).tint(.white) }.padding(.horizontal)
                VStack(alignment: .leading, spacing: 10) { Text("Цель: \(Int(distance)) км").font(.headline).foregroundColor(.white); Slider(value: $distance, in: 1...100, step: 1).tint(AppTheme.accentCyan) }.padding().background(.ultraThinMaterial).cornerRadius(15).padding(.horizontal)
                VStack(alignment: .leading, spacing: 10) { Text("Ставка Клуба: \(Int(wager)) 💰").font(.headline).foregroundColor(AppTheme.gold); Text("Максимум: \(Int(myPoints)) (Ваша казна)").font(.caption).foregroundColor(.gray); Slider(value: $wager, in: 100...max(100, myPoints), step: 100).tint(AppTheme.gold) }.padding().background(.ultraThinMaterial).cornerRadius(15).padding(.horizontal)
                Spacer()
                Button("БРОСИТЬ ВЫЗОВ 🔥") { triggerImpact(style: .heavy); routeManager.challengedClubs.insert(targetClub.id); dismiss() }.font(.title2.bold()).padding().frame(maxWidth: .infinity).background(AppTheme.accentRed).foregroundColor(.white).cornerRadius(20).shadow(color: AppTheme.accentRed, radius: 15).padding(.horizontal).padding(.bottom, 30).buttonStyle(BouncyButton())
            }
        }
    }
}

struct ChallengesMainView: View {
    @EnvironmentObject var routeManager: RouteManager; @State private var showCreateChallenge = false; @State private var selectedChallenge: AppChallenge? = nil
    var body: some View {
        VStack(spacing: 25) {
            if !routeManager.userChallenges.isEmpty { VStack(alignment: .leading, spacing: 15) { Text("Мои Челленджи 🏆").font(.title2.bold()).foregroundColor(.white).padding(.horizontal); ForEach(routeManager.userChallenges) { chal in ChallengeCardGen(challenge: chal) { selectedChallenge = chal } } } }
            VStack(alignment: .leading, spacing: 15) { Text("Recommended 🔥").font(.title2.bold()).foregroundColor(.white).padding(.horizontal); ForEach(generatedChallenges) { chal in ChallengeCardGen(challenge: chal) { selectedChallenge = chal } } }
            Button(action: { showCreateChallenge = true }) { HStack { Image(systemName: "plus.diamond.fill"); Text("Создать свой Челлендж 🔥") }.font(.headline.bold()).foregroundColor(.black).frame(maxWidth: .infinity).padding().background(AppTheme.neonGreen).cornerRadius(20).shadow(color: AppTheme.neonGreen.opacity(0.6), radius: 15).padding(.horizontal) }.buttonStyle(BouncyButton()).padding(.bottom, 50)
        }.fullScreenCover(isPresented: $showCreateChallenge) { CreateChallengeRouter() }.sheet(item: $selectedChallenge) { chal in ChallengeDetailSheet(challenge: chal) }
    }
}

struct ChallengeCardGen: View {
    let challenge: AppChallenge; let action: () -> Void; @EnvironmentObject var routeManager: RouteManager
    var body: some View {
        let isJoined = routeManager.joinedChallenges.contains(challenge.id)
        Button(action: action) {
            HStack(spacing: 0) {
                ZStack { challenge.color.opacity(0.8); Image(systemName: "figure.\(challenge.type.lowercased())").font(.system(size: 40)).foregroundColor(.white) }.frame(width: 100)
                VStack(alignment: .leading, spacing: 8) { HStack { Text(challenge.title).font(.headline.bold()).foregroundColor(.white).lineLimit(1); Spacer(); Image(systemName: "seal.fill").symbolRenderingMode(.multicolor).foregroundColor(AppTheme.gold) }; Text(challenge.desc).font(.caption).foregroundColor(.gray).lineLimit(1); VStack(spacing: 4) { HStack { Text("\(challenge.current)").font(.caption2.bold()).foregroundColor(challenge.color); Spacer(); Text("\(challenge.target)").font(.caption2).foregroundColor(.gray) }; GeometryReader { geo in ZStack(alignment: .leading) { Capsule().fill(Color.white.opacity(0.1)).frame(height: 6); Capsule().fill(challenge.color).frame(width: geo.size.width * CGFloat(challenge.current) / CGFloat(challenge.target), height: 6) } }.frame(height: 6) }.padding(.top, 5) }.padding(12)
            }.background(.ultraThinMaterial).cornerRadius(20).overlay(RoundedRectangle(cornerRadius: 20).stroke(isJoined ? AnyShapeStyle(AppTheme.neonGreen) : AnyShapeStyle(AppTheme.glassGradient), lineWidth: isJoined ? 2 : 1)).padding(.horizontal)
        }.buttonStyle(BouncyButton())
    }
}

struct ChallengeDetailSheet: View {
    let challenge: AppChallenge; @EnvironmentObject var routeManager: RouteManager; @Environment(\.dismiss) var dismiss; @State private var pulse = false
    var body: some View {
        let isJoined = routeManager.joinedChallenges.contains(challenge.id)
        ZStack {
            AppTheme.bgDark.ignoresSafeArea(); MeshGradientBackground(); FloatingParticlesView()
            VStack(spacing: 20) {
                Capsule().fill(Color.gray).frame(width: 40, height: 5).padding(.top)
                Image(systemName: "figure.\(challenge.type.lowercased())").font(.system(size: 80)).foregroundColor(challenge.color).shadow(color: challenge.color, radius: pulse ? 20 : 5).scaleEffect(pulse ? 1.1 : 1.0).padding(.top, 20)
                Text(challenge.title).font(.system(size: 36, weight: .black, design: .rounded)).foregroundColor(.white).multilineTextAlignment(.center); Text(challenge.hashtags).font(.caption.bold()).foregroundColor(AppTheme.accentCyan); Text(challenge.story).font(.subheadline).foregroundColor(.white).multilineTextAlignment(.center).padding(.horizontal, 20)
                HStack(spacing: 30) { VStack { Text("Цель").foregroundColor(.gray); Text("\(challenge.target) \(challenge.type)").font(.title2.bold()).foregroundColor(.white) }; VStack { Text("Участников").foregroundColor(.gray); Text("\(challenge.joined)").font(.title2.bold()).foregroundColor(challenge.color) } }.padding().background(.ultraThinMaterial).cornerRadius(20)
                VStack(spacing: 5) { HStack { Text("Прогресс").font(.caption).foregroundColor(.gray); Spacer(); Text("\(challenge.current) / \(challenge.target)").font(.caption.bold()).foregroundColor(challenge.color) }; GeometryReader { geo in ZStack(alignment: .leading) { Capsule().fill(Color.white.opacity(0.1)).frame(height: 10); Capsule().fill(challenge.color).frame(width: geo.size.width * CGFloat(challenge.current) / CGFloat(challenge.target), height: 10).shadow(color: challenge.color, radius: 5) } }.frame(height: 10) }.padding(.horizontal, 30)
                Spacer()
                Button(action: { triggerImpact(style: .heavy); if isJoined { routeManager.joinedChallenges.remove(challenge.id) } else { routeManager.joinedChallenges.insert(challenge.id); triggerNotification(type: .success) }; dismiss() }) { Text(isJoined ? "ПОКИНУТЬ ЧЕЛЛЕНДЖ" : "УЧАСТВОВАТЬ 🔥").font(.title2.bold()).frame(maxWidth: .infinity).padding().background(isJoined ? Color.gray : challenge.color).foregroundColor(isJoined ? .white : .black).cornerRadius(20).shadow(color: isJoined ? .clear : challenge.color, radius: 15) }.padding(.horizontal).padding(.bottom, 20).buttonStyle(BouncyButton())
            }
        }.onAppear { withAnimation(.easeInOut(duration: 1).repeatForever()) { pulse = true } }
    }
}

enum ChallengeCreationType { case shared, soloPodium, streak, trail, longDistance }

struct CreateChallengeRouter: View {
    @Environment(\.dismiss) var dismiss; @EnvironmentObject var routeManager: RouteManager
    @State private var step = 0; @State private var cType: ChallengeCreationType = .shared; @State private var targetValue = ""; @State private var selectedDate = Date(); @State private var chName = ""; @State private var chDesc = ""; @State private var chHash = ""; @State private var isDistance = false; @State private var calendarOpen = false
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.bgDark.ignoresSafeArea(); MeshGradientBackground()
                VStack {
                    ProgressView(value: Double(step + 1), total: 3.0).tint(AppTheme.neonGreen).padding(.horizontal).padding(.top, 10)
                    if step == 0 { step0View.transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))) }
                    else if step == 1 { step1View.transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))) }
                    else if step == 2 { step2View.transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))) }
                }.animation(.spring(), value: step)
            }.navigationBarItems(leading: Button("Отмена") { dismiss() })
        }
    }
    
    @ViewBuilder private var step0View: some View { VStack { Text("Выбери тип 🔥").font(.title.bold()).foregroundColor(.white).padding(.top); ScrollView { VStack(spacing: 15) { TypeBtn(title: "1. Общая цель", desc: "Шаги вместе", icon: "person.3.fill", color: AppTheme.accentOrange) { cType = .shared; step = 1 }; TypeBtn(title: "2. Соревнование", desc: "За пъедестал", icon: "trophy.fill", color: AppTheme.gold) { cType = .soloPodium; step = 1 }; TypeBtn(title: "3. Своя Тропа", desc: "GPS Маршрут", icon: "map.fill", color: AppTheme.accentPurple) { cType = .trail; step = 1 }; TypeBtn(title: "4. Серия дней", desc: "Держи стрик", icon: "flame.fill", color: AppTheme.accentRed) { cType = .streak; step = 1 }; TypeBtn(title: "5. Ультра-марафон", desc: "Огромная дистанция", icon: "figure.walk.motion", color: AppTheme.neonGreen) { cType = .longDistance; step = 1 } }.padding() } } }
    @ViewBuilder private var step1View: some View { VStack(spacing: 25) { Text("Детали цели 🔥").font(.title.bold()).foregroundColor(.white); TextField("Установите цель (шаги/км)...", text: $targetValue).keyboardType(.numberPad).padding().background(.ultraThinMaterial).cornerRadius(15).foregroundColor(.white); Button(action: { withAnimation { calendarOpen.toggle() } }) { HStack { Image(systemName: "calendar"); Text("Выбрать дату") }.padding().frame(maxWidth: .infinity).background(AppTheme.accentPurple).foregroundColor(.white).cornerRadius(15) }.buttonStyle(BouncyButton()); if calendarOpen { DatePicker("", selection: $selectedDate, displayedComponents: .date).datePickerStyle(.graphical).colorScheme(.dark).padding().background(.ultraThinMaterial).cornerRadius(20) }; Spacer(); Button("Далее 🔥") { step = 2 }.padding().frame(maxWidth: .infinity).background(AppTheme.neonGreen).foregroundColor(.black).cornerRadius(15).buttonStyle(BouncyButton()) }.padding() }
    @ViewBuilder private var step2View: some View { VStack(spacing: 20) { Text("Оформление 🔥").font(.title.bold()).foregroundColor(.white); TextField("Название...", text: $chName).padding().background(.ultraThinMaterial).cornerRadius(15).foregroundColor(.white); TextEditor(text: $chDesc).frame(height: 150).padding().background(.ultraThinMaterial).cornerRadius(15).foregroundColor(.white).overlay(Text("Описание...").foregroundColor(.gray).padding().opacity(chDesc.isEmpty ? 1 : 0), alignment: .topLeading); Spacer(); Button("Создать Челлендж! 🔥") { triggerNotification(type: .success); let finalName = chName.isEmpty ? "My Custom Challenge" : chName; let finalTarget = Int(targetValue) ?? 100; let newCh = AppChallenge(title: finalName, desc: chDesc, story: "Твой личный вызов. Докажи, на что способен!", hashtags: "#CustomChallenge #MyRules", type: "Run", target: finalTarget, current: 0, joined: 1, color: AppTheme.neonGreen); routeManager.userChallenges.insert(newCh, at: 0); routeManager.joinedChallenges.insert(newCh.id); dismiss() }.font(.title3.bold()).padding().frame(maxWidth: .infinity).background(AppTheme.fireGradient).foregroundColor(.white).cornerRadius(20).shadow(color: AppTheme.accentRed, radius: 15).buttonStyle(BouncyButton()) }.padding() }
}
struct TypeBtn: View { let title: String; let desc: String; let icon: String; let color: Color; let action: () -> Void; var body: some View { Button(action: { triggerImpact(); action() }) { HStack(spacing: 15) { Image(systemName: icon).font(.title).symbolRenderingMode(.multicolor).foregroundColor(color).frame(width: 40); VStack(alignment: .leading) { Text(title).font(.headline.bold()).foregroundColor(.white); Text(desc).font(.caption).foregroundColor(.gray) }; Spacer(); Image(systemName: "chevron.right").foregroundColor(.gray) }.padding().background(.ultraThinMaterial).cornerRadius(20).overlay(RoundedRectangle(cornerRadius: 20).stroke(color.opacity(0.3), lineWidth: 1)) }.buttonStyle(BouncyButton()) } }

struct QuestSheet: View {
    @State private var selectedDay = 0; @State private var showInfoPopup = false
    let days = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]; let dates = ["12", "13", "14", "15", "16", "17", "18"]
    let allTasks = [("Шаги сегодня (из 10000)", AppTheme.accentOrange), ("Пробежать 5 км", AppTheme.accentRed), ("Добавить 2 друга", AppTheme.accentCyan), ("Сжечь 500 ккал", AppTheme.accentOrange), ("Найти скрытую тропу", AppTheme.accentPurple), ("Поделиться фото", AppTheme.neonGreen), ("Пульс 150 BPM (20 мин)", Color.pink), ("Пройти 3 маршрута", AppTheme.gold)]
    
    var body: some View {
        ZStack {
            AppTheme.bgDark.ignoresSafeArea(); MeshGradientBackground()
            VStack(spacing: 25) {
                Capsule().fill(Color.gray).frame(width: 40, height: 5).padding(.top); Text("Ежедневный Квест 🔥").font(.largeTitle.bold()).foregroundColor(.white)
                ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 15) { ForEach(0..<7, id: \.self) { i in Button(action: { triggerImpact(); withAnimation { selectedDay = i } }) { VStack(spacing: 10) { Text(days[i]).font(.caption).foregroundColor(selectedDay == i ? .black : .gray); Text(dates[i]).font(.title3.bold()).foregroundColor(selectedDay == i ? .black : .white) }.padding(.vertical, 15).padding(.horizontal, 10).background(selectedDay == i ? AppTheme.neonGreen : Color.white.opacity(0.1)).cornerRadius(20).shadow(color: selectedDay == i ? AppTheme.neonGreen.opacity(0.6) : .clear, radius: 10) }.buttonStyle(BouncyButton()) } }.padding(.horizontal) }
                VStack(spacing: 20) { let seed = selectedDay * 3; QuestBar(title: allTasks[seed % allTasks.count].0, progress: Double.random(in: 0.1...1.0), color: allTasks[seed % allTasks.count].1); QuestBar(title: allTasks[(seed+1) % allTasks.count].0, progress: Double.random(in: 0.1...1.0), color: allTasks[(seed+1) % allTasks.count].1); QuestBar(title: allTasks[(seed+2) % allTasks.count].0, progress: Double.random(in: 0.1...1.0), color: allTasks[(seed+2) % allTasks.count].1) }.padding().background(.ultraThinMaterial).cornerRadius(25).padding(.horizontal).id(selectedDay)
                Button(action: { triggerNotification(type: .success) }) { Text("ЗАБРАТЬ +500 Points 🔥").font(.title3.bold()).padding().frame(maxWidth: .infinity).background(AppTheme.gold).foregroundColor(.black).cornerRadius(20).shadow(color: AppTheme.gold, radius: 10) }.padding(.horizontal).padding(.top, 10).buttonStyle(BouncyButton())
                HStack { Image(systemName: "info.square.fill").foregroundColor(AppTheme.accentCyan).font(.title2); VStack(alignment: .leading) { Text("Зачем нужны поинты?").font(.headline).foregroundColor(.white); Text("Удерживайте, чтобы узнать больше...").font(.caption).foregroundColor(.gray) }; Spacer() }.padding().background(.ultraThinMaterial).cornerRadius(20).overlay(RoundedRectangle(cornerRadius: 20).stroke(AnyShapeStyle(AppTheme.glassGradient), lineWidth: 1)).padding(.horizontal).onLongPressGesture { triggerImpact(style: .medium); withAnimation { showInfoPopup = true } }
                Spacer()
            }
            if showInfoPopup {
                ZStack {
                    Color.black.opacity(0.8).ignoresSafeArea().onTapGesture { withAnimation { showInfoPopup = false } }
                    VStack(spacing: 20) {
                        Image(systemName: "info.circle.fill").font(.system(size: 60)).foregroundColor(AppTheme.accentCyan); Text("Зачем нужны поинты?").font(.title.bold()).foregroundColor(.white)
                        Text("Ежедневные квесты — твой главный ресурс для доминирования. Полученные здесь очки напрямую заливаются в твой рейтинг Лиги.\n\nБольше поинтов — выше шанс вырваться из 'Бронзы', ворваться в элитный дивизион 'Чемпионов' и доказать всем, кто здесь настоящий кибер-атлет. Не упускай ни дня!").font(.subheadline).foregroundColor(.gray).multilineTextAlignment(.center).lineSpacing(4).padding(.horizontal)
                        Button("Понятно 🔥") { triggerImpact(); withAnimation { showInfoPopup = false } }.font(.headline).padding().frame(maxWidth: .infinity).background(AppTheme.accentBlue).foregroundColor(.white).cornerRadius(15).padding(.horizontal)
                    }.padding(30).background(AppTheme.bgDark).cornerRadius(30).overlay(RoundedRectangle(cornerRadius: 30).stroke(AnyShapeStyle(AppTheme.glassGradient), lineWidth: 1)).shadow(color: AppTheme.accentCyan.opacity(0.5), radius: 20).padding(20)
                }.zIndex(200).transition(.scale.combined(with: .opacity))
            }
        }
    }
}

struct QuestBar: View {
    let title: String; let progress: Double; let color: Color; @State private var animProg = 0.0
    var body: some View { VStack(alignment: .leading, spacing: 8) { Text(title).font(.headline).foregroundColor(.white); ZStack(alignment: .leading) { Capsule().fill(Color.gray.opacity(0.3)).frame(height: 12); Capsule().fill(color).frame(width: 300 * animProg, height: 12).shadow(color: color, radius: 5) } }.onAppear { withAnimation(.spring(response: 1.0, dampingFraction: 0.7)) { animProg = progress } } }
}
