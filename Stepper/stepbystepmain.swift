import SwiftUI
import MapKit
import CoreLocation
import Combine

// MARK: - THEME & CONSTANTS
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
}

enum ActiveSheet: String, Identifiable {
    case goal, map, marathon, blood, cardioPro, sleep, water, recovery
    var id: String { rawValue }
}

// ПРЕМИУМ: Типы облачков для статистики
enum TooltipType {
    case calories, time, distance
}

// MARK: - HAPTICS ENGINE
func triggerImpact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
    let generator = UIImpactFeedbackGenerator(style: style)
    generator.prepare()
    generator.impactOccurred()
}
func triggerNotification(type: UINotificationFeedbackGenerator.FeedbackType) {
    let generator = UINotificationFeedbackGenerator()
    generator.prepare()
    generator.notificationOccurred(type)
}

// MARK: - COMBINE DEBOUNCER
class SearchDebouncer: ObservableObject {
    @Published var searchText: String = ""
    @Published var debouncedText: String = ""
    private var cancellables = Set<AnyCancellable>()
    init() {
        $searchText.debounce(for: .seconds(0.5), scheduler: RunLoop.main).sink { [weak self] text in
            self?.debouncedText = text
        }.store(in: &cancellables)
    }
}

// MARK: - GPS MANAGER
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var isAuthorized = false
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10
        manager.pausesLocationUpdatesAutomatically = true
    }
    func requestAuth() { manager.requestWhenInUseAuthorization() }
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            isAuthorized = true; manager.startUpdatingLocation(); triggerNotification(type: .success)
        } else { isAuthorized = false }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        DispatchQueue.main.async { self.location = loc }
    }
}

// MARK: - MAIN SCREEN
struct MainScreenView: View {
    @Environment(\.scenePhase) var scenePhase
    @StateObject private var locManager = LocationManager()
    @StateObject private var debouncer = SearchDebouncer()
    
    @State private var selectedTab = "Home 🔥"
    @State private var steps: Double = 6432
    @State private var goal: Double = 10000
    @State private var activeSheet: ActiveSheet? = nil
    @State private var isAppActive = true
    
    // ПРЕМИУМ: Состояние для всплывающего облачка
    @State private var activeTooltip: TooltipType? = nil
    
    var body: some View {
        ZStack {
            AnimatedBackgroundView(isActive: isAppActive)
            
            VStack(spacing: 0) {
                LiveStatusPill(isGpsActive: locManager.isAuthorized)
                
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 25) {
                        TopTabsView(selectedTab: $selectedTab)
                        
                        SemiCircleStepView(steps: steps, goal: goal)
                            .scrollTransition { content, phase in
                                content.scaleEffect(phase.isIdentity ? 1 : 0.9).opacity(phase.isIdentity ? 1 : 0.5)
                            }
                        
                        // Передаем activeTooltip в карточки
                        StatsRowView(steps: steps, activeTooltip: $activeTooltip)
                            .modifier(ScrollParallaxModifier())
                            .scrollTransition { content, phase in
                                content.offset(y: phase.isIdentity ? 0 : 20).opacity(phase.isIdentity ? 1 : 0)
                            }
                        
                        VStack(spacing: 12) {
                            AISuggestionsTags(searchText: $debouncer.searchText)
                            AIHelperSearchBar(text: $debouncer.searchText)
                        }
                        .scrollTransition { content, phase in content.scaleEffect(phase.isIdentity ? 1 : 0.95) }
                        
                        ActionGrid(activeSheet: $activeSheet)
                        
                        HorizontalHealthWidgets(activeSheet: $activeSheet)
                        
                        Spacer().frame(height: 70)
                    }
                    .padding(.horizontal)
                }
            }
            
            // ПРЕМИУМ: Всплывающее облачко (Tooltip Overlay) поверх всего!
            if let tooltip = activeTooltip {
                TooltipCloudView(tooltip: tooltip, steps: steps, onClose: {
                    triggerImpact(style: .light)
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        activeTooltip = nil
                    }
                })
            }
        }
        .task { locManager.requestAuth() }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            isAppActive = (newPhase == .active)
        }
        .sheet(item: $activeSheet) { sheet in SheetRouter(sheet: sheet, locManager: locManager) }
    }
}

// MARK: - ПРЕМИУМ: ОБЛАЧКО С ИНФОРМАЦИЕЙ И ССЫЛКОЙ
struct TooltipCloudView: View {
    let tooltip: TooltipType
    let steps: Double
    let onClose: () -> Void
    
    @State private var appear = false
    
    var body: some View {
        ZStack {
            // Размытый фон
            Color.black.opacity(0.5)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture { onClose() }
                .opacity(appear ? 1 : 0)
            
            // Сама плашка облачка
            VStack(spacing: 20) {
                // Иконка
                ZStack {
                    Circle().fill(tooltipColor.opacity(0.2)).frame(width: 60, height: 60)
                    Image(systemName: tooltipIcon)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(tooltipColor)
                        .shadow(color: tooltipColor, radius: 10)
                }
                
                Text(tooltipTitle)
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Text(tooltipDescription)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                
                // Специальная ссылка для калорий
                if tooltip == .calories {
                    Link(destination: URL(string: "https://apps.apple.com")!) {
                        HStack {
                            Image(systemName: "arrow.down.app.fill")
                            Text("Скачать фудтрекер 🔥")
                        }
                        .font(.headline.bold())
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(colors: [AppTheme.accentOrange, AppTheme.accentRed], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(15)
                        .shadow(color: AppTheme.accentRed.opacity(0.5), radius: 10)
                    }
                    .padding(.top, 10)
                }
                
                Button(action: onClose) {
                    Text("Понятно 🔥")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(15)
                        .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.white.opacity(0.2)))
                }
            }
            .padding(25)
            .background(.ultraThinMaterial)
            .cornerRadius(30)
            .overlay(RoundedRectangle(cornerRadius: 30).stroke(AppTheme.glassGradient, lineWidth: 2))
            .shadow(color: tooltipColor.opacity(0.3), radius: 30, y: 15)
            .padding(30)
            .scaleEffect(appear ? 1 : 0.8)
            .opacity(appear ? 1 : 0)
            .rotation3DEffect(.degrees(appear ? 0 : 10), axis: (x: 1, y: 0, z: 0))
        }
        .onAppear {
            triggerImpact(style: .heavy)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { appear = true }
        }
    }
    
    // Динамические данные для облачка
    var tooltipTitle: String {
        switch tooltip {
        case .calories: return "Калории 🔥"
        case .time: return "Активное время 🔥"
        case .distance: return "Пройденный путь 🔥"
        }
    }
    var tooltipDescription: String {
        switch tooltip {
        case .calories: return "Вы потратили \(Int(steps * 0.045)) ккал за активность и можете съесть на столько же больше!"
        case .time: return "Это чистое время вашей активности в движении. Продолжайте в том же духе!"
        case .distance: return "Дистанция рассчитана на основе количества ваших шагов и среднего размера шага."
        }
    }
    var tooltipColor: Color {
        switch tooltip {
        case .calories: return AppTheme.accentOrange
        case .time: return AppTheme.accentCyan
        case .distance: return AppTheme.neonGreen
        }
    }
    var tooltipIcon: String {
        switch tooltip {
        case .calories: return "flame.fill"
        case .time: return "timer"
        case .distance: return "figure.walk"
        }
    }
}

// MARK: - РОУТЕР
struct SheetRouter: View {
    let sheet: ActiveSheet
    @ObservedObject var locManager: LocationManager
    var body: some View {
        Group {
            switch sheet {
            case .goal: GoalSheetView()
            case .map: if locManager.isAuthorized { RealMapRouteSheetView(locManager: locManager) } else { MinskMapRouteSheetView() }
            case .marathon: MarathonSheetView()
            case .blood: BloodHealthSheetView()
            case .cardioPro: CardioProSheetView()
            case .sleep: SleepAISheetView()
            case .water: HydrationSheetView()
            case .recovery: RecoverySheetView()
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - ПРЕМИУМ: ОГНЕННЫЕ ЧАСТИЦЫ
struct FloatingFireParticles: View {
    @State private var animate = false
    var body: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { i in
                Circle()
                    .fill(Color.orange.opacity(Double.random(in: 0.3...0.8)))
                    .frame(width: CGFloat.random(in: 4...8))
                    .blur(radius: CGFloat.random(in: 1...2))
                    .offset(
                        x: animate ? CGFloat.random(in: -120...120) : CGFloat.random(in: -40...40),
                        y: animate ? -150 : 20
                    )
                    .opacity(animate ? 0 : 1)
                    .animation(
                        .easeInOut(duration: Double.random(in: 2...4))
                        .repeatForever(autoreverses: false)
                        .delay(Double.random(in: 0...2)),
                        value: animate
                    )
            }
        }
        .onAppear { animate = true }
    }
}

// MARK: - ИСПРАВЛЕННЫЙ ПОЛУКРУГ
struct SemiCircleStepView: View {
    var steps: Double
    var goal: Double
    @State private var firePulse = false
    @State private var loadProgress = 0.0
    
    let arcSize: CGFloat = 260
    
    var body: some View {
        let progress = min(steps / goal, 1.0)
        
        ZStack(alignment: .bottom) {
            FloatingFireParticles()
                .frame(width: arcSize, height: arcSize / 2)
            
            ZStack {
                Circle()
                    .trim(from: 0, to: 0.5)
                    .stroke(AppTheme.accentOrange.opacity(0.15), style: StrokeStyle(lineWidth: 30, lineCap: .round))
                    .blur(radius: 20)
                    .rotationEffect(.degrees(180))
                
                Circle()
                    .trim(from: 0, to: 0.5)
                    .stroke(Color.gray.opacity(0.15), style: StrokeStyle(lineWidth: 24, lineCap: .round))
                    .rotationEffect(.degrees(180))
                
                Circle()
                    .trim(from: 0, to: CGFloat(loadProgress * 0.5))
                    .stroke(AppTheme.fireGradient, style: StrokeStyle(lineWidth: 24, lineCap: .round))
                    .rotationEffect(.degrees(180))
                    .shadow(color: AppTheme.accentRed.opacity(0.6), radius: firePulse ? 15 : 5)
            }
            .frame(width: arcSize, height: arcSize)
            .frame(height: arcSize / 2, alignment: .top)
            
            VStack(spacing: 2) {
                Text("🔥")
                    .font(.system(size: 40))
                    .shadow(color: AppTheme.accentOrange, radius: firePulse ? 20 : 5)
                    .scaleEffect(firePulse ? 1.15 : 1.0)
                
                Text("\(Int(steps))")
                    .font(.system(size: 60, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.white)
                    .shadow(color: .white.opacity(0.2), radius: 10)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                
                Text("ИЗ \(Int(goal)) ШАГОВ 🔥")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.gray)
                    .tracking(2.0)
            }
            .offset(y: 20)
        }
        .padding(.top, 40)
        .padding(.bottom, 25)
        .onAppear {
            withAnimation(.spring(response: 1.5, dampingFraction: 0.7)) { loadProgress = progress }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) { firePulse = true }
        }
    }
}

// MARK: - НОВЫЕ АККУРАТНЫЕ КАРТОЧКИ (ДОБАВЛЕНО ЗАЖАТИЕ / LONG PRESS)
struct StatsRowView: View {
    var steps: Double
    @Binding var activeTooltip: TooltipType?
    
    var body: some View {
        HStack(spacing: 12) {
            ColorfulStatCard(title: "Калории", value: "\(Int(steps * 0.045))", unit: "ккал", icon: "flame.fill", color: AppTheme.accentOrange, progress: 0.6) { activeTooltip = .calories }
            ColorfulStatCard(title: "Время", value: "45", unit: "мин", icon: "timer", color: AppTheme.accentCyan, progress: 0.4) { activeTooltip = .time }
            ColorfulStatCard(title: "Путь", value: String(format: "%.1f", steps * 0.00076), unit: "км", icon: "figure.walk", color: AppTheme.neonGreen, progress: 0.8) { activeTooltip = .distance }
        }
    }
}

struct ColorfulStatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    let progress: Double
    let onLongPress: () -> Void
    
    @State private var isHovered = false
    @State private var breathe = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle().fill(color.opacity(0.2)).frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(color)
                        .scaleEffect(breathe ? 1.1 : 1.0)
                }
                Spacer()
                Text("🔥").font(.caption).shadow(color: color, radius: 8)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value).font(.system(size: 24, weight: .bold, design: .rounded)).monospacedDigit().foregroundColor(.white).minimumScaleFactor(0.8)
                    Text(unit).font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundColor(.gray)
                }
                
                HStack {
                    Text(title).font(.system(size: 12, weight: .medium)).foregroundColor(color.opacity(0.8))
                    Spacer()
                }
                
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.gray.opacity(0.3)).frame(height: 3)
                    Capsule().fill(color)
                        .frame(width: CGFloat(progress) * 70, height: 3)
                        .shadow(color: color, radius: 3)
                }
                .padding(.top, 2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.glassGradient, lineWidth: 1.5))
        .shadow(color: color.opacity(isHovered ? 0.4 : 0.1), radius: 15)
        .scaleEffect(isHovered ? 0.93 : 1.0)
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) { breathe = true }
        }
        .onLongPressGesture(minimumDuration: 0.4) {
            triggerImpact(style: .heavy)
            onLongPress()
        } onPressingChanged: { inProgress in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { isHovered = inProgress }
        }
    }
}

// MARK: - ОСНОВНЫЕ UI КОМПОНЕНТЫ (ИДЕАЛЬНО РОВНЫЙ ТАБ БАР)
struct TopTabsView: View {
    @Binding var selectedTab: String
    let tabs = ["Home 🔥", "GPS 🔥", "AI Helper 🔥"]
    @Namespace private var tabAnimation
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.self) { t in
                Button(action: {
                    triggerImpact()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        selectedTab = t
                    }
                }) {
                    Text(t)
                        .font(.system(size: 13, weight: selectedTab == t ? .bold : .semibold, design: .rounded))
                        .foregroundColor(selectedTab == t ? .white : .gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            ZStack {
                                if selectedTab == t {
                                    Capsule()
                                        .fill(AppTheme.accentBlue)
                                        .shadow(color: AppTheme.accentBlue.opacity(0.6), radius: 12)
                                        .matchedGeometryEffect(id: "ActiveTab", in: tabAnimation)
                                }
                            }
                        )
                        .contentShape(Rectangle())
                }
            }
        }
        .padding(4)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(AppTheme.glassGradient, lineWidth: 1))
        .padding(.top)
    }
}

struct AISuggestionsTags: View {
    @Binding var searchText: String
    let tags = ["🔥 Fat burn?", "🔥 BPM info"]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 10) {
                ForEach(tags, id: \.self) { t in
                    Button(action: { triggerImpact(); searchText = t }) {
                        Text(t)
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial)
                            .overlay(Capsule().stroke(AppTheme.accentPurple.opacity(0.6), lineWidth: 1))
                            .clipShape(Capsule())
                            .shadow(color: AppTheme.accentPurple.opacity(0.3), radius: 5)
                    }
                }
            }
        }
    }
}

// MARK: - ПРЕМИУМ: АКТИВНЫЙ ГОЛОСОВОЙ ВВОД (ИСПРАВЛЕН TERNARY С ANYSHAPESTYLE)
struct AIHelperSearchBar: View {
    @Binding var text: String
    @State private var pIndex = 0
    let pl = ["Ask AI 🔥...", "Marathon plan 🔥..."]
    
    @State private var isListening = false
    @State private var micPulse = false
    
    var body: some View {
        HStack {
            Image(systemName: "sparkles")
                .foregroundColor(isListening ? AppTheme.neonGreen : AppTheme.accentRed)
                .modifier(ShimmerModifier())
            
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    if isListening {
                        Text("Слушаю (задавайте вопросы) 🔥...")
                            .foregroundColor(AppTheme.neonGreen)
                            .shadow(color: AppTheme.neonGreen.opacity(0.8), radius: 5)
                            .transition(.opacity)
                    } else {
                        Text(pl[pIndex])
                            .foregroundColor(.gray)
                            .transition(.opacity.combined(with: .slide))
                            .id(pIndex)
                    }
                }
                TextField("", text: $text)
                    .foregroundColor(.white)
                    .disabled(isListening)
            }
            
            if !text.isEmpty && !isListening {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                }
            }
            Spacer()
            
            Button(action: {
                triggerImpact(style: .heavy)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    isListening.toggle()
                }
            }) {
                ZStack {
                    if isListening {
                        Circle()
                            .stroke(AppTheme.neonGreen, lineWidth: 2)
                            .frame(width: 40, height: 40)
                            .scaleEffect(micPulse ? 1.8 : 1.0)
                            .opacity(micPulse ? 0 : 1)
                            .onAppear {
                                withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                                    micPulse = true
                                }
                            }
                    }
                    
                    Image(systemName: isListening ? "waveform" : "mic.fill")
                        .foregroundColor(isListening ? .black : .white)
                        .padding(10)
                        .background(
                            Circle()
                                .fill(isListening ? AppTheme.neonGreen : AppTheme.accentRed)
                                .shadow(color: isListening ? AppTheme.neonGreen : AppTheme.accentRed.opacity(0.8), radius: 10)
                        )
                        .scaleEffect(isListening ? 1.1 : 1.0)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        // ФИКС ОШИБКИ СОВМЕСТИМОСТИ ТИПОВ:
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .stroke(isListening ? AnyShapeStyle(AppTheme.neonGreen.opacity(0.5)) : AnyShapeStyle(AppTheme.glassGradient), lineWidth: 1.5)
        )
        .cornerRadius(30)
        .shadow(color: isListening ? AppTheme.neonGreen.opacity(0.2) : .black.opacity(0.3), radius: 15, y: 10)
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                if !isListening {
                    withAnimation(.spring()) { pIndex = (pIndex + 1) % pl.count }
                }
            }
        }
    }
}

struct ActionGrid: View {
    @Binding var activeSheet: ActiveSheet?
    var body: some View {
        HStack(spacing: 15) {
            ActionButton(icon: "magnifyingglass", title: "Goal 🔥", color: AppTheme.accentPurple) { triggerImpact(); activeSheet = .goal }
            ActionButton(icon: "map.fill", title: "Route 🔥", color: AppTheme.accentBlue) { triggerImpact(); activeSheet = .map }
            ActionButton(icon: "figure.run", title: "Events 🔥", color: AppTheme.accentRed) { triggerImpact(); activeSheet = .marathon }
            
            Button(action: { triggerImpact(style: .heavy); activeSheet = .cardioPro }) {
                VStack(spacing: 10) {
                    Image(systemName: "flame.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 55, height: 55)
                        .background(LinearGradient(colors: [.orange, .red], startPoint: .top, endPoint: .bottom))
                        .clipShape(Circle())
                        .shadow(color: .orange.opacity(0.8), radius: 15)
                    Text("PRO 🔥")
                        .font(.caption2.bold())
                        .foregroundColor(AppTheme.gold)
                }
            }
            .buttonStyle(BouncyButton())
        }
    }
}

struct ActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 55, height: 55)
                    .background(color)
                    .clipShape(Circle())
                    .shadow(color: color.opacity(0.6), radius: 12)
                Text(title)
                    .font(.caption2.bold())
                    .foregroundColor(.gray)
            }
        }
        .buttonStyle(BouncyButton())
    }
}

struct HorizontalHealthWidgets: View {
    @Binding var activeSheet: ActiveSheet?
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Log Health Data 🔥")
                .font(.title3.bold())
                .foregroundColor(.white)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 15) {
                    WidgetCard(icon: "heart.fill", title: "Blood 🔥", sub: "132 BPM", color: AppTheme.accentRed) { activeSheet = .blood }
                    WidgetCard(icon: "moon.zzz.fill", title: "Sleep 🔥", sub: "7h 12m", color: AppTheme.accentPurple) { activeSheet = .sleep }
                    WidgetCard(icon: "drop.fill", title: "Water 🔥", sub: "1.2 L", color: AppTheme.accentCyan) { activeSheet = .water }
                    WidgetCard(icon: "battery.100.bolt", title: "Recover 🔥", sub: "98% Ready", color: AppTheme.neonGreen) { activeSheet = .recovery }
                }
                .padding(.horizontal)
            }
            .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                content.scaleEffect(phase.isIdentity ? 1 : 0.9).opacity(phase.isIdentity ? 1 : 0.7)
            }
        }
        .padding(.horizontal, -16)
    }
}

struct WidgetCard: View {
    let icon: String
    let title: String
    let sub: String
    let color: Color
    let action: () -> Void
    var body: some View {
        Button(action: { triggerImpact(); action() }) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(color)
                    .shadow(color: color.opacity(0.8), radius: 8)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline.bold()).foregroundColor(.white)
                    Text(sub).font(.caption.weight(.semibold)).foregroundColor(.gray)
                }
            }
            .padding(16)
            .frame(width: 145, alignment: .leading)
            .background(.ultraThinMaterial)
            .cornerRadius(24)
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(AppTheme.glassGradient, lineWidth: 1.5))
            .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
        }
        .buttonStyle(BouncyButton())
    }
}

struct BouncyButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: configuration.isPressed)
            .brightness(configuration.isPressed ? 0.2 : 0)
    }
}

struct AnimatedBackgroundView: View {
    var isActive: Bool
    @State private var a = false
    var body: some View {
        ZStack {
            AppTheme.bgDark.ignoresSafeArea()
            Color.white.opacity(0.01).blendMode(.overlay).ignoresSafeArea()
            
            Circle().fill(AppTheme.accentRed.opacity(0.15)).blur(radius: 60).frame(width: 300).offset(x: a ? 100 : -100, y: a ? -150 : 100)
            Circle().fill(AppTheme.accentBlue.opacity(0.2)).blur(radius: 80).frame(width: 400).offset(x: a ? -100 : 150, y: a ? 200 : -50)
            Circle().fill(AppTheme.accentPurple.opacity(0.15)).blur(radius: 100).frame(width: 250).offset(x: a ? 50 : -50, y: a ? 50 : -200)
        }
        .drawingGroup()
        .onAppear { if isActive { withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) { a.toggle() } } }
        .onChange(of: isActive) { old, newActive in
            if newActive { withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) { a.toggle() } }
        }
    }
}

struct MeshGradientBackground: View {
    var body: some View {
        ZStack {
            AppTheme.bgDark.ignoresSafeArea()
            LinearGradient(colors: [AppTheme.accentPurple.opacity(0.15), .clear, AppTheme.accentBlue.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
        }.allowsHitTesting(false)
    }
}

struct LiveStatusPill: View {
    var isGpsActive: Bool
    @State private var p = false
    var body: some View {
        HStack {
            Circle()
                .fill(isGpsActive ? AppTheme.neonGreen : .red)
                .frame(width: 8, height: 8)
                .shadow(color: isGpsActive ? AppTheme.neonGreen : .red, radius: p ? 8 : 0)
                .opacity(p ? 1.0 : 0.4)
            Text(isGpsActive ? "GPS LINKED 🔥" : "GPS SEARCHING 🔥")
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundColor(isGpsActive ? AppTheme.neonGreen : .red)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.15)))
        .shadow(color: .black.opacity(0.2), radius: 5)
        .onAppear { withAnimation(.easeInOut(duration: 1).repeatForever()) { p = true } }
    }
}

struct ScrollParallaxModifier: ViewModifier {
    func body(content: Content) -> some View {
        GeometryReader { geo in
            content.rotation3DEffect(.degrees(Double(geo.frame(in: .global).minY - 300) / -60), axis: (x: 1, y: 0, z: 0))
        }.frame(height: 110)
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1
    func body(content: Content) -> some View {
        content.overlay(
            LinearGradient(colors: [.clear, .white.opacity(0.6), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                .offset(x: phase * 100)
                .mask(content)
        )
        .onAppear { withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) { phase = 1 } }
    }
}

// MARK: - ШИТЫ (КАРТЫ И ОСТАЛЬНОЕ)
struct RealMapRouteSheetView: View {
    @ObservedObject var locManager: LocationManager
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    
    var body: some View {
        ZStack {
            Map(position: $position) {
                UserAnnotation()
            }
            .mapStyle(.standard(elevation: .realistic))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapPitchToggle()
            }
            .ignoresSafeArea()
            .colorScheme(.dark)
            
            VStack {
                HStack {
                    VStack(alignment: .leading) {
                        Text("LIVE GPS LINK 🔥").font(.caption.bold()).foregroundColor(AppTheme.neonGreen)
                        Text("Tracking active 🔥").font(.system(size: 12)).foregroundColor(.gray)
                    }
                    Spacer()
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.glassGradient))
                .padding()
                
                Spacer()
            }
        }
    }
}

struct MinskMapRouteSheetView: View {
    @State private var d = false; @State private var rot: Double = 0
    var body: some View {
        ZStack {
            Color(red: 0.10, green: 0.10, blue: 0.12).ignoresSafeArea()
            ZStack {
                Circle().stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 4, dash: [10, 15])).frame(width: 340, height: 340)
                Path { p in p.move(to: CGPoint(x: 40, y: 150)); p.addLine(to: CGPoint(x: 350, y: 650)) }.stroke(Color.white.opacity(0.1), lineWidth: 8)
                Path { p in p.move(to: CGPoint(x: 100, y: 100)); p.addCurve(to: CGPoint(x: 200, y: 400), control1: CGPoint(x: 50, y: 250), control2: CGPoint(x: 250, y: 300)); p.addCurve(to: CGPoint(x: 250, y: 700), control1: CGPoint(x: 150, y: 500), control2: CGPoint(x: 350, y: 600)) }.stroke(Color.blue.opacity(0.3), lineWidth: 12)
                Path { p in p.move(to: CGPoint(x: 180, y: 350)); p.addCurve(to: CGPoint(x: 240, y: 420), control1: CGPoint(x: 200, y: 360), control2: CGPoint(x: 220, y: 400)); p.addLine(to: CGPoint(x: 270, y: 450)) }.trim(from: 0, to: d ? 1 : 0).stroke(AppTheme.accentBlue, style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)).shadow(color: AppTheme.accentBlue, radius: 10).onAppear { withAnimation(.easeInOut(duration: 3.0)) { d = true } }
            }.rotationEffect(.degrees(rot)).onAppear { withAnimation(.linear(duration: 40).repeatForever(autoreverses: true)) { rot = 15 } }.drawingGroup()
            VStack { HStack { VStack(alignment: .leading) { Text("📍 Minsk (Simulated) 🔥").font(.title2.bold()).foregroundColor(.white); Text("Enable GPS for real map 🔥").font(.caption).foregroundColor(.red) }; Spacer() }.padding().background(.ultraThinMaterial).cornerRadius(20).padding(); Spacer() }
        }
    }
}

struct GoalSheetView: View {
    @State private var goalText = ""
    let popGoals = ["10,000 steps today 🔥", "Walk 5 kilometers 🔥", "Burn 600 calories 🔥"]
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.bgDark.ignoresSafeArea()
                MeshGradientBackground()
                VStack(spacing: 25) {
                    ZStack {
                        Circle().stroke(Color.gray.opacity(0.2), lineWidth: 10).frame(width: 80, height: 80)
                        Circle().trim(from: 0, to: 0.65).stroke(AppTheme.accentPurple, style: StrokeStyle(lineWidth: 10, lineCap: .round)).rotationEffect(.degrees(-90)).frame(width: 80, height: 80)
                        Text("65%").font(.headline.bold()).foregroundColor(.white)
                    }.padding(.top).drawingGroup()
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundColor(.gray)
                        TextField("Enter custom goal 🔥...", text: $goalText).foregroundColor(.white)
                        if !goalText.isEmpty { Button(action: { goalText = "" }) { Image(systemName: "xmark.circle.fill").foregroundColor(.gray) } }
                    }.padding().background(.ultraThinMaterial).cornerRadius(20).overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.accentPurple.opacity(0.3))).padding(.horizontal)
                    VStack(alignment: .leading, spacing: 15) {
                        Text("AI Suggested Goals 🔥").font(.headline).foregroundColor(.gray).padding(.horizontal)
                        ForEach(popGoals, id: \.self) { goal in
                            Button(action: { triggerNotification(type: .success); goalText = goal }) {
                                HStack { Text("🔥").font(.title3); Text(goal).foregroundColor(.white).font(.body.weight(.medium)); Spacer(); Image(systemName: "checkmark.circle.fill").foregroundColor(AppTheme.accentBlue) }.padding().background(.ultraThinMaterial).cornerRadius(15).padding(.horizontal)
                            }
                        }
                    }
                    Spacer()
                }
            }.navigationTitle("Set Target 🔥").navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct MarathonSheetView: View {
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.bgDark.ignoresSafeArea()
                MeshGradientBackground()
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 20) {
                        MarathonCard(city: "Tokyo Marathon 🔥", dist: "42.2 km", flag: "🔥", price: "$150", slots: "12 left", color: .pink)
                        MarathonCard(city: "London Marathon 🔥", dist: "21.1 km", flag: "🔥", price: "$120", slots: "Open", color: .blue)
                        MarathonCard(city: "Berlin Dash 🔥", dist: "10.0 km", flag: "🔥", price: "$50", slots: "4 left", color: .orange)
                    }.padding()
                }
            }.navigationTitle("Global Events 🔥")
        }
    }
}

struct MarathonCard: View {
    let city, dist, flag, price, slots: String; let color: Color
    @State private var isExpanded = false; @State private var isRegistered = false
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(flag).font(.largeTitle).shadow(color: color, radius: 10)
                VStack(alignment: .leading) { Text(city).font(.title3.bold()).foregroundColor(.white); Text("\(dist) • \(price)").foregroundColor(.white.opacity(0.7)).font(.subheadline) }
                Spacer()
                VStack { Text(slots).font(.caption2.bold()).padding(5).background(slots.contains("left") ? Color.red : AppTheme.neonGreen).cornerRadius(8).foregroundColor(.white); Image(systemName: isExpanded ? "chevron.up" : "chevron.down").foregroundColor(.white).padding(.top, 5) }
            }.padding().background(color.opacity(0.8)).onTapGesture { triggerImpact(); withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { isExpanded.toggle() } }
            if isExpanded {
                VStack(spacing: 15) {
                    HStack { Image(systemName: "map.fill").foregroundColor(color); Text("Elevation: 140m Gain 🔥").foregroundColor(.white).font(.subheadline); Spacer() }
                    Button(action: { triggerNotification(type: .success); withAnimation(.spring()) { isRegistered = true } }) {
                        Text(isRegistered ? "Вы записаны 🔥" : "Записаться на марафон 🔥").font(.headline.bold()).foregroundColor(.white).frame(maxWidth: .infinity).padding().background(isRegistered ? AppTheme.neonGreen : AppTheme.accentBlue).cornerRadius(15).shadow(color: (isRegistered ? AppTheme.neonGreen : AppTheme.accentBlue).opacity(0.5), radius: 10)
                    }.disabled(isRegistered)
                }.padding().background(Color.white.opacity(0.05))
            }
        }.clipShape(RoundedRectangle(cornerRadius: 20)).shadow(color: color.opacity(0.3), radius: 10, y: 5)
    }
}

struct BloodHealthSheetView: View {
    @State private var p = false
    var body: some View {
        ZStack {
            AppTheme.bgDark.ignoresSafeArea()
            MeshGradientBackground()
            VStack(spacing: 30) {
                Text("Heart Sync 🔥").font(.largeTitle.bold()).foregroundColor(.white).padding(.top)
                ZStack {
                    ForEach(0..<3, id: \.self) { i in Circle().stroke(AppTheme.accentRed.opacity(0.4), lineWidth: 3).frame(width: 140, height: 140).scaleEffect(p ? 2.5 : 1.0).opacity(p ? 0 : 1).animation(.easeOut(duration: 1.2).repeatForever().delay(Double(i) * 0.3), value: p) }
                    Circle().fill(AppTheme.accentRed).frame(width: 150, height: 150).shadow(color: .red, radius: p ? 30 : 10)
                    VStack { Text("132").font(.system(size: 55, weight: .black)).foregroundColor(.white); Text("BPM").font(.headline).foregroundColor(.white.opacity(0.8)); Image(systemName: "waveform.path.ecg").foregroundColor(.white).font(.title3) }
                }.onAppear { p = true }.drawingGroup()
                VStack(alignment: .leading) { Text("Current Zone: Cardio 🔥").font(.caption).foregroundColor(.gray); HStack(spacing: 4) { ForEach(0..<5, id: \.self) { i in RoundedRectangle(cornerRadius: 2).fill(i < 3 ? AppTheme.accentRed : Color.gray.opacity(0.3)).frame(height: 8) } } }.padding(.horizontal, 40)
                HStack {
                    VStack { Text("Pressure 🔥").foregroundColor(.gray); Text("120/80").font(.title2.bold()).foregroundColor(.white) }
                    Spacer()
                    VStack { Text("O2 Sat 🔥").foregroundColor(.gray); Text("98%").font(.title2.bold()).foregroundColor(AppTheme.neonGreen).shadow(color: AppTheme.neonGreen, radius: 5) }
                }.padding().background(.ultraThinMaterial).cornerRadius(20).padding(.horizontal)
                VStack(alignment: .leading, spacing: 10) {
                    HStack { Image(systemName: "brain").foregroundColor(AppTheme.accentPurple); Text("AI Heart Coach 🔥").font(.headline.bold()).foregroundColor(.white) }
                    Text("Your heart rate is in the **Fat Burn Zone**. Maintain this pace for 20 more minutes. **Do not stop**.").font(.subheadline).foregroundColor(.white)
                }.padding().background(.ultraThinMaterial).overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.accentPurple.opacity(0.5))).cornerRadius(20).padding(.horizontal)
                Spacer()
            }
        }
    }
}

struct HydrationSheetView: View {
    @State private var water: CGFloat = 1200; let goal: CGFloat = 2500; @State private var ripple = false
    var body: some View {
        ZStack {
            AppTheme.bgDark.ignoresSafeArea()
            MeshGradientBackground()
            VStack(spacing: 40) {
                Text("Hydration 🔥").font(.largeTitle.bold()).foregroundColor(.white).padding(.top)
                ZStack {
                    Circle().fill(AppTheme.accentCyan.opacity(0.1)).frame(width: 220, height: 220).scaleEffect(ripple ? 1.1 : 1.0).animation(.easeInOut(duration: 2).repeatForever(), value: ripple)
                    Circle().stroke(Color.gray.opacity(0.2), lineWidth: 20).frame(width: 200, height: 200)
                    Circle().trim(from: 0, to: water / goal).stroke(AppTheme.accentCyan, style: StrokeStyle(lineWidth: 20, lineCap: .round)).rotationEffect(.degrees(-90)).frame(width: 200, height: 200).shadow(color: AppTheme.accentCyan, radius: 15)
                    VStack { Image(systemName: "drop.fill").font(.largeTitle).foregroundColor(AppTheme.accentCyan); Text("\(Int(water))").font(.system(size: 40, weight: .black)).foregroundColor(.white); Text("ml / \(Int(goal)) ml").foregroundColor(.gray) }
                }.onAppear { ripple = true }.drawingGroup()
                Button(action: { triggerNotification(type: .success); if water < goal { withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { water += 250 } } }) {
                    HStack { Image(systemName: "plus"); Text("Add 250 ml 🔥") }.font(.title3.bold()).foregroundColor(.white).padding().frame(width: 200).background(AppTheme.accentCyan).cornerRadius(20).shadow(color: AppTheme.accentCyan.opacity(0.5), radius: 10)
                }
                Spacer()
            }
        }
    }
}

struct SleepAISheetView: View {
    var body: some View {
        ZStack {
            AppTheme.bgDark.ignoresSafeArea()
            MeshGradientBackground()
            VStack(spacing: 30) {
                Image(systemName: "moon.stars.fill").font(.system(size: 60)).foregroundColor(.yellow).shadow(color: .yellow, radius: 20).padding(.top, 40)
                Text("Sleep Analysis 🔥").font(.largeTitle.bold()).foregroundColor(.white)
                VStack(spacing: 20) {
                    SleepBar(title: "Deep Sleep 🔥", duration: "2h 10m", color: AppTheme.accentPurple, width: 200)
                    SleepBar(title: "REM Sleep 🔥", duration: "1h 45m", color: AppTheme.accentBlue, width: 150)
                    SleepBar(title: "Light Sleep 🔥", duration: "3h 17m", color: AppTheme.accentCyan, width: 250)
                }
                VStack(alignment: .leading, spacing: 10) { Text("AI Coach 🔥").font(.headline.bold()).foregroundColor(.yellow); Text("Your Deep Sleep is excellent today! This ensures maximum muscle recovery.").font(.body).foregroundColor(.white.opacity(0.8)) }.padding().background(.ultraThinMaterial).overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.yellow.opacity(0.3))).cornerRadius(15).padding()
                Spacer()
            }
        }
    }
}
struct SleepBar: View { let title, duration: String; let color: Color; let width: CGFloat; var body: some View { VStack(alignment: .leading) { HStack { Text(title).foregroundColor(.white); Spacer(); Text(duration).foregroundColor(.gray) }; ZStack(alignment: .leading) { Capsule().fill(Color.gray.opacity(0.2)).frame(height: 10); Capsule().fill(color).frame(width: width, height: 10).shadow(color: color, radius: 5) } }.padding(.horizontal) } }

struct RecoverySheetView: View {
    @State private var pulse = false
    var body: some View {
        ZStack {
            AppTheme.bgDark.ignoresSafeArea()
            MeshGradientBackground()
            VStack(spacing: 40) {
                Text("Recovery 🔥").font(.largeTitle.bold()).foregroundColor(.white).padding(.top)
                ZStack {
                    Circle().stroke(AppTheme.neonGreen.opacity(0.2), lineWidth: 10).frame(width: 180, height: 180)
                    Circle().trim(from: 0, to: 0.98).stroke(AppTheme.neonGreen, style: StrokeStyle(lineWidth: 15, lineCap: .round)).rotationEffect(.degrees(-90)).frame(width: 180, height: 180).shadow(color: AppTheme.neonGreen, radius: pulse ? 30 : 5)
                    VStack { Image(systemName: "battery.100.bolt").font(.largeTitle).foregroundColor(AppTheme.neonGreen); Text("98%").font(.system(size: 50, weight: .black)).foregroundColor(.white) }
                }.onAppear { withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) { pulse = true } }.drawingGroup()
                Text("Ready to crush a Marathon! 🔥").font(.title3.bold()).foregroundColor(AppTheme.neonGreen).shadow(color: AppTheme.neonGreen, radius: 5)
                Spacer()
            }
        }
    }
}

struct CardioProSheetView: View {
    struct W: Identifiable { let id = UUID(); let t, d, e: String; let c1, c2: Color; let diff: Int }
    let w = [ W(t: "HIIT Hellfire 🔥", d: "30s sprint / 15s rest.", e: "🔥", c1: .red, c2: .orange, diff: 5), W(t: "Shadow Boxer 🔥", d: "Punching combos.", e: "🔥", c1: .purple, c2: .blue, diff: 3), W(t: "Everest Stairs 🔥", d: "Level 15 stairmaster.", e: "🔥", c1: .green, c2: .black, diff: 4) ]
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.bgDark.ignoresSafeArea()
                MeshGradientBackground()
                ScrollView {
                    LazyVStack(spacing: 20) {
                        HStack { Image(systemName: "crown.fill").foregroundColor(AppTheme.gold); Text("Elite Cardio 🔥").font(.title2.bold()).foregroundColor(.white) }.padding(.top)
                        ForEach(w) { item in
                            HStack(spacing: 15) {
                                ZStack { LinearGradient(colors: [item.c1, item.c2], startPoint: .topLeading, endPoint: .bottomTrailing); Text(item.e).font(.system(size: 40)).shadow(color: .white, radius: 5) }.frame(width: 80, height: 80).cornerRadius(15).shadow(color: item.c1.opacity(0.5), radius: 8)
                                VStack(alignment: .leading) { Text(item.t).font(.headline.bold()).foregroundColor(.white); Text(item.d).font(.caption).foregroundColor(.gray).lineLimit(2); HStack(spacing: 4) { ForEach(0..<5, id: \.self) { i in Circle().fill(i < item.diff ? AppTheme.accentRed : .gray.opacity(0.3)).frame(width: 6, height: 6) } } }
                                Spacer(); Image(systemName: "lock.fill").foregroundColor(.gray)
                            }.padding().background(.ultraThinMaterial).cornerRadius(20).overlay(RoundedRectangle(cornerRadius: 20).stroke(item.c1.opacity(0.3))).onTapGesture { triggerImpact(style: .rigid) }.contentShape(Rectangle())
                        }
                    }.padding()
                }
            }.navigationBarTitleDisplayMode(.inline)
        }
    }
}
