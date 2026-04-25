import SwiftUI

struct LeagueOnboardingView: View {
    @Binding var isPresented: Bool
    @AppStorage("hasSeenLeagueOnboarding") private var hasSeenLeagueOnboarding = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
            VStack(spacing: 25) {
                Image(systemName: "crown.fill").font(.system(size: 80)).symbolRenderingMode(.multicolor).shadow(color: AppTheme.gold, radius: 20)
                Text("Добро пожаловать в Лиги! 🏆").font(.system(size: 30, weight: .black, design: .rounded)).foregroundColor(.white).multilineTextAlignment(.center)
                Text("Тут герои мира ходьбы, бега, велоспорта и все, кто хоть как-то относится к спорту, соревнуются в самой базовой и нужной вещи для человека — это шаги.\n\nТут ты будешь видеть лидерборд с топом людей за все время. И советую поторопиться, ведь даже создатель этого приложения уже далеко не в топе!").font(.headline).foregroundColor(.gray).multilineTextAlignment(.center).padding(.horizontal, 20)
                Button("Погнали! 🔥") { triggerImpact(style: .heavy); hasSeenLeagueOnboarding = true; withAnimation(.spring()) { isPresented = false } }.font(.title2.bold()).padding().frame(maxWidth: .infinity).background(AppTheme.gold).foregroundColor(.black).cornerRadius(20).shadow(color: AppTheme.gold.opacity(0.5), radius: 15).padding(.horizontal, 30).padding(.top, 20).buttonStyle(BouncyButton())
            }.padding(20).background(.ultraThinMaterial).cornerRadius(30).overlay(RoundedRectangle(cornerRadius: 30).stroke(AppTheme.gold.opacity(0.5), lineWidth: 2)).padding(20)
        }
    }
}

struct LeagueSheet: View {
    @Binding var points: Int
    @AppStorage("savedUsername") private var username = ""
    @AppStorage("isUserSignedIn") private var signedIn = false
    @State private var pulse = false; @State private var selectedLeague: League? = nil
    @State private var showSocialPopup = false
    @AppStorage("hasSeenLeagueOnboarding") private var hasSeenLeagueOnboarding = false
    @State private var showOnboarding = false
    
    var body: some View {
        ZStack {
            AppTheme.bgDark.ignoresSafeArea(); MeshGradientBackground()
            if !signedIn {
                VStack(spacing: 20) { Image(systemName: "crown.fill").font(.system(size: 80)).symbolRenderingMode(.multicolor).padding(.top, 40); Text("Вход в Лигу 🔥").font(.largeTitle.bold()).foregroundColor(.white); TextField("Введи свой ник...", text: $username).padding().background(.ultraThinMaterial).cornerRadius(15).foregroundColor(.white).padding(.horizontal, 40); Button("Войти 🔥") { if !username.isEmpty { triggerNotification(type: .success); withAnimation { signedIn = true } } }.padding().frame(width: 200).background(AppTheme.accentBlue).foregroundColor(.white).cornerRadius(15).shadow(color: AppTheme.accentBlue, radius: 10).buttonStyle(BouncyButton()) }
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 25) {
                        HStack { Image(systemName: "timer").foregroundColor(.white); Text("Конец сезона: 12д 04ч").font(.caption.bold()).foregroundColor(.white) }.padding(.horizontal, 15).padding(.vertical, 8).background(AppTheme.accentRed.opacity(0.5)).cornerRadius(15).padding(.top, 20)
                        Text("\(username)'s League 🔥").font(.title.bold()).foregroundColor(.white)
                        Text("Очки: \(points)").font(.system(size: 40, weight: .black)).foregroundColor(AppTheme.gold).shadow(color: AppTheme.gold, radius: pulse ? 15 : 5)
                        HStack(spacing: 15) { VStack { Text("Твой Ранг").font(.caption).foregroundColor(.gray); Text("Топ 15%").font(.headline.bold()).foregroundColor(AppTheme.neonGreen) }.frame(maxWidth: .infinity).padding().background(.ultraThinMaterial).cornerRadius(15); VStack { Text("Игроков").font(.caption).foregroundColor(.gray); Text("142K+").font(.headline.bold()).foregroundColor(AppTheme.accentCyan) }.frame(maxWidth: .infinity).padding().background(.ultraThinMaterial).cornerRadius(15) }.padding(.horizontal)
                        HStack { Image(systemName: "flame.fill").foregroundColor(AppTheme.accentOrange); Text("ДНЕВНОЙ БОНУС: x1.5 за шаги!").font(.subheadline.bold()).foregroundColor(.white); Spacer() }.padding().background(LinearGradient(colors: [AppTheme.accentOrange.opacity(0.4), .clear], startPoint: .leading, endPoint: .trailing)).cornerRadius(15).overlay(RoundedRectangle(cornerRadius: 15).stroke(AppTheme.accentOrange.opacity(0.5), lineWidth: 1)).padding(.horizontal)
                        ForEach(leagues) { league in Button(action: { triggerImpact(); selectedLeague = league }) { HStack { Image(systemName: points >= league.pointsReq ? "trophy.fill" : "lock.fill").foregroundColor(points >= league.pointsReq ? league.color : .gray).font(.title); VStack(alignment: .leading) { Text(league.name).font(.title3.bold()).foregroundColor(.white); Text("Нужно: \(league.pointsReq) pts").font(.caption).foregroundColor(.gray) }; Spacer(); if points >= league.pointsReq { Text("UNLOCKED 🔥").font(.caption.bold()).foregroundColor(league.color) } }.padding().background(.ultraThinMaterial).cornerRadius(20).overlay(RoundedRectangle(cornerRadius: 20).stroke(league.color.opacity(points >= league.pointsReq ? 0.6 : 0.1), lineWidth: 2)).shadow(color: league.color.opacity(points >= league.pointsReq ? 0.3 : 0), radius: 10).opacity(points >= league.pointsReq ? 1.0 : 0.5) }.buttonStyle(BouncyButton()) }.padding(.horizontal)
                        Text("Наши сообщества 🌐").font(.headline).foregroundColor(.gray).padding(.top, 20)
                        HStack(spacing: 30) { Button(action: { triggerImpact(); withAnimation { showSocialPopup = true } }) { Image(systemName: "paperplane.circle.fill").font(.system(size: 45)).foregroundColor(Color(red: 0.17, green: 0.61, blue: 0.85)) }.buttonStyle(BouncyButton()); Button(action: { triggerImpact(); withAnimation { showSocialPopup = true } }) { Image(systemName: "camera.circle.fill").font(.system(size: 45)).foregroundColor(Color.pink) }.buttonStyle(BouncyButton()); Button(action: { triggerImpact(); withAnimation { showSocialPopup = true } }) { Image(systemName: "link.circle.fill").font(.system(size: 45)).foregroundColor(Color.blue) }.buttonStyle(BouncyButton()) }.padding(.bottom, 50)
                    }
                }
            }
            if showSocialPopup {
                ZStack {
                    Color.black.opacity(0.8).ignoresSafeArea().onTapGesture { withAnimation { showSocialPopup = false } }
                    VStack(spacing: 20) {
                        Image(systemName: "hashtag").font(.system(size: 60)).foregroundColor(AppTheme.accentCyan)
                        Text("Делитесь победами!").font(.title.bold()).foregroundColor(.white)
                        Text("Публикуйте фото с нашими тропами, упоминая нас в хэштегах! Ищите соперников по уровню в наших группах!!").font(.subheadline).foregroundColor(.gray).multilineTextAlignment(.center).padding(.horizontal)
                        VStack(spacing: 10) { Text("#CyberRunCity").font(.headline).foregroundColor(AppTheme.neonGreen); Text("#NeonTrails").font(.headline).foregroundColor(AppTheme.accentPurple); Text("#SpeedDemonRun").font(.headline).foregroundColor(AppTheme.accentRed) }.padding().background(.ultraThinMaterial).cornerRadius(15)
                        Button("Понятно 🔥") { triggerImpact(); withAnimation { showSocialPopup = false } }.padding().frame(maxWidth: .infinity).background(AppTheme.accentBlue).foregroundColor(.white).cornerRadius(15).padding(.horizontal)
                    }.padding(30).background(AppTheme.bgDark).cornerRadius(30).overlay(RoundedRectangle(cornerRadius: 30).stroke(AnyShapeStyle(AppTheme.glassGradient), lineWidth: 1)).shadow(color: AppTheme.accentCyan.opacity(0.5), radius: 20).padding(20)
                }.zIndex(200).transition(.scale.combined(with: .opacity))
            }
            if showOnboarding { LeagueOnboardingView(isPresented: $showOnboarding).zIndex(300).transition(.scale.combined(with: .opacity)) }
        }.onAppear { withAnimation(.easeInOut(duration: 1).repeatForever()) { pulse = true }; if !hasSeenLeagueOnboarding { showOnboarding = true } }.sheet(item: $selectedLeague) { league in LeagueDetailLeaderboard(league: league, currentPoints: $points) }
    }
}

struct LeaderboardPlayer: Identifiable { let id = UUID(); let rank: Int; let name: String; let points: Int; let isUser: Bool }

struct LeaderboardPlayerRow: View {
    let player: LeaderboardPlayer; let leagueColor: Color; let pulse: Bool; let userRank: Int
    var body: some View {
        let isTarget = player.rank == (userRank - 1)
        HStack(spacing: 15) {
            HStack(spacing: 2) { Text("#\(player.rank)").font(.title3.bold()).foregroundColor(player.rank <= 3 ? AppTheme.gold : .gray); if player.rank == 1 { Image(systemName: "crown.fill").symbolRenderingMode(.multicolor).font(.caption2) } }.frame(width: 45, alignment: .leading)
            Image(systemName: player.isUser ? "person.crop.circle.fill" : "person.fill").font(.title2).foregroundColor(player.isUser ? leagueColor : Color.white.opacity(0.5))
            VStack(alignment: .leading) { Text(player.name).font(player.isUser ? .headline.bold() : .headline).foregroundColor(player.isUser ? .white : .gray); if isTarget { Text("TARGET 🎯").font(.caption2.bold()).foregroundColor(AppTheme.accentRed) } }
            Spacer(); Text("\(player.points) pts").font(.subheadline.bold()).foregroundColor(player.isUser ? leagueColor : .white)
        }.padding().background(Group { if player.isUser { leagueColor.opacity(0.2) } else if isTarget { AppTheme.accentRed.opacity(0.1) } else { Rectangle().fill(.ultraThinMaterial) } }).cornerRadius(15).overlay(RoundedRectangle(cornerRadius: 15).stroke(player.isUser ? leagueColor : (isTarget ? AppTheme.accentRed : Color.clear), lineWidth: (player.isUser || isTarget) ? 2 : 0)).shadow(color: player.isUser ? leagueColor.opacity(0.5) : (isTarget ? AppTheme.accentRed.opacity(0.5) : Color.clear), radius: 10).scaleEffect(player.isUser && pulse ? 1.02 : 1.0).padding(.horizontal)
    }
}

struct LeagueDetailLeaderboard: View {
    let league: League; @Binding var currentPoints: Int; @Environment(\.dismiss) var dismiss; @State private var toastMessage: String? = nil; @State private var progressAnim: CGFloat = 0.0; @State private var pulse: Bool = false
    let players: [LeaderboardPlayer] = [ LeaderboardPlayer(rank: 1, name: "MaxSpeed", points: 84500, isUser: false), LeaderboardPlayer(rank: 2, name: "Runner_01", points: 82100, isUser: false), LeaderboardPlayer(rank: 3, name: "CyberHiker", points: 79000, isUser: false), LeaderboardPlayer(rank: 4, name: "You (Ты)", points: 76500, isUser: true), LeaderboardPlayer(rank: 5, name: "IronLegs", points: 75000, isUser: false) ]
    var body: some View {
        ZStack {
            AppTheme.bgDark.ignoresSafeArea(); MeshGradientBackground(); FloatingParticlesView(); Circle().fill(league.color.opacity(0.3)).frame(width: 300, height: 300).blur(radius: 100).position(x: UIScreen.main.bounds.width/2, y: 150)
            ScrollView { VStack(spacing: 25) { Capsule().fill(Color.gray).frame(width: 40, height: 5).padding(.top); VStack { Image(systemName: "trophy.fill").font(.system(size: 60)).foregroundColor(league.color).shadow(color: league.color, radius: pulse ? 20 : 5).scaleEffect(pulse ? 1.1 : 0.9); Text(league.name).font(.system(size: 32, weight: .black, design: .rounded)).foregroundColor(.white).shadow(color: league.color, radius: 10) }.onLongPressGesture { triggerImpact(style: .heavy); withAnimation { toastMessage = league.motivation }; DispatchQueue.main.asyncAfter(deadline: .now()+3) { withAnimation { toastMessage = nil } } }
                Text("Займи место в Топ-5 и удержи его до конца месяца, чтобы перейти в лигу выше! 🚀").font(.subheadline.bold()).foregroundColor(.white).multilineTextAlignment(.center).padding().background(.ultraThinMaterial).cornerRadius(20).overlay(RoundedRectangle(cornerRadius: 20).stroke(league.color.opacity(0.5), lineWidth: 1)).padding(.horizontal)
                VStack(alignment: .leading, spacing: 15) { HStack { Text("Leaderboard 🏆").font(.title3.bold()).foregroundColor(.white); Spacer(); HStack(spacing: 5) { Circle().fill(Color.red).frame(width: 8, height: 8).opacity(pulse ? 1 : 0); Text("LIVE").font(.caption.bold()).foregroundColor(.red) } }.padding(.horizontal); ForEach(players) { p in LeaderboardPlayerRow(player: p, leagueColor: league.color, pulse: pulse, userRank: 4) } }
            } }
            if let msg = toastMessage { VStack { CyberToast(message: msg); Spacer() }.zIndex(100) }
        }.onAppear { withAnimation(.easeInOut(duration: 1).repeatForever()) { pulse = true }; withAnimation(.spring()) { progressAnim = 0.25 } }
    }
}
