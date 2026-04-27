import SwiftUI
struct OracleRouteItem: Identifiable {
    let id = UUID()
    let name: String
    let timeMsg: String
    let color: Color
    let icon: String
}

struct AICoreHubView: View {
    @Environment(\.dismiss) var dismiss
    @State private var activeTab: AITab = .chat
    @State private var pulse = false
    @State private var scanlineOffset: CGFloat = -500
    @State private var aiThinking = false
    @State private var terminalLogs: [String] = ["> СИСТЕМА: Инициализация Нейро-Ядра...", "> ИИ: Анализ биометрии за последние 7 дней завершен.", "> СТАТУС: Цифровой двойник синхронизирован."]
    
    enum AITab: String, CaseIterable {
        case chat = "AI КОУЧ"
        case avatar = "ДВОЙНИК", oracle = "ОРАКУЛ", bioFuel = "БИО-ТОПЛИВО", market = "ЧЕРНЫЙ РЫНОК", hack = "НЕЙРО-ВЗЛОМ"
        var icon: String {
            switch self {
            case .chat: return "bubble.left.and.bubble.right.fill"
            case .avatar: return "figure.stand.line.dotted.figure.stand"
            case .oracle: return "eye.trianglebadge.exclamationmark"
            case .bioFuel: return "flask.fill"
            case .market: return "cart.circle.fill"
            case .hack: return "bolt.shield.fill"
            }
        }
    }

    var body: some View {
        ZStack {
            AppTheme.bgDark.ignoresSafeArea(); MeshGradientBackground(); FloatingParticlesView()
            Rectangle().fill(LinearGradient(colors: [.clear, AppTheme.accentCyan.opacity(0.2), .clear], startPoint: .top, endPoint: .bottom)).frame(height: 60).offset(y: scanlineOffset).allowsHitTesting(false)
            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) { Image(systemName: "chevron.left").font(.title2).foregroundColor(.white).padding(10).background(.ultraThinMaterial).clipShape(Circle()) }.buttonStyle(BouncyButton())
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) { Text("NEURAL CORE 🧠").font(.system(size: 24, weight: .black, design: .rounded)).foregroundColor(.white); HStack(spacing: 5) { Circle().fill(aiThinking ? AppTheme.accentOrange : AppTheme.neonGreen).frame(width: 8, height: 8).scaleEffect(pulse ? 1.2 : 0.8); Text(aiThinking ? "ИИ АНАЛИЗИРУЕТ..." : "СИНХРОНИЗИРОВАНО").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(aiThinking ? AppTheme.accentOrange : AppTheme.neonGreen) } }
                }.padding(.horizontal).padding(.top, 10)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(AITab.allCases, id: \.self) { tab in
                            Button(action: { triggerImpact(style: .light); withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { activeTab = tab }; addTerminalLog("> ИИ: Переключение модуля: \(tab.rawValue)") }) {
                                VStack(spacing: 5) { Image(systemName: tab.icon).font(.title3); Text(tab.rawValue).font(.system(size: 10, weight: .black)) }.frame(width: 100).padding(.vertical, 12).background(activeTab == tab ? AppTheme.accentCyan.opacity(0.2) : Color.white.opacity(0.05)).foregroundColor(activeTab == tab ? AppTheme.accentCyan : .gray).cornerRadius(15).overlay(RoundedRectangle(cornerRadius: 15).stroke(activeTab == tab ? AnyShapeStyle(AppTheme.accentCyan) : AnyShapeStyle(AppTheme.glassGradient), lineWidth: 1))
                            }.buttonStyle(BouncyButton())
                        }
                    }.padding(.horizontal).padding(.vertical, 15)
                }
                
                TabView(selection: $activeTab) { AICoachChatView().tag(AITab.chat); DigitalTwinView(pulse: $pulse).tag(AITab.avatar); OraclePredictionView().tag(AITab.oracle); BioFuelView().tag(AITab.bioFuel); BlackMarketView().tag(AITab.market); NeuroHackView().tag(AITab.hack) }.tabViewStyle(.page(indexDisplayMode: .never)).animation(.easeInOut, value: activeTab)
                
                VStack(alignment: .leading, spacing: 5) {
                    HStack { Image(systemName: "terminal").foregroundColor(AppTheme.accentCyan); Text("ИИ ТЕРМИНАЛ").font(.system(size: 10, weight: .bold)).foregroundColor(.gray); Spacer() }
                    ScrollViewReader { proxy in ScrollView { VStack(alignment: .leading, spacing: 4) { ForEach(terminalLogs, id: \.self) { log in Text(log).font(.system(size: 11, design: .monospaced)).foregroundColor(log.contains("КРИТИЧЕСКИ") ? AppTheme.accentRed : AppTheme.neonGreen).frame(maxWidth: .infinity, alignment: .leading) } } }.frame(height: 60).onChange(of: terminalLogs.count) { _ in withAnimation { proxy.scrollTo(terminalLogs.last, anchor: .bottom) } } }
                }.padding(15).background(Color.black.opacity(0.6)).cornerRadius(20).overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.accentCyan.opacity(0.3), lineWidth: 1)).padding(.horizontal).padding(.bottom, 20)
            }
        }.onAppear { withAnimation(.easeInOut(duration: 1.5).repeatForever()) { pulse = true }; withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) { scanlineOffset = UIScreen.main.bounds.height + 200 } }
    }
    private func addTerminalLog(_ msg: String) { terminalLogs.append(msg); if terminalLogs.count > 10 { terminalLogs.removeFirst() } }
}

struct DigitalTwinView: View {
    @Binding var pulse: Bool; @State private var showWaterPopup = false; @State private var isScanning = false; @State private var showBioPopup = false; @State private var showEndurancePopup = false; @State private var showTonePopup = false; @State private var enduranceVal = Int.random(in: 40...100)
    var body: some View {
        VStack {
            Spacer()
            ZStack {
                Circle().stroke(AppTheme.accentCyan.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [5, 5])).frame(width: 220, height: 220).rotationEffect(.degrees(pulse ? 360 : 0)).animation(.linear(duration: 20).repeatForever(autoreverses: false), value: pulse); Image(systemName: "figure.stand").font(.system(size: 180)).foregroundColor(AppTheme.accentCyan.opacity(0.5)).shadow(color: AppTheme.accentCyan, radius: 10)
                TwinBodyNode(x: -40, y: -60, title: "ЦНС", status: "СТАБИЛЬНО", color: AppTheme.neonGreen, pulse: pulse); TwinBodyNode(x: 50, y: -20, title: "СЕРДЦЕ", status: "110 BPM", color: AppTheme.accentOrange, pulse: pulse); TwinBodyNode(x: -50, y: 50, title: "КОЛЕНО", status: "ИЗНОС 14%", color: AppTheme.accentRed, pulse: pulse)
                Rectangle().fill(AppTheme.neonGreen).frame(width: 150, height: 2).shadow(color: AppTheme.neonGreen, radius: 10).offset(y: isScanning ? 120 : -120)
            }.frame(height: 300)
            Spacer()
            HStack(spacing: 15) {
                Button(action: { triggerImpact(); showEndurancePopup = true }) { TwinStatCard(title: "ВЫНОСЛИВОСТЬ", value: "\(enduranceVal)%", icon: "battery.75", color: enduranceVal >= 70 ? AppTheme.neonGreen : AppTheme.accentOrange) }.buttonStyle(BouncyButton())
                Button(action: { triggerImpact(); showWaterPopup = true }) { TwinStatCard(title: "ВОДА В ЯДРЕ", value: "LOW", icon: "drop.triangle.fill", color: AppTheme.accentRed) }.buttonStyle(BouncyButton())
                Button(action: { triggerImpact(); showTonePopup = true }) { TwinStatCard(title: "МЫШЦЫ", value: "ТОНУС", icon: "bolt.heart.fill", color: AppTheme.gold) }.buttonStyle(BouncyButton())
            }.padding(.horizontal, 20)
            Button(action: { triggerImpact(style: .heavy); withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) { isScanning = true }; DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { isScanning = false; triggerNotification(type: .success); showBioPopup = true } }) { Text(isScanning ? "СКАНИРОВАНИЕ..." : "ЗАПУСТИТЬ БИО-ДИАГНОСТИКУ").font(.headline.bold()).padding().frame(maxWidth: .infinity).background(isScanning ? AppTheme.neonGreen.opacity(0.2) : AppTheme.accentCyan.opacity(0.2)).foregroundColor(isScanning ? AppTheme.neonGreen : AppTheme.accentCyan).cornerRadius(20).overlay(RoundedRectangle(cornerRadius: 20).stroke(isScanning ? AppTheme.neonGreen : AppTheme.accentCyan, lineWidth: 1)) }.buttonStyle(BouncyButton()).padding(20).disabled(isScanning)
        }
        .sheet(isPresented: $showWaterPopup) { HydrationPopupSheet() }.sheet(isPresented: $showBioPopup) { BioResultSheet() }.sheet(isPresented: $showEndurancePopup) { EndurancePopupSheet(endurance: enduranceVal) }.sheet(isPresented: $showTonePopup) { MuscleTonePopupSheet() }
    }
}

struct OraclePredictionView: View {
    let staminaDrop: [CGFloat] = [0.9, 0.75, 0.4, 0.8, 1.0]; let days = ["СЕГ", "ЗАВ", "СРД", "ЧТВ", "ПТН"]
    @State private var selectedRoute: OracleRouteItem? = nil
    let aiRoutes = [ OracleRouteItem(name: "Неоновый Даш (5км)", timeMsg: "Улучшишь на 1м 20с", color: AppTheme.neonGreen, icon: "arrow.up.right"), OracleRouteItem(name: "Горный Перевал (12км)", timeMsg: "Не хватит стамины", color: AppTheme.accentRed, icon: "xmark.octagon") ]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                HStack(spacing: 15) { Image(systemName: "eye.trianglebadge.exclamationmark").font(.system(size: 40)).foregroundColor(AppTheme.accentOrange); VStack(alignment: .leading, spacing: 5) { Text("ПРОГНОЗ КРИТИЧЕСКОГО СПАДА").font(.system(size: 12, weight: .black)).foregroundColor(AppTheme.accentOrange); Text("Оракул предвидит отказ мышечных волокон в среду. Снизьте нагрузку на 40% завтра.").font(.caption).foregroundColor(.white) } }.padding().background(AppTheme.accentOrange.opacity(0.1)).cornerRadius(20).overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.accentOrange.opacity(0.5), lineWidth: 1)).padding(.horizontal, 20)
                VStack(alignment: .leading) { Text("ГРАФИК ВЫЖИВАЕМОСТИ").font(.caption.bold()).foregroundColor(.gray); HStack(alignment: .bottom, spacing: 20) { ForEach(0..<5, id: \.self) { i in VStack { Text("\(Int(staminaDrop[i] * 100))%").font(.system(size: 10, design: .monospaced)).foregroundColor(staminaDrop[i] < 0.5 ? AppTheme.accentRed : AppTheme.neonGreen); ZStack(alignment: .bottom) { Capsule().fill(Color.white.opacity(0.05)).frame(width: 30, height: 120); Capsule().fill(staminaDrop[i] < 0.5 ? AppTheme.accentRed : AppTheme.neonGreen).frame(width: 30, height: 120 * staminaDrop[i]) }; Text(days[i]).font(.system(size: 12, weight: .bold)).foregroundColor(.white) } } }.frame(maxWidth: .infinity).padding(.top, 10) }.padding().background(.ultraThinMaterial).cornerRadius(20).padding(.horizontal, 20)
                VStack(alignment: .leading, spacing: 10) { Text("ИИ-АНАЛИЗ ВАШИХ ТРОП").font(.caption.bold()).foregroundColor(.gray); ForEach(aiRoutes) { route in Button(action: { triggerImpact(); selectedRoute = route }) { OracleRouteRow(route: route.name, time: route.timeMsg, color: route.color, icon: route.icon) }.buttonStyle(BouncyButton()) } }.padding(.horizontal)
                Spacer(minLength: 40)
            }
        }.sheet(item: $selectedRoute) { route in OracleGhostStatsSheet(route: route) }
    }
}

struct BioFuelView: View {
    @State private var showCaloriePromo = false
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                ZStack { Image(systemName: "hexagon.fill").font(.system(size: 80)).foregroundColor(AppTheme.accentPurple.opacity(0.2)); Image(systemName: "bolt.fill").font(.system(size: 40)).foregroundColor(AppTheme.gold) }
                Text("ИИ РЕЦЕПТ ВОССТАНОВЛЕНИЯ").font(.title3.bold()).foregroundColor(.white)
                VStack(spacing: 15) { FuelBar(title: "ПРОТЕИН (Строительство имплантов)", value: "120г", progress: 0.8, color: AppTheme.accentCyan); FuelBar(title: "УГЛЕВОДЫ (Энерго-ячейки)", value: "350г", progress: 0.6, color: AppTheme.accentOrange) }.padding().background(.ultraThinMaterial).cornerRadius(20).padding(.horizontal, 20)
                VStack(alignment: .leading, spacing: 10) { HStack { Image(systemName: "fork.knife").foregroundColor(AppTheme.neonGreen); Text("ПРОТОКОЛ: ИДЕАЛЬНЫЙ ПРИЕМ ПИЩИ").font(.headline.bold()).foregroundColor(.white) }; Text("Синтез: 150г куриного филе (паровой обдув), 100г киноа, порция синтетических витаминов C и D. Запить 500мл H2O.").font(.subheadline).foregroundColor(.gray); Button(action: { triggerImpact(); showCaloriePromo = true }) { Text("ПОДТВЕРДИТЬ СИНТЕЗ ПИЩИ ✅").font(.caption.bold()).padding().frame(maxWidth: .infinity).background(AppTheme.neonGreen.opacity(0.2)).foregroundColor(AppTheme.neonGreen).cornerRadius(10).overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.neonGreen, lineWidth: 1)) }.buttonStyle(BouncyButton()).padding(.top, 5) }.padding().background(.ultraThinMaterial).cornerRadius(20).overlay(RoundedRectangle(cornerRadius: 20).stroke(AnyShapeStyle(AppTheme.glassGradient), lineWidth: 1)).padding(.horizontal)
            }
        }.sheet(isPresented: $showCaloriePromo) { CaloriePromoSheet() }
    }
}

struct BlackMarketView: View {
    @State private var showBalanceInfo = false
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                Button(action: { triggerImpact(); showBalanceInfo = true }) { HStack { VStack(alignment: .leading) { HStack { Text("ТВОЙ БАЛАНС").font(.caption).foregroundColor(.gray); Image(systemName: "info.circle").font(.caption2).foregroundColor(.gray) }; Text("12,450 🪙").font(.title2.bold()).foregroundColor(AppTheme.gold) }; Spacer(); Image(systemName: "cart.circle.fill").font(.system(size: 40)).foregroundColor(AppTheme.accentRed) }.padding(20).background(AppTheme.accentRed.opacity(0.1)).cornerRadius(20).overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.accentRed.opacity(0.4), lineWidth: 1)) }.buttonStyle(BouncyButton()).padding(.horizontal, 20)
                Text("ДОСТУПНЫЕ ИМПЛАНТЫ").font(.caption.bold()).foregroundColor(.white).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 25)
                ImplantCard(title: "Титановые Легкие v2", desc: "Снижает потерю стамины при беге на 15%", price: "8,000", icon: "lungs.fill", color: AppTheme.accentCyan); ImplantCard(title: "Карбоновые Икры", desc: "Увеличивает добычу поинтов на +5% за шаг", price: "15,000", icon: "figure.walk", color: AppTheme.neonGreen); ImplantCard(title: "Нейро-Стимулятор", desc: "Игнорирование усталости (Авто-выполнение 1 квеста в день)", price: "50,000", icon: "brain.head.profile", color: AppTheme.accentPurple)
            }.padding(.bottom, 30)
        }.sheet(isPresented: $showBalanceInfo) { MarketEconomySheet() }
    }
}

struct NeuroHackView: View {
    @State private var hacked = false; @State private var glitching = false
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            ZStack { Circle().fill(hacked ? AppTheme.neonGreen.opacity(0.2) : AppTheme.accentRed.opacity(0.2)).frame(width: 150, height: 150); Image(systemName: hacked ? "lock.open.fill" : "bolt.shield.fill").font(.system(size: 60)).foregroundColor(hacked ? AppTheme.neonGreen : AppTheme.accentRed).offset(x: glitching ? CGFloat.random(in: -5...5) : 0).shadow(color: hacked ? AppTheme.neonGreen : AppTheme.accentRed, radius: 15) }
            VStack(spacing: 10) { Text(hacked ? "СИСТЕМА ВЗЛОМАНА" : "ПРОТОКОЛ РАЗГОНА").font(.title2.bold()).foregroundColor(.white); Text(hacked ? "Множитель шагов х2.0 активирован на 24 часа. Сбой системы не произошел." : "Рискни и взломай свой организм. Шанс успеха 70%. При успехе: множитель шагов x2.0. При провале: потеря 50% энергии на сегодня.").font(.subheadline).foregroundColor(.gray).multilineTextAlignment(.center).padding(.horizontal, 30) }
            Spacer()
            Button(action: { if !hacked { triggerImpact(style: .heavy); withAnimation(.spring(response: 0.1, dampingFraction: 0.2)) { glitching = true }; DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { withAnimation { glitching = false; hacked = true } } } }) { Text(hacked ? "АКТИВНО 🟢" : "НАЧАТЬ ВЗЛОМ ⚠️").font(.title3.bold()).padding().frame(maxWidth: .infinity).background(hacked ? AppTheme.neonGreen.opacity(0.5) : AppTheme.accentRed).foregroundColor(.white).cornerRadius(20).shadow(color: hacked ? .clear : AppTheme.accentRed, radius: 10) }.buttonStyle(BouncyButton()).padding(.horizontal, 20).disabled(hacked)
            Spacer()
        }
    }
}

struct TwinBodyNode: View {
    let x: CGFloat; let y: CGFloat; let title: String; let status: String; let color: Color; let pulse: Bool
    var body: some View { HStack(spacing: 0) { ZStack { Circle().fill(color).frame(width: 8, height: 8); Circle().stroke(color, lineWidth: 1).frame(width: 20, height: 20).scaleEffect(pulse ? 1.5 : 0.5).opacity(pulse ? 0 : 1) }; Path { path in path.move(to: CGPoint(x: 0, y: 0)); path.addLine(to: CGPoint(x: x > 0 ? 30 : -30, y: 0)) }.stroke(color.opacity(0.5), lineWidth: 1).frame(width: 30, height: 1); VStack(alignment: x > 0 ? .leading : .trailing) { Text(title).font(.system(size: 8, weight: .bold)).foregroundColor(.white); Text(status).font(.system(size: 8, design: .monospaced)).foregroundColor(color) }.padding(4).background(Color.black.opacity(0.5)).cornerRadius(5).overlay(RoundedRectangle(cornerRadius: 5).stroke(color.opacity(0.3), lineWidth: 1)) }.offset(x: x, y: y) }
}
struct TwinStatCard: View { let title: String; let value: String; let icon: String; let color: Color; var body: some View { VStack(spacing: 5) { Image(systemName: icon).foregroundColor(color).font(.title3); Text(value).font(.headline.bold().monospaced()).foregroundColor(.white); Text(title).font(.system(size: 8, weight: .bold)).foregroundColor(.gray) }.frame(maxWidth: .infinity).padding(.vertical, 12).background(.ultraThinMaterial).cornerRadius(15).overlay(RoundedRectangle(cornerRadius: 15).stroke(AnyShapeStyle(AppTheme.glassGradient), lineWidth: 1)) } }
struct OracleRouteRow: View { let route: String; let time: String; let color: Color; let icon: String; var body: some View { HStack { Image(systemName: icon).foregroundColor(color); VStack(alignment: .leading) { Text(route).font(.headline.bold()).foregroundColor(.white); Text(time).font(.caption).foregroundColor(color) }; Spacer(); Image(systemName: "brain").foregroundColor(Color.white.opacity(0.2)) }.padding().background(.ultraThinMaterial).cornerRadius(15).overlay(RoundedRectangle(cornerRadius: 15).stroke(AnyShapeStyle(AppTheme.glassGradient), lineWidth: 1)) } }
struct ImplantCard: View { let title: String; let desc: String; let price: String; let icon: String; let color: Color; var body: some View { HStack(spacing: 15) { ZStack { Circle().fill(color.opacity(0.2)).frame(width: 50, height: 50); Image(systemName: icon).font(.title2).foregroundColor(color) }; VStack(alignment: .leading, spacing: 4) { Text(title).font(.headline.bold()).foregroundColor(.white); Text(desc).font(.caption2).foregroundColor(.gray).lineLimit(2) }; Spacer(); Button(action: { triggerImpact(style: .heavy) }) { Text("\(price)").font(.caption.bold()).padding(.horizontal, 10).padding(.vertical, 8).background(AppTheme.gold.opacity(0.2)).foregroundColor(AppTheme.gold).cornerRadius(10) }.buttonStyle(BouncyButton()) }.padding(15).background(.ultraThinMaterial).cornerRadius(20).overlay(RoundedRectangle(cornerRadius: 20).stroke(AnyShapeStyle(AppTheme.glassGradient), lineWidth: 1)).padding(.horizontal, 20) } }
struct FuelBar: View { let title: String; let value: String; let progress: CGFloat; let color: Color; @State private var anim: CGFloat = 0; var body: some View { VStack(alignment: .leading, spacing: 5) { HStack { Text(title).font(.system(size: 10, weight: .bold)).foregroundColor(.gray); Spacer(); Text(value).font(.system(size: 12, weight: .black, design: .monospaced)).foregroundColor(color) }; ZStack(alignment: .leading) { Capsule().fill(Color.white.opacity(0.1)).frame(height: 8); Capsule().fill(color).frame(width: 300 * anim, height: 8).shadow(color: color, radius: 5) } }.onAppear { withAnimation(.spring(response: 1.0, dampingFraction: 0.7)) { anim = progress } } } }

// Попапы Нейро-Ядра
struct BioResultSheet: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        ZStack {
            AppTheme.bgDark.ignoresSafeArea(); MeshGradientBackground(); FloatingParticlesView()
            VStack(spacing: 20) {
                Capsule().fill(Color.gray).frame(width: 40, height: 5).padding(.top); Image(systemName: "cross.case.fill").font(.system(size: 60)).foregroundColor(AppTheme.accentCyan).padding(.top, 10); Text("ОТЧЕТ ИИ: БИО-СТАТУС").font(.title2.bold()).foregroundColor(.white)
                VStack(alignment: .leading, spacing: 15) { HStack { Image(systemName: "exclamationmark.triangle.fill").foregroundColor(AppTheme.accentOrange); Text("Системный перегруз: Легкий").font(.headline).foregroundColor(.white) }; Text("Мышечные волокна ног требуют регенерации. ИИ рекомендует сменить 'Бег' на 'Легкую ходьбу' на ближайшие 24 часа. Риск разрыва связок при ускорении >12 км/ч составляет 64%.").font(.subheadline).foregroundColor(.gray); Text("ПРОТОКОЛ ВОССТАНОВЛЕНИЯ:").font(.caption.bold()).foregroundColor(AppTheme.neonGreen).padding(.top, 10)
                    HStack(spacing: 10) { VStack { Image(systemName: "bed.double.fill").foregroundColor(AppTheme.accentPurple); Text("Сон 8.5ч").font(.caption2).foregroundColor(.white) }.frame(maxWidth: .infinity).padding(10).background(Color.white.opacity(0.05)).cornerRadius(10); VStack { Image(systemName: "drop.fill").foregroundColor(AppTheme.accentBlue); Text("H2O 3.2Л").font(.caption2).foregroundColor(.white) }.frame(maxWidth: .infinity).padding(10).background(Color.white.opacity(0.05)).cornerRadius(10); VStack { Image(systemName: "figure.walk").foregroundColor(AppTheme.neonGreen); Text("Шаги < 5k").font(.caption2).foregroundColor(.white) }.frame(maxWidth: .infinity).padding(10).background(Color.white.opacity(0.05)).cornerRadius(10) }
                }.padding().background(.ultraThinMaterial).cornerRadius(20).overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.glassGradient, lineWidth: 1)).padding(.horizontal)
                Spacer()
                Button("ПРИНЯТЬ К СВЕДЕНИЮ") { dismiss() }.font(.headline.bold()).padding().frame(maxWidth: .infinity).background(AppTheme.accentCyan).foregroundColor(.black).cornerRadius(15).padding(.horizontal).padding(.bottom, 20)
            }
        }
    }
}

struct OracleGhostStatsSheet: View {
    let route: OracleRouteItem; @Environment(\.dismiss) var dismiss
    var body: some View {
        ZStack {
            AppTheme.bgDark.ignoresSafeArea(); MeshGradientBackground()
            VStack(spacing: 20) {
                Capsule().fill(Color.gray).frame(width: 40, height: 5).padding(.top); Text(route.name).font(.title2.bold()).foregroundColor(.white).padding(.top, 10)
                HStack(spacing: 20) { VStack { Text("ТВОЙ РЕКОРД").font(.caption).foregroundColor(.gray); Text("24:12").font(.title.bold().monospaced()).foregroundColor(AppTheme.neonGreen) }; Text("VS").font(.headline.italic()).foregroundColor(.gray); VStack { Text("ПРИЗРАК (ИИ)").font(.caption).foregroundColor(.gray); Text("25:32").font(.title.bold().monospaced()).foregroundColor(AppTheme.accentRed) } }.padding().frame(maxWidth: .infinity).background(.ultraThinMaterial).cornerRadius(20).padding(.horizontal)
                VStack(alignment: .leading, spacing: 10) { Text("ИИ АНАЛИЗ ЗАБЕГА:").font(.caption.bold()).foregroundColor(.gray); HStack { Image(systemName: "flame.fill").foregroundColor(AppTheme.accentOrange); Text("Ты обогнал призрака на ").foregroundColor(.white) + Text("1 мин 20 сек").bold().foregroundColor(AppTheme.neonGreen) }.font(.subheadline); HStack { Image(systemName: "heart.text.square.fill").foregroundColor(.pink); Text("Средний пульс ниже нормы: 132 BPM").font(.subheadline).foregroundColor(.white) } }.padding().frame(maxWidth: .infinity, alignment: .leading).background(Color.white.opacity(0.05)).cornerRadius(15).padding(.horizontal)
                VStack(alignment: .leading) { Text("ГРАФИК СКОРОСТИ (ТЫ vs ПРИЗРАК)").font(.caption.bold()).foregroundColor(.gray); HStack(alignment: .bottom, spacing: 15) { ForEach(0..<8) { i in VStack(spacing: 5) { Capsule().fill(AppTheme.accentRed).frame(width: 8, height: CGFloat.random(in: 30...80)); Capsule().fill(AppTheme.neonGreen).frame(width: 8, height: CGFloat.random(in: 50...100)); Text("\(i+1)k").font(.system(size: 8)).foregroundColor(.gray) } } }.frame(height: 120) }.padding().frame(maxWidth: .infinity).background(.ultraThinMaterial).cornerRadius(20).padding(.horizontal)
                Spacer()
                Button("ЗАКРЫТЬ ОТЧЕТ") { dismiss() }.font(.headline.bold()).padding().frame(maxWidth: .infinity).background(Color.white.opacity(0.1)).foregroundColor(.white).cornerRadius(15).padding(.horizontal).padding(.bottom, 20)
            }
        }
    }
}

struct CaloriePromoSheet: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        ZStack {
            AppTheme.bgDark.ignoresSafeArea(); MeshGradientBackground(); FloatingParticlesView()
            VStack(spacing: 25) {
                Capsule().fill(Color.gray).frame(width: 40, height: 5).padding(.top); ZStack { Circle().fill(AppTheme.accentPurple.opacity(0.2)).frame(width: 120, height: 120); Image(systemName: "camera.macro").font(.system(size: 60)).foregroundColor(AppTheme.accentCyan) }.padding(.top, 20)
                Text("РАЗБЛОКИРОВАН НОВЫЙ МОДУЛЬ").font(.system(size: 14, weight: .black)).foregroundColor(AppTheme.accentCyan); Text("AI Vision Tracker 👁️").font(.system(size: 32, weight: .black, design: .rounded)).foregroundColor(.white)
                Text("Советуем протестировать наш новейший модуль ИИ. Просто наведи камеру на свою еду, и нейросеть мгновенно рассчитает калории, белки, жиры и углеводы!").font(.subheadline).foregroundColor(.gray).multilineTextAlignment(.center).padding(.horizontal, 20)
                VStack(spacing: 10) { HStack { Image(systemName: "checkmark.circle.fill").foregroundColor(AppTheme.neonGreen); Text("Распознавание > 10,000 блюд").foregroundColor(.white) }.frame(maxWidth: .infinity, alignment: .leading); HStack { Image(systemName: "checkmark.circle.fill").foregroundColor(AppTheme.neonGreen); Text("Оценка граммовки по фото").foregroundColor(.white) }.frame(maxWidth: .infinity, alignment: .leading) }.padding().background(Color.white.opacity(0.05)).cornerRadius(15).padding(.horizontal)
                Spacer()
                Button("ПЕРЕЙТИ К ТЕСТИРОВАНИЮ 🚀") { triggerImpact(style: .heavy); dismiss() }.font(.headline.bold()).padding().frame(maxWidth: .infinity).background(AppTheme.accentCyan).foregroundColor(.black).cornerRadius(20).shadow(color: AppTheme.accentCyan.opacity(0.5), radius: 10).padding(.horizontal).padding(.bottom, 20).buttonStyle(BouncyButton())
            }
        }
    }
}

struct MarketEconomySheet: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        ZStack {
            AppTheme.bgDark.ignoresSafeArea(); LinearGradient(colors: [AppTheme.accentRed.opacity(0.2), .clear], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            VStack(spacing: 20) {
                Capsule().fill(Color.gray).frame(width: 40, height: 5).padding(.top); Image(systemName: "exclamationmark.shield.fill").font(.system(size: 70)).foregroundColor(AppTheme.accentRed).padding(.top, 10); Text("ЭКОНОМИКА ЛИГИ").font(.title2.bold()).foregroundColor(.white)
                Text("Внимание, Кибер-Атлет! ⚠️\n\nМонеты Чёрного Рынка — это твои заработанные очки Лиги (Leaderboard Points).\n\nПокупая импланты, ты **тратишь свой рейтинг** и можешь спуститься в таблице лидеров. Однако, крутые импланты дают перманентные бонусы к шагам, позволяя тебе зарабатывать очки в 2 раза быстрее в будущем.\n\nИнвестируй с умом!").font(.subheadline).foregroundColor(.gray).multilineTextAlignment(.center).padding().background(.ultraThinMaterial).cornerRadius(20).overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.glassGradient, lineWidth: 1)).padding(.horizontal)
                Spacer()
                Button("Я ПОНЯЛ РИСКИ 🔥") { triggerImpact(); dismiss() }.font(.headline.bold()).padding().frame(maxWidth: .infinity).background(AppTheme.accentRed).foregroundColor(.white).cornerRadius(15).padding(.horizontal).padding(.bottom, 20)
            }
        }
    }
}

struct EndurancePopupSheet: View {
    let endurance: Int; @Environment(\.dismiss) var dismiss; @State private var pulse = false
    var body: some View {
        let isHigh = endurance >= 70; let color = isHigh ? AppTheme.neonGreen : AppTheme.accentOrange
        ZStack {
            AppTheme.bgDark.ignoresSafeArea(); MeshGradientBackground(); FloatingParticlesView()
            VStack(spacing: 25) {
                Capsule().fill(Color.gray).frame(width: 40, height: 5).padding(.top); ZStack { Circle().fill(color.opacity(0.2)).frame(width: 100, height: 100); Image(systemName: isHigh ? "battery.100.bolt" : "battery.25").font(.system(size: 50)).foregroundColor(color).scaleEffect(pulse ? 1.1 : 0.9).animation(.easeInOut(duration: 1.0).repeatForever(), value: pulse) }.padding(.top, 10)
                Text("АНАЛИЗ: ВЫНОСЛИВОСТЬ").font(.title2.bold()).foregroundColor(.white); Text("Уровень заряда ядра: \(endurance)%").font(.system(size: 40, weight: .black, design: .monospaced)).foregroundColor(color)
                VStack(alignment: .leading, spacing: 10) { HStack { Image(systemName: "cpu").foregroundColor(color); Text(isHigh ? "Система: ОПТИМАЛЬНО" : "Система: ИСТОЩЕНИЕ").font(.headline).foregroundColor(.white) }; Text(isHigh ? "Твоя энерго-ячейка заряжена. Обычные шаги уже не дадут сильного эффекта. ИИ рекомендует интервальный бег, спринты в гору или нестандартные нагрузки для шокирования ЦНС." : "Заряд падает. Мышцы закислены лактатом. Продолжение интенсивных нагрузок приведет к сгоранию нейро-связей. ИИ рекомендует горячую ванну, легкий стретчинг и глубокий сон.").font(.subheadline).foregroundColor(.gray).lineSpacing(4) }.padding().frame(maxWidth: .infinity, alignment: .leading).background(.ultraThinMaterial).cornerRadius(20).overlay(RoundedRectangle(cornerRadius: 20).stroke(color.opacity(0.4), lineWidth: 1)).padding(.horizontal)
                if isHigh { VStack(spacing: 15) { Text("ГОТОВ К НОВЫМ ВЫЗОВАМ?").font(.caption.bold()).foregroundColor(AppTheme.accentCyan); Button(action: { triggerImpact(style: .heavy) }) { HStack { Image(systemName: "brain.head.profile").font(.title2); Text("ПЕРЕЙТИ В ИИ-ТРЕКЕР УПРАЖНЕНИЙ 🤖").font(.headline.bold()) }.padding().frame(maxWidth: .infinity).background(AppTheme.accentCyan).foregroundColor(.black).cornerRadius(15).shadow(color: AppTheme.accentCyan.opacity(0.5), radius: 10) }.buttonStyle(BouncyButton()); Text("Сгенерируй персональный план тренировок с помощью нейросети.").font(.caption2).foregroundColor(.gray).multilineTextAlignment(.center) }.padding().background(Color.white.opacity(0.05)).cornerRadius(20).padding(.horizontal) }
                Spacer()
                Button("ЗАКРЫТЬ ОТЧЕТ") { dismiss() }.font(.headline.bold()).padding().frame(maxWidth: .infinity).background(Color.white.opacity(0.1)).foregroundColor(.white).cornerRadius(15).padding(.horizontal).padding(.bottom, 20)
            }
        }.onAppear { pulse = true }
    }
}

struct MuscleTonePopupSheet: View {
    @Environment(\.dismiss) var dismiss; @State private var isCalibrating = false; @State private var calibrationProgress: CGFloat = 0.0
    var body: some View {
        ZStack {
            AppTheme.bgDark.ignoresSafeArea(); MeshGradientBackground()
            VStack(spacing: 25) {
                Capsule().fill(Color.gray).frame(width: 40, height: 5).padding(.top); Image(systemName: "bolt.heart.fill").font(.system(size: 60)).foregroundColor(AppTheme.gold).shadow(color: AppTheme.gold, radius: 15).padding(.top, 20); Text("МЫШЕЧНЫЙ ТОНУС").font(.title2.bold()).foregroundColor(.white)
                Text("Одни шаги не спасут твою оболочку. 🧬\n\nШаги прокачивают мотор (сердце) и гоняют кровь по магистралям, но гидравлика твоих суставов и плотность мышечных волокон требуют иного подхода.\n\nДля поддержания идеального тонуса необходима **силовая калибровка** (гантели/турники) и **глубокий стретчинг** (растяжка). Иначе твои импланты начнут 'ржаветь'.").font(.subheadline).foregroundColor(.gray).multilineTextAlignment(.center).lineSpacing(5).padding(.horizontal, 20)
                VStack(alignment: .leading, spacing: 10) { Text("ПРОТОКОЛ НЕЙРО-КАЛИБРОВКИ").font(.headline.bold()).foregroundColor(AppTheme.gold); Text("Запусти быструю 3-минутную разминку суставов, чтобы разогнать синовиальную жидкость.").font(.caption).foregroundColor(.white)
                    if isCalibrating { VStack(spacing: 5) { HStack { Text("Калибровка шарниров...").font(.caption2.bold()).foregroundColor(AppTheme.gold); Spacer(); Text("\(Int(calibrationProgress * 100))%").font(.caption2).foregroundColor(.gray) }; ZStack(alignment: .leading) { Capsule().fill(Color.white.opacity(0.1)).frame(height: 10); Capsule().fill(AppTheme.epicGradient).frame(width: 300 * calibrationProgress, height: 10).shadow(color: AppTheme.gold, radius: 5) } }.padding(.top, 10) } else { Button(action: { triggerImpact(style: .heavy); withAnimation { isCalibrating = true }; Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in if calibrationProgress >= 1.0 { timer.invalidate(); triggerNotification(type: .success); DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { dismiss() } } else { withAnimation { calibrationProgress += 0.02 } } } }) { Text("ЗАПУСТИТЬ КАЛИБРОВКУ ⚙️").font(.headline.bold()).padding().frame(maxWidth: .infinity).background(AppTheme.gold.opacity(0.2)).foregroundColor(AppTheme.gold).cornerRadius(15).overlay(RoundedRectangle(cornerRadius: 15).stroke(AppTheme.gold, lineWidth: 1)) }.buttonStyle(BouncyButton()).padding(.top, 10) }
                }.padding().frame(maxWidth: .infinity, alignment: .leading).background(.ultraThinMaterial).cornerRadius(20).padding(.horizontal)
                Spacer()
            }
        }
    }
}

struct HydrationPopupSheet: View {
    @Environment(\.dismiss) var dismiss; @State private var pulse = false; @State private var isDetailsExpanded = false
    var body: some View {
        ZStack {
            AppTheme.bgDark.ignoresSafeArea(); MeshGradientBackground(); FloatingParticlesView()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 25) {
                    Capsule().fill(Color.gray).frame(width: 40, height: 5).padding(.top, 15)
                    ZStack { Circle().fill(AppTheme.accentRed.opacity(0.2)).frame(width: 100, height: 100); Image(systemName: "drop.triangle.fill").font(.system(size: 50)).foregroundColor(AppTheme.accentRed).offset(y: pulse ? 5 : -5).animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse) }.padding(.top, 10)
                    Text("КРИТИЧЕСКИЙ СБОЙ").font(.title3.bold()).foregroundColor(AppTheme.accentRed); Text("Жидкость: LOW ⚠️").font(.system(size: 26, weight: .black, design: .monospaced)).foregroundColor(.white)
                    VStack(alignment: .leading, spacing: 10) { Button(action: { triggerImpact(style: .light); withAnimation(.spring()) { isDetailsExpanded.toggle() } }) { HStack { Text("РАСШИФРОВКА УГРОЗЫ").font(.headline).foregroundColor(.white); Spacer(); Image(systemName: isDetailsExpanded ? "chevron.up" : "chevron.down").foregroundColor(AppTheme.accentRed) } }.buttonStyle(BouncyButton())
                        if isDetailsExpanded { Text("H2O — это главная охлаждающая жидкость твоего био-двигателя. 💧\n\nПри падении уровня воды кровь густеет, мотору (сердцу) становится тяжелее качать кислород, а нейронные связи замедляются. Шаги сжигают воду как бензин. Если не заправить бак сейчас — система войдет в режим аварийного отключения.").font(.subheadline).foregroundColor(.gray).multilineTextAlignment(.leading).lineSpacing(4).fixedSize(horizontal: false, vertical: true).padding(.top, 5).transition(.opacity.combined(with: .move(edge: .top))) }
                    }.padding().background(Color.white.opacity(0.05)).cornerRadius(20).overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.glassGradient, lineWidth: 1)).padding(.horizontal)
                    VStack(alignment: .leading, spacing: 12) { HStack { Image(systemName: "camera.macro").foregroundColor(AppTheme.accentCyan).font(.title2); Text("КОНТРОЛЬ ЗАПРАВКИ").font(.headline.bold()).foregroundColor(.white) }; Text("Отслеживай водный баланс и калории еды по одному фото с помощью ИИ-модуля.").font(.caption).foregroundColor(.gray).fixedSize(horizontal: false, vertical: true)
                        Button(action: { triggerImpact(style: .heavy) }) { HStack { Text("СКАЧАТЬ ИИ-ТРЕКЕР"); Image(systemName: "arrow.up.right.square") }.font(.headline.bold()).padding().frame(maxWidth: .infinity).background(AppTheme.accentBlue).foregroundColor(.white).cornerRadius(15).shadow(color: AppTheme.accentBlue.opacity(0.5), radius: 10) }.buttonStyle(BouncyButton()).padding(.top, 5)
                    }.padding().frame(maxWidth: .infinity, alignment: .leading).background(.ultraThinMaterial).cornerRadius(20).overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.glassGradient, lineWidth: 1)).padding(.horizontal)
                    Spacer(minLength: 20)
                    Button("ЗАКРЫТЬ ОТЧЕТ") { dismiss() }.font(.headline.bold()).padding().frame(maxWidth: .infinity).background(Color.white.opacity(0.1)).foregroundColor(.white).cornerRadius(15).padding(.horizontal).padding(.bottom, 30)
                }
            }
        }.onAppear { pulse = true }
    }
}
