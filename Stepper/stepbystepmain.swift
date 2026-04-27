import SwiftUI
import MapKit
import CoreLocation
import Combine
import Speech  // ДОБАВИТЬ ЭТУ СТРОКУ
import AVFoundation // ДОБАВИТЬ ЭТУ СТРОКУ

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
    
    // ДОБАВИТЬ ЭТУ СТРОКУ:
    static let epicGradient = LinearGradient(colors: [gold, accentOrange, accentRed], startPoint: .bottom, endPoint: .top)
}
enum ActiveSheet: String, Identifiable {
    case goal, map, marathon, blood, cardioPro, sleep, recovery
    var id: String { rawValue }
}

// ПРЕМИУМ: Типы облачков для статистики
enum TooltipType {
    case calories, time, distance
}
class SpeechManager: ObservableObject {
    @Published var recognizedText = ""
    @Published var isRecording = false
    
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ru-RU"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    func startRecording() {
        // Просим разрешение у пользователя (сработает 1 раз)
        SFSpeechRecognizer.requestAuthorization { status in
            if status == .authorized {
                DispatchQueue.main.async { self.setupRecording() }
            }
        }
    }

    private func setupRecording() {
        if audioEngine.isRunning { stopRecording(); return }
        
        recognizedText = ""
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try? audioEngine.start()
        isRecording = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                DispatchQueue.main.async { self.recognizedText = result.bestTranscription.formattedString }
            }
            if error != nil || result?.isFinal == true {
                self.stopRecording()
            }
        }
    }

    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false)
    }
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


// MARK: - MAIN SCREEN
struct MainScreenView: View {
    @Environment(\.scenePhase) var scenePhase
    @Environment(HealthKitManager.self) private var health
    @StateObject private var locManager = LocationManager()
    @StateObject private var debouncer = SearchDebouncer()

    /// Live step total from HealthKit. Falls back to 0 when the user has
    /// not granted Health permission yet — the previous hardcoded value
    /// (6432) was placeholder data and would have failed App Review.
    private var steps: Double { health.todaySteps ?? 0 }
    @AppStorage("dailyStepGoal") private var goal: Double = 10000
    @State private var activeSheet: ActiveSheet? = nil
    @State private var isAppActive = true
    @State private var activeTooltip: TooltipType? = nil
    
    // Новые стейты для ИИ Чата
    @State private var showAIChat = false
    @State private var currentAIPrompt = ""
    
    var body: some View {
        ZStack {
            AnimatedBackgroundView(isActive: isAppActive)
            
            VStack(spacing: 0) {
                LiveStatusPill(isGpsActive: locManager.isAuthorized)
                
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 25) {
                        // Верхний бар (TopTabsView) удален!
                        
                        SemiCircleStepView(steps: steps, goal: goal)
                            .scrollTransition { content, phase in
                                content.scaleEffect(phase.isIdentity ? 1 : 0.9).opacity(phase.isIdentity ? 1 : 0.5)
                            }
                        
                        StatsRowView(steps: steps, activeTooltip: $activeTooltip)
                            .modifier(ScrollParallaxModifier())
                            .scrollTransition { content, phase in
                                content.offset(y: phase.isIdentity ? 0 : 20).opacity(phase.isIdentity ? 1 : 0)
                            }
                        
                        VStack(spacing: 12) {
                            AISuggestionsTags(searchText: $debouncer.searchText)
                            // Передаем действие при отправке сообщения
                            AIHelperSearchBar(text: $debouncer.searchText) {
                                currentAIPrompt = debouncer.searchText
                                debouncer.searchText = "" // очищаем поле
                                showAIChat = true         // открываем чат
                            }
                        }
                        .scrollTransition { content, phase in content.scaleEffect(phase.isIdentity ? 1 : 0.95) }
                        
                        ActionGrid(activeSheet: $activeSheet)
                        
                        HorizontalHealthWidgets(activeSheet: $activeSheet)
                        
                        Spacer().frame(height: 100) // Отступ под прозрачный TabBar
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
            }
            
            if let tooltip = activeTooltip {
                TooltipCloudView(tooltip: tooltip, steps: steps, onClose: {
                    triggerImpact(style: .light)
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        activeTooltip = nil
                    }
                })
            }
        }
        .task {
            locManager.requestAuth()
            await health.requestAuthorization()
        }
        .onChange(of: scenePhase) { _, newPhase in
            isAppActive = (newPhase == .active)
            if newPhase == .active {
                Task { await health.refreshAll() }
            }
        }
        .sheet(item: $activeSheet) { sheet in SheetRouter(sheet: sheet, locManager: locManager) }
        // Открываем чат на весь экран
        .fullScreenCover(isPresented: $showAIChat) {
            AIChatView(initialMessage: currentAIPrompt)
        }
    }
}

// MARK: - ОБНОВЛЕННЫЕ КОМПОНЕНТЫ (БЕЗ ЛИШНИХ ОГНЕЙ)

struct SemiCircleStepView: View {
    var steps: Double; var goal: Double
    @State private var firePulse = false; @State private var loadProgress = 0.0
    let arcSize: CGFloat = 260
    var body: some View {
        let progress = min(steps / goal, 1.0)
        ZStack(alignment: .bottom) {
            FloatingFireParticles().frame(width: arcSize, height: arcSize / 2)
            ZStack {
                Circle().trim(from: 0, to: 0.5).stroke(AppTheme.accentOrange.opacity(0.15), style: StrokeStyle(lineWidth: 30, lineCap: .round)).blur(radius: 20).rotationEffect(.degrees(180))
                Circle().trim(from: 0, to: 0.5).stroke(Color.gray.opacity(0.15), style: StrokeStyle(lineWidth: 24, lineCap: .round)).rotationEffect(.degrees(180))
                Circle().trim(from: 0, to: CGFloat(loadProgress * 0.5)).stroke(AppTheme.fireGradient, style: StrokeStyle(lineWidth: 24, lineCap: .round)).rotationEffect(.degrees(180)).shadow(color: AppTheme.accentRed.opacity(0.6), radius: firePulse ? 15 : 5)
            }.frame(width: arcSize, height: arcSize).frame(height: arcSize / 2, alignment: .top)
            
            VStack(spacing: 2) {
                // Оставляем ТОЛЬКО этот большой огонек
                Text("🔥").font(.system(size: 40)).shadow(color: AppTheme.accentOrange, radius: firePulse ? 20 : 5).scaleEffect(firePulse ? 1.15 : 1.0)
                Text("\(Int(steps))").font(.system(size: 60, weight: .black, design: .rounded)).monospacedDigit().foregroundColor(.white).shadow(color: .white.opacity(0.2), radius: 10).minimumScaleFactor(0.5).lineLimit(1)
                Text("ИЗ \(Int(goal)) ШАГОВ").font(.system(size: 13, weight: .bold, design: .rounded)).foregroundColor(.gray).tracking(2.0)
            }.offset(y: 20)
        }.padding(.top, 20).padding(.bottom, 25).onAppear {
            withAnimation(.spring(response: 1.5, dampingFraction: 0.7)) { loadProgress = progress }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) { firePulse = true }
        }
    }
}

struct StatsRowView: View {
    var steps: Double; @Binding var activeTooltip: TooltipType?
    var body: some View {
        HStack(spacing: 12) {
            ColorfulStatCard(title: "Калории", value: "\(Int(steps * 0.045))", unit: "ккал", icon: "flame.fill", color: AppTheme.accentOrange, progress: 0.6) { activeTooltip = .calories }
            ColorfulStatCard(title: "Время", value: "45", unit: "мин", icon: "timer", color: AppTheme.accentCyan, progress: 0.4) { activeTooltip = .time }
            ColorfulStatCard(title: "Путь", value: String(format: "%.1f", steps * 0.00076), unit: "км", icon: "figure.walk", color: AppTheme.neonGreen, progress: 0.8) { activeTooltip = .distance }
        }
    }
}

struct ColorfulStatCard: View {
    let title: String; let value: String; let unit: String; let icon: String; let color: Color; let progress: Double; let onLongPress: () -> Void
    @State private var isHovered = false; @State private var breathe = false
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle().fill(color.opacity(0.2)).frame(width: 32, height: 32)
                    Image(systemName: icon).font(.system(size: 14, weight: .bold)).foregroundColor(color).scaleEffect(breathe ? 1.1 : 1.0)
                }
                Spacer() // Убрали огонек из правого угла
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value).font(.system(size: 24, weight: .bold, design: .rounded)).monospacedDigit().foregroundColor(.white).minimumScaleFactor(0.8)
                    Text(unit).font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundColor(.gray)
                }
                HStack { Text(title).font(.system(size: 12, weight: .medium)).foregroundColor(color.opacity(0.8)); Spacer() }
                ZStack(alignment: .leading) { Capsule().fill(Color.gray.opacity(0.3)).frame(height: 3); Capsule().fill(color).frame(width: CGFloat(progress) * 70, height: 3).shadow(color: color, radius: 3) }.padding(.top, 2)
            }
        }.padding(14).frame(maxWidth: .infinity).background(.ultraThinMaterial).cornerRadius(20).overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.glassGradient, lineWidth: 1.5))
        .shadow(color: color.opacity(isHovered ? 0.4 : 0.1), radius: 15).scaleEffect(isHovered ? 0.93 : 1.0).onAppear { withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) { breathe = true } }.onLongPressGesture(minimumDuration: 0.4) { triggerImpact(style: .heavy); onLongPress() } onPressingChanged: { inProgress in withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { isHovered = inProgress } }
    }
}

struct AISuggestionsTags: View {
    @Binding var searchText: String
    let tags = ["Fat burn?", "BPM info"] // Убрали огоньки
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 10) {
                ForEach(tags, id: \.self) { t in Button(action: { triggerImpact(); searchText = t }) { Text(t).font(.caption.bold()).foregroundColor(.white).padding(.horizontal, 16).padding(.vertical, 8).background(.ultraThinMaterial).overlay(Capsule().stroke(AppTheme.accentPurple.opacity(0.6), lineWidth: 1)).clipShape(Capsule()).shadow(color: AppTheme.accentPurple.opacity(0.3), radius: 5) } }
            }
        }
    }
}

struct AIHelperSearchBar: View {
    @Binding var text: String
    var onSubmit: () -> Void
    @State private var pIndex = 0
    let pl = ["Ask AI...", "Marathon plan..."]
    
    // Подключаем микрофон
    @StateObject private var speech = SpeechManager()
    @State private var micPulse = false
    
    var body: some View {
        HStack {
            Image(systemName: "sparkles").foregroundColor(speech.isRecording ? AppTheme.neonGreen : AppTheme.accentRed).modifier(ShimmerModifier())
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    if speech.isRecording { Text("Слушаю...").foregroundColor(AppTheme.neonGreen).shadow(color: AppTheme.neonGreen.opacity(0.8), radius: 5).transition(.opacity) }
                    else { Text(pl[pIndex]).foregroundColor(.gray).transition(.opacity.combined(with: .slide)).id(pIndex) }
                }
                TextField("", text: $text)
                    .foregroundColor(.white)
                    .submitLabel(.send)
                    .onSubmit {
                        if speech.isRecording { speech.stopRecording() }
                        if !text.isEmpty { onSubmit() }
                    }
            }
            if !text.isEmpty && !speech.isRecording {
                Button(action: { onSubmit() }) { Image(systemName: "arrow.up.circle.fill").font(.title2).foregroundColor(AppTheme.accentBlue) }
            }
            Spacer()
            
            // Кнопка микрофона
            Button(action: {
                triggerImpact(style: .heavy)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    if speech.isRecording {
                        speech.stopRecording()
                        if !text.isEmpty { onSubmit() } // Отправляем сразу после конца записи
                    } else {
                        text = ""
                        speech.startRecording()
                    }
                }
            }) {
                ZStack {
                    if speech.isRecording { Circle().stroke(AppTheme.neonGreen, lineWidth: 2).frame(width: 40, height: 40).scaleEffect(micPulse ? 1.8 : 1.0).opacity(micPulse ? 0 : 1).onAppear { withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) { micPulse = true } } }
                    Image(systemName: speech.isRecording ? "waveform" : "mic.fill").foregroundColor(speech.isRecording ? .black : .white).padding(10).background(Circle().fill(speech.isRecording ? AppTheme.neonGreen : AppTheme.accentRed).shadow(color: speech.isRecording ? AppTheme.neonGreen : AppTheme.accentRed.opacity(0.8), radius: 10)).scaleEffect(speech.isRecording ? 1.1 : 1.0)
                }
            }
        }.padding(.horizontal, 20).padding(.vertical, 12).background(.ultraThinMaterial).overlay(RoundedRectangle(cornerRadius: 30).stroke(speech.isRecording ? AnyShapeStyle(AppTheme.neonGreen.opacity(0.5)) : AnyShapeStyle(AppTheme.glassGradient), lineWidth: 1.5)).cornerRadius(30).shadow(color: speech.isRecording ? AppTheme.neonGreen.opacity(0.2) : .black.opacity(0.3), radius: 15, y: 10).onAppear { Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in if !speech.isRecording { withAnimation(.spring()) { pIndex = (pIndex + 1) % pl.count } } } }
        // Живой перенос текста из голоса
        .onChange(of: speech.recognizedText) { _, newText in
            if !newText.isEmpty { text = newText }
        }
    }
}

struct ActionGrid: View {
    @Binding var activeSheet: ActiveSheet?
    var body: some View {
        HStack(spacing: 15) {
            ActionButton(icon: "magnifyingglass", title: "Goal", color: AppTheme.accentPurple) { triggerImpact(); activeSheet = .goal }
            ActionButton(icon: "map.fill", title: "Route", color: AppTheme.accentBlue) { triggerImpact(); activeSheet = .map }
            ActionButton(icon: "figure.run", title: "Events", color: AppTheme.accentRed) { triggerImpact(); activeSheet = .marathon }
            Button(action: { triggerImpact(style: .heavy); activeSheet = .cardioPro }) {
                VStack(spacing: 10) {
                    Image(systemName: "flame.fill").font(.title2).foregroundColor(.white).frame(width: 55, height: 55).background(LinearGradient(colors: [.orange, .red], startPoint: .top, endPoint: .bottom)).clipShape(Circle()).shadow(color: .orange.opacity(0.8), radius: 15)
                    Text("PRO").font(.caption2.bold()).foregroundColor(AppTheme.gold) // Убран огонек
                }
            }.buttonStyle(BouncyButton())
        }
    }
}

struct ActionButton: View {
    let icon: String; let title: String; let color: Color; let action: () -> Void
    var body: some View {
        Button(action: action) { VStack(spacing: 10) { Image(systemName: icon).font(.title2).foregroundColor(.white).frame(width: 55, height: 55).background(color).clipShape(Circle()).shadow(color: color.opacity(0.6), radius: 12); Text(title).font(.caption2.bold()).foregroundColor(.gray) } }.buttonStyle(BouncyButton())
    }
}

struct HorizontalHealthWidgets: View {
    @Binding var activeSheet: ActiveSheet?
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Log Health Data").font(.title3.bold()).foregroundColor(.white).padding(.horizontal) // Убран огонек
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 15) {
                    WidgetCard(icon: "heart.fill", title: "Blood", sub: "132 BPM", color: AppTheme.accentRed) { activeSheet = .blood }
                    WidgetCard(icon: "moon.zzz.fill", title: "Sleep", sub: "7h 12m", color: AppTheme.accentPurple) { activeSheet = .sleep }
                    WidgetCard(icon: "battery.100.bolt", title: "Recover", sub: "98% Ready", color: AppTheme.neonGreen) { activeSheet = .recovery }
                }.padding(.horizontal)
            }.scrollTransition(.interactive, axis: .horizontal) { content, phase in content.scaleEffect(phase.isIdentity ? 1 : 0.9).opacity(phase.isIdentity ? 1 : 0.7) }
        }.padding(.horizontal, -16)
    }
}

struct WidgetCard: View {
    let icon: String; let title: String; let sub: String; let color: Color; let action: () -> Void
    var body: some View {
        Button(action: { triggerImpact(); action() }) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon).font(.title).foregroundColor(color).shadow(color: color.opacity(0.8), radius: 8)
                VStack(alignment: .leading, spacing: 4) { Text(title).font(.headline.bold()).foregroundColor(.white); Text(sub).font(.caption.weight(.semibold)).foregroundColor(.gray) }
            }.padding(16).frame(width: 145, alignment: .leading).background(.ultraThinMaterial).cornerRadius(24).overlay(RoundedRectangle(cornerRadius: 24).stroke(AppTheme.glassGradient, lineWidth: 1.5)).shadow(color: .black.opacity(0.2), radius: 10, y: 5)
        }.buttonStyle(BouncyButton())
    }
}


struct LiveStatusPill: View {
    var isGpsActive: Bool; @State private var p = false
    var body: some View {
        HStack {
            Circle().fill(isGpsActive ? AppTheme.neonGreen : .red).frame(width: 8, height: 8).shadow(color: isGpsActive ? AppTheme.neonGreen : .red, radius: p ? 8 : 0).opacity(p ? 1.0 : 0.4)
            Text(isGpsActive ? "GPS LINKED 🔥" : "GPS SEARCHING 🔥").font(.system(size: 11, weight: .black, design: .monospaced)).foregroundColor(isGpsActive ? AppTheme.neonGreen : .red)
        }.padding(.horizontal, 16).padding(.vertical, 8).background(.ultraThinMaterial).clipShape(Capsule()).overlay(Capsule().stroke(Color.white.opacity(0.15))).shadow(color: .black.opacity(0.2), radius: 5)
        .onAppear { withAnimation(.easeInOut(duration: 1).repeatForever()) { p = true } }
    }
}

struct ScrollParallaxModifier: ViewModifier {
    func body(content: Content) -> some View { GeometryReader { geo in content.rotation3DEffect(.degrees(Double(geo.frame(in: .global).minY - 300) / -60), axis: (x: 1, y: 0, z: 0)) }.frame(height: 110) }
}

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1
    func body(content: Content) -> some View { content.overlay(LinearGradient(colors: [.clear, .white.opacity(0.6), .clear], startPoint: .topLeading, endPoint: .bottomTrailing).offset(x: phase * 100).mask(content)).onAppear { withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) { phase = 1 } } }
}

// MARK: - ЭКРАН РЕАЛЬНОЙ КАРТЫ
struct MapTrackerSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var locManager: LocationManager
    
    // Камера будет автоматически следить за пользователем
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    
    var body: some View {
        ZStack(alignment: .top) {
            // Настоящая карта Apple Maps
            Map(position: $position) {
                UserAnnotation() // Показывает синюю точку геолокации
            }
            .mapStyle(.standard(elevation: .realistic))
            .mapControls {
                MapUserLocationButton() // Кнопка возврата к себе
                MapCompass()            // Компас
                MapPitchToggle()        // 3D кнопка
            }
            .ignoresSafeArea()
            .colorScheme(.dark)
            
            // Красивый плавающий бар сверху
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(locManager.isAuthorized ? "СИГНАЛ GPS СТАБИЛЕН 🟢" : "GPS НЕ АКТИВЕН 🔴")
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                        .foregroundColor(locManager.isAuthorized ? AppTheme.neonGreen : AppTheme.accentRed)
                    
                    Text(locManager.isAuthorized ? "Координаты синхронизированы" : "Дайте разрешение в настройках")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
                
                Button(action: {
                    triggerImpact()
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.8))
                        .background(Circle().fill(.black).frame(width: 28, height: 28))
                }
                .buttonStyle(BouncyButton())
            }
            .padding(15)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.glassGradient, lineWidth: 1.5))
            .padding()
        }
        .onAppear {
            // Если зашли на карту, а GPS еще не дали - просим снова
            if !locManager.isAuthorized {
                locManager.requestAuth()
            }
        }
    }
}
struct GoalSheetView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("dailyStepGoal") private var currentGoal: Double = 10000
    @State private var customGoalText = ""
    @State private var pulse = false
    
    let aiSuggestions: [(title: String, value: Double, icon: String, color: Color)] = [
        ("Легкий старт", 8000, "figure.walk", AppTheme.neonGreen),
        ("Кибер-Норма", 12000, "bolt.fill", AppTheme.accentCyan),
        ("Ультра-Режим", 20000, "flame.fill", AppTheme.accentOrange)
    ]
    
    var body: some View {
        ZStack {
            AppTheme.bgDark.ignoresSafeArea()
            MeshGradientBackground()
            FloatingParticlesView()
            
            VStack(spacing: 25) {
                headerView
                circularProgressView
                customInputView
                suggestionsView
                Spacer()
                confirmButton
            }
        }
        .onAppear { pulse = true }
    }
    
    // MARK: - Подкомпоненты (Разбиваем для компилятора)
    
    private var headerView: some View {
        HStack {
            Spacer()
            Text("СИСТЕМНАЯ ЦЕЛЬ 🎯")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundColor(.white)
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill").font(.title2).foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private var circularProgressView: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.accentPurple.opacity(0.2), style: StrokeStyle(lineWidth: 15, dash: [10, 15]))
                .frame(width: 140, height: 140)
                .rotationEffect(.degrees(pulse ? 360 : 0))
                .animation(.linear(duration: 20).repeatForever(autoreverses: false), value: pulse)
            
            Circle()
                .trim(from: 0, to: 0.8)
                .stroke(AppTheme.accentPurple, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 140, height: 140)
                .shadow(color: AppTheme.accentPurple, radius: pulse ? 15 : 5)
                .scaleEffect(pulse ? 1.05 : 0.95)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulse)
            
            VStack(spacing: 0) {
                Text("ТЕКУЩАЯ")
                    .font(.system(size: 10, weight: .bold)).foregroundColor(.gray)
                Text("\(Int(currentGoal))")
                    .font(.system(size: 28, weight: .black, design: .monospaced)).foregroundColor(.white)
            }
        }
        .padding(.vertical, 20)
    }
    
    private var customInputView: some View {
        HStack {
            Image(systemName: "target").foregroundColor(AppTheme.accentPurple)
            TextField("Ввести свою цель...", text: $customGoalText)
                .keyboardType(.numberPad)
                .foregroundColor(.white)
                .font(.headline.monospaced())
            if !customGoalText.isEmpty {
                Button(action: { customGoalText = "" }) {
                    Image(systemName: "delete.left.fill").foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.accentPurple.opacity(0.5), lineWidth: 1.5))
        .padding(.horizontal, 20)
    }
    
    private var suggestionsView: some View {
            VStack(alignment: .leading, spacing: 15) {
                Text("ИИ АНАЛИЗ: РЕКОМЕНДАЦИИ 🤖")
                    .font(.caption.bold()).foregroundColor(.gray).padding(.horizontal, 25)
                
                ForEach(aiSuggestions, id: \.title) { suggestion in
                    Button(action: {
                        triggerImpact(style: .heavy)
                        saveGoal(suggestion.value)
                    }) {
                        HStack(spacing: 15) {
                            ZStack {
                                Circle().fill(suggestion.color.opacity(0.2)).frame(width: 40, height: 40)
                                Image(systemName: suggestion.icon).foregroundColor(suggestion.color)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(suggestion.title).font(.headline.bold()).foregroundColor(.white)
                                Text("\(Int(suggestion.value)) шагов").font(.caption.monospaced()).foregroundColor(suggestion.color)
                            }
                            Spacer()
                            Image(systemName: currentGoal == suggestion.value ? "checkmark.circle.fill" : "chevron.right")
                                .foregroundColor(currentGoal == suggestion.value ? AppTheme.neonGreen : .gray)
                                .font(.title3)
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                // ФИКС ОШИБКИ ЗДЕСЬ (AnyShapeStyle):
                                .stroke(currentGoal == suggestion.value ? AnyShapeStyle(AppTheme.neonGreen.opacity(0.5)) : AnyShapeStyle(AppTheme.glassGradient), lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                    }
                    .buttonStyle(BouncyButton())
                }
            }
        }
    private var confirmButton: some View {
        Button(action: {
            if let parsedGoal = Double(customGoalText), parsedGoal > 0 {
                triggerImpact(style: .heavy)
                saveGoal(parsedGoal)
            } else {
                triggerNotification(type: .error)
            }
        }) {
            Text("ПРИНЯТЬ ПРОТОКОЛ ✅")
                .font(.headline.bold())
                .padding()
                .frame(maxWidth: .infinity)
                .background(customGoalText.isEmpty ? Color.gray.opacity(0.3) : AppTheme.accentPurple)
                .foregroundColor(customGoalText.isEmpty ? .gray : .white)
                .cornerRadius(20)
                .shadow(color: customGoalText.isEmpty ? .clear : AppTheme.accentPurple.opacity(0.5), radius: 10)
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
        }
        .disabled(customGoalText.isEmpty)
        .buttonStyle(BouncyButton())
    }
    
    private func saveGoal(_ newGoal: Double) {
        currentGoal = newGoal
        triggerNotification(type: .success)
        dismiss()
    }
}
struct MarathonSheetView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            AppTheme.bgDark.ignoresSafeArea()
            MeshGradientBackground()
            FloatingParticlesView()
            
            VStack(spacing: 0) {
                // Кастомный заголовок (Без NavigationView)
                HStack {
                    Spacer()
                    Text("ГЛОБАЛЬНЫЕ ИВЕНТЫ 🌐")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 15)
                
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 20) {
                        MarathonCard(city: "Неоновый Токио", dist: "42.2 км", price: "1500 pts", slots: "12 мест", color: AppTheme.accentRed, icon: "building.2.fill")
                        MarathonCard(city: "Лондонский Даш", dist: "21.1 км", price: "800 pts", slots: "Открыто", color: AppTheme.accentBlue, icon: "cloud.heavyrain.fill")
                        MarathonCard(city: "Берлинский Спринт", dist: "10.0 км", price: "300 pts", slots: "4 места", color: AppTheme.accentOrange, icon: "bolt.fill")
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}
struct MarathonCard: View {
    let city, dist, price, slots: String
    let color: Color
    let icon: String
    
    @State private var isExpanded = false
    @State private var isRegistered = false
    
    var body: some View {
            VStack(spacing: 0) {
                headerView
                if isExpanded {
                    expandedDetailsView
                }
            }
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    // ФИКС ОШИБКИ ЗДЕСЬ (AnyShapeStyle):
                    .stroke(isExpanded ? AnyShapeStyle(color.opacity(0.5)) : AnyShapeStyle(AppTheme.glassGradient), lineWidth: 1)
            )
            .shadow(color: isExpanded ? color.opacity(0.2) : .clear, radius: 15)
        }
    private var headerView: some View {
        HStack(spacing: 15) {
            ZStack {
                Circle().fill(color.opacity(0.2)).frame(width: 50, height: 50)
                Image(systemName: icon).font(.title2).foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(city).font(.headline.bold()).foregroundColor(.white)
                HStack {
                    Text(dist).font(.caption.monospaced()).foregroundColor(color)
                    Text("•").foregroundColor(.gray)
                    Text(price).font(.caption).foregroundColor(.gray)
                }
            }
            Spacer()
            VStack(spacing: 5) {
                Text(slots)
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(slots.contains("мест") ? AppTheme.accentRed.opacity(0.8) : AppTheme.neonGreen.opacity(0.8))
                    .cornerRadius(8)
                    .foregroundColor(.white)
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down").foregroundColor(.gray).font(.caption)
            }
        }
        .padding(15)
        .background(Color.white.opacity(0.05))
        .onTapGesture {
            triggerImpact()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { isExpanded.toggle() }
        }
    }
    
    private var expandedDetailsView: some View {
        VStack(spacing: 15) {
            Divider().background(Color.white.opacity(0.1))
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Набор высоты").font(.caption).foregroundColor(.gray)
                    Text("140 м 🏔️").font(.subheadline.bold()).foregroundColor(.white)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Сложность").font(.caption).foregroundColor(.gray)
                    HStack(spacing: 2) {
                        ForEach(0..<5, id: \.self) { i in
                            Circle().fill(i < 4 ? color : Color.gray.opacity(0.3)).frame(width: 6, height: 6)
                        }
                    }
                }
            }
            
            Button(action: {
                triggerNotification(type: .success)
                withAnimation(.spring()) { isRegistered = true }
            }) {
                HStack {
                    Text(isRegistered ? "СТАТУС: ЗАРЕГИСТРИРОВАН" : "ПРИНЯТЬ УЧАСТИЕ")
                        .font(.caption.bold())
                    if isRegistered { Image(systemName: "checkmark.circle.fill") }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isRegistered ? AppTheme.neonGreen.opacity(0.2) : color.opacity(0.2))
                .foregroundColor(isRegistered ? AppTheme.neonGreen : color)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(isRegistered ? AppTheme.neonGreen : color, lineWidth: 1))
            }
            .disabled(isRegistered)
            .buttonStyle(BouncyButton())
        }
        .padding(15)
        .background(Color.black.opacity(0.3))
    }
}
struct BloodHealthSheetView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var pulse = false
    @State private var liveBPM = 132
    
    // Таймер для имитации живого сердцебиения
    let heartTimer = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            AppTheme.bgDark.ignoresSafeArea()
            MeshGradientBackground()
            FloatingParticlesView()
            
            VStack(spacing: 25) {
                
                // MARK: Кастомный заголовок
                HStack {
                    Spacer()
                    Text("БИО-СИНХРОНИЗАЦИЯ 🫀")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // MARK: Главный пульсатор (Исправлен баг с квадратом)
                ZStack {
                    // Расходящиеся волны
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(AppTheme.accentRed.opacity(0.5), lineWidth: 2)
                            .frame(width: 140, height: 140)
                            .scaleEffect(pulse ? 2.0 : 1.0)
                            .opacity(pulse ? 0 : 1)
                            .animation(
                                .easeOut(duration: 1.5).repeatForever(autoreverses: false).delay(Double(i) * 0.4),
                                value: pulse
                            )
                    }
                    
                    // Центральное ядро
                    Circle()
                        .fill(
                            LinearGradient(colors: [AppTheme.accentRed, Color.red.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 150, height: 150)
                        .shadow(color: AppTheme.accentRed.opacity(0.8), radius: pulse ? 25 : 10)
                        .scaleEffect(pulse ? 1.05 : 0.95)
                        .animation(.easeInOut(duration: 0.75).repeatForever(autoreverses: true), value: pulse)
                    
                    // Текст внутри
                    VStack(spacing: -5) {
                        Text("\(liveBPM)")
                            .font(.system(size: 55, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .contentTransition(.numericText()) // Красивая анимация смены цифр
                        Text("BPM")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                        Image(systemName: "waveform.path.ecg")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding(.top, 8)
                    }
                }
                .padding(.vertical, 20)
                
                // MARK: Индикатор пульсовых зон
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("ТЕКУЩАЯ ЗОНА:")
                            .font(.caption.bold())
                            .foregroundColor(.gray)
                        Text("СЖИГАНИЕ ЖИРА")
                            .font(.caption.bold())
                            .foregroundColor(AppTheme.accentRed)
                            .shadow(color: AppTheme.accentRed, radius: 5)
                        Spacer()
                        Image(systemName: "flame.fill")
                            .foregroundColor(AppTheme.accentRed)
                    }
                    
                    HStack(spacing: 6) {
                        ForEach(0..<5, id: \.self) { i in
                            Capsule()
                                .fill(i <= 2 ? AppTheme.accentRed : Color.white.opacity(0.1))
                                .frame(height: 8)
                                .shadow(color: i == 2 && pulse ? AppTheme.accentRed : .clear, radius: 5)
                        }
                    }
                    
                    HStack {
                        Text("Покой").font(.system(size: 10, weight: .bold)).foregroundColor(.gray)
                        Spacer()
                        Text("Максимум").font(.system(size: 10, weight: .bold)).foregroundColor(.gray)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.glassGradient, lineWidth: 1))
                .padding(.horizontal, 20)
                
                // MARK: Жизненные показатели
                HStack(spacing: 15) {
                    VitalsCard(title: "Давление", value: "120/80", icon: "drop.fill", color: AppTheme.accentOrange)
                    VitalsCard(title: "Кислород", value: "98%", icon: "wind", color: AppTheme.neonGreen)
                }
                .padding(.horizontal, 20)
                
                // MARK: ИИ Тренер
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(AppTheme.accentPurple)
                            .font(.title2)
                        Text("ИИ КАРДИО-ТРЕНЕР")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                    }
                    Text("Ваш мотор работает идеально. Вы находитесь в зоне жиросжигания. Сохраняйте этот темп еще 20 минут. Система охлаждения в норме.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineSpacing(4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(AppTheme.accentPurple.opacity(0.1))
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.accentPurple.opacity(0.4), lineWidth: 1))
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
        .onAppear {
            pulse = true
            triggerImpact(style: .rigid)
        }
        // Имитация живого сердцебиения
        .onReceive(heartTimer) { _ in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                liveBPM = Int.random(in: 130...135)
                triggerImpact(style: .soft) // Легкая пульсация телефона
            }
        }
    }
}

// MARK: - Карточка для давления и кислорода
struct VitalsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                Circle().fill(color.opacity(0.2)).frame(width: 40, height: 40)
                Image(systemName: icon).foregroundColor(color).font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption).foregroundColor(.gray)
                Text(value).font(.headline.bold().monospaced()).foregroundColor(.white)
            }
            Spacer()
        }
        .padding(15)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.glassGradient, lineWidth: 1))
    }
}
struct SleepAISheetView: View {
    @Environment(\.dismiss) var dismiss
    @State private var pulse = false
    
    var body: some View {
        ZStack {
            AppTheme.bgDark.ignoresSafeArea()
            MeshGradientBackground()
            FloatingParticlesView() // Добавляем медленные частицы
            
            VStack(spacing: 0) {
                // Кастомный заголовок
                HStack {
                    Spacer()
                    Text("НЕЙРО-СОН 🌙")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 10)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 30) {
                        
                        // Анимированная голограмма луны
                        ZStack {
                            Circle()
                                .stroke(AppTheme.gold.opacity(0.2), style: StrokeStyle(lineWidth: 2, dash: [8, 8]))
                                .frame(width: 140, height: 140)
                                .rotationEffect(.degrees(pulse ? 360 : 0))
                                .animation(.linear(duration: 20).repeatForever(autoreverses: false), value: pulse)
                            
                            Circle()
                                .fill(AppTheme.gold.opacity(0.1))
                                .frame(width: 100, height: 100)
                                .scaleEffect(pulse ? 1.2 : 0.8)
                                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulse)
                            
                            Image(systemName: "moon.zzz.fill")
                                .font(.system(size: 60))
                                .foregroundColor(AppTheme.gold)
                                .shadow(color: AppTheme.gold, radius: pulse ? 15 : 5)
                        }
                        .padding(.top, 20)
                        
                        // Блок с барами сна
                        VStack(spacing: 20) {
                            Text("ФАЗЫ ВОССТАНОВЛЕНИЯ")
                                .font(.caption.bold())
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            SleepBar(title: "Глубокий сон", duration: "2ч 10м", percentage: 0.8, color: AppTheme.accentPurple)
                            SleepBar(title: "Быстрый сон (REM)", duration: "1ч 45м", percentage: 0.6, color: AppTheme.accentBlue)
                            SleepBar(title: "Легкий сон", duration: "3ч 17м", percentage: 0.9, color: AppTheme.accentCyan)
                        }
                        .padding(20)
                        .background(.ultraThinMaterial)
                        .cornerRadius(25)
                        .overlay(RoundedRectangle(cornerRadius: 25).stroke(AppTheme.glassGradient, lineWidth: 1))
                        .padding(.horizontal, 20)
                        
                        // ИИ Сводка
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Image(systemName: "brain.head.profile")
                                    .font(.title2)
                                    .foregroundColor(AppTheme.accentCyan)
                                    .symbolEffect(.pulse)
                                Text("ИИ НЕЙРО-СВОДКА")
                                    .font(.headline.bold())
                                    .foregroundColor(.white)
                            }
                            
                            Text("Система зафиксировала отличный цикл глубокого сна. Нервная система восстановлена на 94%. Рекомендуется увеличить кардио-активность на 15% в первой половине дня.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .lineSpacing(5)
                        }
                        .padding(20)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(25)
                        .overlay(RoundedRectangle(cornerRadius: 25).stroke(AppTheme.accentCyan.opacity(0.3), lineWidth: 1))
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
        }
        .onAppear { pulse = true }
    }
}

// Обновленный бар прогресса сна
struct SleepBar: View {
    let title, duration: String
    let percentage: CGFloat
    let color: Color
    
    @State private var anim: CGFloat = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                Spacer()
                Text(duration)
                    .font(.caption.monospaced())
                    .foregroundColor(color)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)
                    
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * anim, height: 8)
                        .shadow(color: color, radius: 5)
                }
            }
            .frame(height: 8)
        }
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.7)) {
                anim = percentage
            }
        }
    }
}

struct RecoverySheetView: View {
    @Environment(\.dismiss) var dismiss
    @State private var pulse = false
    
    var body: some View {
        ZStack {
            AppTheme.bgDark.ignoresSafeArea()
            MeshGradientBackground()
            FloatingParticlesView()
            
            VStack(spacing: 0) {
                // Кастомный заголовок
                HStack {
                    Spacer()
                    Text("РЕГЕНЕРАЦИЯ 🔋")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 10)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 25) {
                        
                        // Главный индикатор (Баг с квадратом исправлен!)
                        ZStack {
                            // Внешнее свечение
                            Circle()
                                .fill(AppTheme.neonGreen.opacity(0.1))
                                .frame(width: 190, height: 190)
                                .scaleEffect(pulse ? 1.1 : 0.9)
                                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulse)
                            
                            // Трек
                            Circle()
                                .stroke(Color.white.opacity(0.1), lineWidth: 15)
                                .frame(width: 160, height: 160)
                            
                            // Прогресс
                            Circle()
                                .trim(from: 0, to: 0.98)
                                .stroke(AppTheme.neonGreen, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .frame(width: 160, height: 160)
                                .shadow(color: AppTheme.neonGreen.opacity(0.8), radius: pulse ? 15 : 5)
                            
                            VStack(spacing: -5) {
                                Image(systemName: "battery.100.bolt")
                                    .font(.title2)
                                    .foregroundColor(AppTheme.neonGreen)
                                    .padding(.bottom, 5)
                                Text("98%")
                                    .font(.system(size: 45, weight: .black, design: .monospaced))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.top, 20)
                        
                        Text("> СТАТУС: СИСТЕМА ВОССТАНОВЛЕНА")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(AppTheme.neonGreen)
                            .shadow(color: AppTheme.neonGreen, radius: 5)
                        
                        // Карточка Анализа
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Image(systemName: "cpu")
                                    .font(.title2)
                                    .foregroundColor(AppTheme.accentPurple)
                                Text("Анализ ЦНС и Мышц")
                                    .font(.headline.bold())
                                    .foregroundColor(.white)
                            }
                            
                            Text("Ваша центральная нервная система (ЦНС) восстановилась на 95% после вчерашней тренировки. Гликоген восполнен. Микротравмы устранены.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .lineSpacing(4)
                            
                            // Метрики
                            HStack(spacing: 12) {
                                RecoveryMetricBox(title: "Стресс ЦНС", value: "Низкий", color: AppTheme.neonGreen)
                                RecoveryMetricBox(title: "Мышцы", value: "Готовы", color: AppTheme.neonGreen)
                                RecoveryMetricBox(title: "Сонный долг", value: "0 ч", color: AppTheme.accentCyan)
                            }
                        }
                        .padding(20)
                        .background(.ultraThinMaterial)
                        .cornerRadius(25)
                        .overlay(RoundedRectangle(cornerRadius: 25).stroke(AppTheme.glassGradient, lineWidth: 1))
                        .padding(.horizontal, 20)
                        
                        // Протоколы отдыха
                        VStack(alignment: .leading, spacing: 15) {
                            Text("РЕКОМЕНДОВАННЫЕ ПРОТОКОЛЫ")
                                .font(.caption.bold())
                                .foregroundColor(.gray)
                                .padding(.horizontal, 5)
                            
                            RecoveryTipRow(icon: "figure.walk", title: "Активное восстановление", desc: "Легкая прогулка 20 мин для разгона молочной кислоты.", color: AppTheme.accentBlue)
                            RecoveryTipRow(icon: "thermometer.snowflake", title: "Криотерапия", desc: "Контрастный душ 3 мин снизит остаточное воспаление.", color: AppTheme.accentCyan)
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
        }
        .onAppear { pulse = true }
    }
}

// Обновленные метрики (Glassmorphism)
struct RecoveryMetricBox: View {
    let title: String
    let value: String
    let color: Color
    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.headline.bold())
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(Color.white.opacity(0.05))
        .cornerRadius(15)
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(color.opacity(0.3), lineWidth: 1))
    }
}

// Обновленные строки протоколов
struct RecoveryTipRow: View {
    let icon: String
    let title: String
    let desc: String
    let color: Color
    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                Circle().fill(color.opacity(0.2)).frame(width: 45, height: 45)
                Image(systemName: icon).font(.title3).foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                Text(desc)
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(.gray).font(.caption)
        }
        .padding(15)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.glassGradient, lineWidth: 1))
    }
}
// MARK: - МОДЕЛЬ ТРЕНИРОВКИ
struct CardioWorkout: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let duration: Int // В минутах
    let kcal: Int
    let icon: String
    let color: Color
    let difficulty: Int // от 1 до 5
    let aiAdvice: String
}

// MARK: - ГЛАВНЫЙ ЭКРАН ПРО-КАРДИО
struct CardioProSheetView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedWorkout: CardioWorkout? = nil
    
    // База данных тренировок
    let workouts = [
        CardioWorkout(title: "HIIT: Адский Спринт", description: "Интервальный бег. 30 сек ускорение на максимум, 15 сек легкий шаг. Сжигает жир как плазменный резак.", duration: 15, kcal: 320, icon: "figure.run", color: AppTheme.accentRed, difficulty: 5, aiAdvice: "Критическая нагрузка на ЦНС. Перед запуском убедитесь, что уровень гидратации в норме."),
        CardioWorkout(title: "Бой с Тенью", description: "Отработка ударных комбинаций высокой интенсивности. Работает весь корпус и плечевой пояс.", duration: 25, kcal: 280, icon: "figure.boxing", color: AppTheme.accentPurple, difficulty: 3, aiAdvice: "Отличный выбор для кардио без нагрузки на колени. Держите ритм дыхания."),
        CardioWorkout(title: "Эверест: Ступени", description: "Интенсивный подъем по лестнице (или степпер). Уровень 15. Прокачивает икры и ягодицы.", duration: 30, kcal: 450, icon: "figure.stair.stepper", color: AppTheme.neonGreen, difficulty: 4, aiAdvice: "Лактат в мышцах превысит норму на 12-й минуте. Терпите, система адаптируется."),
        CardioWorkout(title: "Кибер-Велосипед", description: "Непрерывное педалирование с изменяемым сопротивлением. Протокол 'Холмы'.", duration: 45, kcal: 550, icon: "bicycle", color: AppTheme.accentCyan, difficulty: 3, aiAdvice: "Оптимальный теплоотвод. Идеально для длительной выносливости ядра.")
    ]
    
    var body: some View {
        ZStack {
            AppTheme.bgDark.ignoresSafeArea()
            MeshGradientBackground()
            FloatingParticlesView()
            
            VStack(spacing: 0) {
                // Кастомный заголовок
                HStack {
                    Spacer()
                    VStack(spacing: 2) {
                        Text("ПРОТОКОЛЫ КАРДИО ⚡️")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        Text("Элитный уровень нагрузок")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 15)
                
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 15) {
                        ForEach(workouts) { workout in
                            Button(action: {
                                triggerImpact(style: .light)
                                selectedWorkout = workout
                            }) {
                                CardioCard(workout: workout)
                            }
                            .buttonStyle(BouncyButton())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        // Открываем детали тренировки
        .sheet(item: $selectedWorkout) { workout in
            CardioDetailSheet(workout: workout)
        }
    }
}

// MARK: - КАРТОЧКА ТРЕНИРОВКИ В СПИСКЕ
struct CardioCard: View {
    let workout: CardioWorkout
    
    var body: some View {
        HStack(spacing: 15) {
            // Неоновая иконка
            ZStack {
                LinearGradient(colors: [workout.color.opacity(0.8), workout.color.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                Image(systemName: workout.icon)
                    .font(.system(size: 30))
                    .foregroundColor(.white)
                    .shadow(color: .white.opacity(0.5), radius: 5)
            }
            .frame(width: 70, height: 70)
            .cornerRadius(15)
            .shadow(color: workout.color.opacity(0.4), radius: 8)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(workout.title)
                    .font(.headline.bold())
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 10) {
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                        Text("\(workout.duration) мин")
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                        Text("\(workout.kcal) ккал")
                    }
                }
                .font(.caption2.bold())
                .foregroundColor(.gray)
                
                // Индикатор сложности
                HStack(spacing: 4) {
                    ForEach(0..<5, id: \.self) { i in
                        Circle()
                            .fill(i < workout.difficulty ? workout.color : Color.gray.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.caption)
        }
        .padding(15)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppTheme.glassGradient, lineWidth: 1)
        )
    }
}

// MARK: - ЭКРАН ДЕТАЛЕЙ ТРЕНИРОВКИ (ФУНКЦИОНАЛ)
struct CardioDetailSheet: View {
    let workout: CardioWorkout
    @Environment(\.dismiss) var dismiss
    
    @State private var pulse = false
    @State private var isStarting = false
    @State private var startProgress: CGFloat = 0.0
    
    var body: some View {
        ZStack {
            AppTheme.bgDark.ignoresSafeArea()
            // Радиальный фон от цвета тренировки
            RadialGradient(colors: [workout.color.opacity(0.2), .clear], center: .top, startRadius: 10, endRadius: 400)
                .ignoresSafeArea()
            FloatingParticlesView()
            
            VStack(spacing: 25) {
                Capsule().fill(Color.gray.opacity(0.5)).frame(width: 40, height: 5).padding(.top)
                
                // Главная иконка
                ZStack {
                    Circle().stroke(workout.color.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [10, 5]))
                        .frame(width: 130, height: 130)
                        .rotationEffect(.degrees(pulse ? 360 : 0))
                        .animation(.linear(duration: 15).repeatForever(autoreverses: false), value: pulse)
                    
                    Circle().fill(workout.color.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .scaleEffect(pulse ? 1.1 : 0.9)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulse)
                    
                    Image(systemName: workout.icon)
                        .font(.system(size: 50))
                        .foregroundColor(workout.color)
                        .shadow(color: workout.color, radius: 10)
                }
                .padding(.top, 20)
                
                VStack(spacing: 5) {
                    Text(workout.title)
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Сложность: \(workout.difficulty)/5")
                        .font(.headline)
                        .foregroundColor(workout.color)
                }
                
                // Статы
                HStack(spacing: 20) {
                    StatBlock(icon: "timer", title: "Время", value: "\(workout.duration)м", color: AppTheme.accentCyan)
                    StatBlock(icon: "flame.fill", title: "Расход", value: "\(workout.kcal)", color: AppTheme.accentOrange)
                    StatBlock(icon: "heart.text.square.fill", title: "Пульс", value: "140+", color: AppTheme.accentRed)
                }
                .padding(.horizontal, 20)
                
                // Описание
                VStack(alignment: .leading, spacing: 10) {
                    Text("ПРОТОКОЛ")
                        .font(.caption.bold())
                        .foregroundColor(.gray)
                    Text(workout.description)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .lineSpacing(4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(15)
                .padding(.horizontal, 20)
                
                // ИИ Анализ
                HStack(alignment: .top, spacing: 15) {
                    Image(systemName: "brain.head.profile")
                        .font(.title2)
                        .foregroundColor(AppTheme.accentPurple)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("ИИ АНАЛИЗ")
                            .font(.caption.bold())
                            .foregroundColor(AppTheme.accentPurple)
                        Text(workout.aiAdvice)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineSpacing(3)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(AppTheme.accentPurple.opacity(0.1))
                .cornerRadius(15)
                .overlay(RoundedRectangle(cornerRadius: 15).stroke(AppTheme.accentPurple.opacity(0.3), lineWidth: 1))
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Функциональная кнопка "СТАРТ"
                VStack {
                    if isStarting {
                        VStack(spacing: 8) {
                            Text("ПОДГОТОВКА СИСТЕМ...")
                                .font(.caption.bold().monospaced())
                                .foregroundColor(workout.color)
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.1)).frame(height: 8)
                                Capsule().fill(workout.color).frame(width: (UIScreen.main.bounds.width - 40) * startProgress, height: 8)
                                    .shadow(color: workout.color, radius: 5)
                            }
                        }
                        .padding(.horizontal, 20)
                    } else {
                        Button(action: { startWorkoutRoutine() }) {
                            Text("ЗАПУСТИТЬ ПРОТОКОЛ 🚀")
                                .font(.headline.bold())
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(workout.color)
                                .foregroundColor(.black)
                                .cornerRadius(20)
                                .shadow(color: workout.color.opacity(0.5), radius: 15)
                                .padding(.horizontal, 20)
                        }
                        .buttonStyle(BouncyButton())
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .onAppear { pulse = true }
    }
    
    // Функция запуска тренировки
    private func startWorkoutRoutine() {
        triggerImpact(style: .heavy)
        withAnimation { isStarting = true }
        
        // Симуляция загрузки ИИ-протокола
        Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { timer in
            if startProgress >= 1.0 {
                timer.invalidate()
                triggerNotification(type: .success)
                // После загрузки закрываем окно (типа тренировка пошла)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    dismiss()
                }
            } else {
                withAnimation { startProgress += 0.015 }
            }
        }
    }
}

// Мини-компонент для статов
struct StatBlock: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon).foregroundColor(color)
            Text(value).font(.headline.bold()).foregroundColor(.white)
            Text(title).font(.caption2).foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .cornerRadius(15)
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(AppTheme.glassGradient, lineWidth: 1))
    }
}
// MARK: - ЭКРАН ИИ ЧАТА
struct AIChatView: View {
    @Environment(\.dismiss) var dismiss
    @State var initialMessage: String
    
    @State private var selectedTab = "Чат"
    @State private var inputText = ""
    @State private var messages: [ChatMessage] = []
    
    @StateObject private var speech = SpeechManager() // Микрофон чата
    
    let tabs = ["Чат", "История"]
    
    var body: some View {
        ZStack {
            AppTheme.bgDark.ignoresSafeArea()
            MeshGradientBackground()
            
            VStack(spacing: 0) {
                // Header (Без изменений)
                HStack {
                    Button(action: { dismiss() }) { Image(systemName: "chevron.down").font(.title2).foregroundColor(.white).padding(10).background(.ultraThinMaterial).clipShape(Circle()) }
                    Spacer(); Text("AI Coach 🤖").font(.headline.bold()).foregroundColor(.white); Spacer()
                    Image(systemName: "chevron.down").opacity(0).padding(10)
                }.padding().background(.ultraThinMaterial)
                
                // Вкладки (Без изменений)
                HStack(spacing: 0) {
                    ForEach(tabs, id: \.self) { tab in
                        Button(action: { withAnimation(.spring()) { selectedTab = tab } }) {
                            Text(tab).font(.subheadline.bold()).foregroundColor(selectedTab == tab ? .white : .gray).frame(maxWidth: .infinity).padding(.vertical, 12).background(ZStack { if selectedTab == tab { Capsule().fill(AppTheme.accentPurple).shadow(color: AppTheme.accentPurple.opacity(0.5), radius: 10) } })
                        }
                    }
                }.padding(4).background(Color.white.opacity(0.05)).clipShape(Capsule()).padding(.horizontal).padding(.top, 10)
                
                if selectedTab == "Чат" {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 15) {
                                ForEach(messages) { msg in ChatBubble(message: msg) }
                            }.padding()
                        }
                        .onChange(of: messages.count) { _, _ in if let last = messages.last { withAnimation { proxy.scrollTo(last.id, anchor: .bottom) } } }
                    }
                    
                    // Обновленное Поле ввода с МИКРОФОНОМ
                    HStack(spacing: 12) {
                        TextField("Задать вопрос ИИ...", text: $inputText)
                            .foregroundColor(.white).padding().background(Color.white.opacity(0.1)).cornerRadius(20).submitLabel(.send)
                            .onSubmit {
                                if speech.isRecording { speech.stopRecording() }
                                sendMessage()
                            }
                        
                        // Кнопка микрофона
                        Button(action: {
                            triggerImpact()
                            if speech.isRecording {
                                speech.stopRecording()
                            } else {
                                inputText = ""
                                speech.startRecording()
                            }
                        }) {
                            Image(systemName: speech.isRecording ? "waveform.circle.fill" : "mic.circle.fill")
                                .font(.system(size: 42))
                                .foregroundColor(speech.isRecording ? AppTheme.neonGreen : .gray)
                        }
                        
                        // Кнопка отправить
                        Button(action: {
                            if speech.isRecording { speech.stopRecording() }
                            sendMessage()
                        }) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 42))
                                .foregroundColor(inputText.isEmpty ? .gray : AppTheme.neonGreen)
                        }.disabled(inputText.isEmpty)
                    }
                    .padding().background(.ultraThinMaterial)
                    .onChange(of: speech.recognizedText) { _, newText in
                        if !newText.isEmpty { inputText = newText }
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 15) {
                            HistoryRow(date: "Сегодня", title: "План на марафон (21 км)")
                            HistoryRow(date: "Вчера", title: "Разбор пульса 160 BPM")
                            HistoryRow(date: "12 Апр", title: "Диета для похудения")
                        }.padding()
                    }
                }
            }
        }
        .onAppear {
            if !initialMessage.isEmpty {
                messages.append(ChatMessage(text: initialMessage, isUser: true))
                initialMessage = ""
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { messages.append(ChatMessage(text: "Анализирую ваш запрос... Как кибер-тренер, я готов помочь.", isUser: false)) }
            } else if messages.isEmpty {
                messages.append(ChatMessage(text: "Привет! Я твой AI-помощник. Составим план тренировок?", isUser: false))
            }
        }
    }
    func sendMessage() {
        guard !inputText.isEmpty else { return }
        messages.append(ChatMessage(text: inputText, isUser: true))
        inputText = ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { messages.append(ChatMessage(text: "Принято. Вношу коррективы в вашу программу.", isUser: false)) }
    }
}

struct ChatMessage: Identifiable { let id = UUID(); let text: String; let isUser: Bool }
struct ChatBubble: View {
    let message: ChatMessage
    var body: some View {
        HStack {
            if message.isUser { Spacer() }
            
            Text(message.text)
                .font(.subheadline)
                .foregroundColor(message.isUser ? .black : .white)
                .padding(15)
                .background(message.isUser ? AppTheme.neonGreen : Color.white.opacity(0.1))
                .cornerRadius(20)
                .overlay(
                    // РЕШЕНИЕ: Разбиваем условие через Group, чтобы компилятор не смешивал Color и LinearGradient
                    Group {
                        if message.isUser {
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.clear, lineWidth: 1)
                        } else {
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(AppTheme.glassGradient, lineWidth: 1)
                        }
                    }
                )
                .shadow(color: message.isUser ? AppTheme.neonGreen.opacity(0.3) : .clear, radius: 10)
                .frame(maxWidth: 280, alignment: message.isUser ? .trailing : .leading)
            
            if !message.isUser { Spacer() }
        }
    }
}

struct HistoryRow: View {
    let date: String
    let title: String
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(date)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(15)
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(AppTheme.glassGradient, lineWidth: 1))
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
            Color.black.opacity(0.5).background(.ultraThinMaterial).ignoresSafeArea().onTapGesture { onClose() }.opacity(appear ? 1 : 0)
            VStack(spacing: 20) {
                ZStack {
                    Circle().fill(tooltipColor.opacity(0.2)).frame(width: 60, height: 60)
                    Image(systemName: tooltipIcon).font(.system(size: 28, weight: .bold)).foregroundColor(tooltipColor).shadow(color: tooltipColor, radius: 10)
                }
                Text(tooltipTitle).font(.title2.bold()).foregroundColor(.white)
                Text(tooltipDescription).font(.body).multilineTextAlignment(.center).foregroundColor(.gray).padding(.horizontal)
                
                Button(action: onClose) {
                    Text("Понятно 🔥").font(.headline).foregroundColor(.white).padding().frame(maxWidth: .infinity).background(Color.white.opacity(0.1)).cornerRadius(15).overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.white.opacity(0.2)))
                }
            }
            .padding(25).background(.ultraThinMaterial).cornerRadius(30).overlay(RoundedRectangle(cornerRadius: 30).stroke(AppTheme.glassGradient, lineWidth: 2)).shadow(color: tooltipColor.opacity(0.3), radius: 30, y: 15).padding(30).scaleEffect(appear ? 1 : 0.8).opacity(appear ? 1 : 0).rotation3DEffect(.degrees(appear ? 0 : 10), axis: (x: 1, y: 0, z: 0))
        }.onAppear { triggerImpact(style: .heavy); withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { appear = true } }
    }
    
    var tooltipTitle: String { switch tooltip { case .calories: return "Калории 🔥"; case .time: return "Активное время 🔥"; case .distance: return "Пройденный путь 🔥" } }
    var tooltipDescription: String { switch tooltip { case .calories: return "Вы потратили \(Int(steps * 0.045)) ккал за активность!"; case .time: return "Это чистое время вашей активности в движении."; case .distance: return "Дистанция рассчитана на основе количества ваших шагов." } }
    var tooltipColor: Color { switch tooltip { case .calories: return AppTheme.accentOrange; case .time: return AppTheme.accentCyan; case .distance: return AppTheme.neonGreen } }
    var tooltipIcon: String { switch tooltip { case .calories: return "flame.fill"; case .time: return "timer"; case .distance: return "figure.walk" } }
}

// MARK: - РОУТЕР
struct SheetRouter: View {
    let sheet: ActiveSheet
    @ObservedObject var locManager: LocationManager
    var body: some View {
        Group {
            switch sheet {
            case .goal: GoalSheetView()
            case .map: MapTrackerSheet(locManager: locManager) // <-- Теперь тут всегда реальная карта
            case .marathon: MarathonSheetView()
            case .blood: BloodHealthSheetView()
            case .cardioPro: CardioProSheetView()
            case .sleep: SleepAISheetView()
            case .recovery: RecoverySheetView()
            }
        }.preferredColorScheme(.dark)
    }
}

// MARK: - ОГНЕННЫЕ ЧАСТИЦЫ
struct FloatingFireParticles: View {
    @State private var animate = false
    var body: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { i in
                Circle().fill(Color.orange.opacity(Double.random(in: 0.3...0.8))).frame(width: CGFloat.random(in: 4...8)).blur(radius: CGFloat.random(in: 1...2)).offset(x: animate ? CGFloat.random(in: -120...120) : CGFloat.random(in: -40...40), y: animate ? -150 : 20).opacity(animate ? 0 : 1).animation(.easeInOut(duration: Double.random(in: 2...4)).repeatForever(autoreverses: false).delay(Double.random(in: 0...2)), value: animate)
            }
        }.onAppear { animate = true }
    }
}
