import SwiftUI

struct WeatherCyberSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var pulse = false
    @State private var weatherCondition: CyberWeatherState = .allCases.randomElement()!
    @State private var temp = Int.random(in: -15...35)
    @State private var wind = Double.random(in: 0.5...15.0)

    @State private var forecast: [DailyWeatherModel] = []
    @State private var selectedDayWeather: DailyWeatherModel? = nil
    
    @State private var sportToCheck: ActivityType? = nil
    @State private var isScanning = false

    var themeColor: Color { switch weatherCondition { case .clear: return AppTheme.gold; case .rain: return AppTheme.accentBlue; case .snow: return AppTheme.accentCyan } }

    var body: some View {
        ZStack {
            AppTheme.bgDark.ignoresSafeArea(); MeshGradientBackground()
            if weatherCondition == .rain { CyberpunkRainView() } else if weatherCondition == .snow { CyberSnowView() } else { FloatingParticlesView() }

            ScrollView(showsIndicators: false) {
                VStack(spacing: 25) {
                    Capsule().fill(Color.gray.opacity(0.5)).frame(width: 40, height: 5).padding(.top)

                    HStack {
                        VStack(alignment: .leading, spacing: 0) { Text("МЕТЕО-РАДАР").font(.system(size: 14, weight: .bold)).foregroundColor(.gray); Text("СИСТЕМА 🛰").font(.system(size: 36, weight: .black, design: .rounded)).foregroundColor(themeColor).shadow(color: themeColor, radius: pulse ? 15 : 5).scaleEffect(pulse ? 1.02 : 0.98) }
                        Spacer()
                        Image(systemName: "sensor.tag.radiowaves.forward").font(.title).foregroundColor(themeColor).symbolEffect(.variableColor, isActive: pulse)
                    }.padding(.horizontal, 25)

                    HStack(spacing: 20) {
                        ZStack { Circle().fill(themeColor.opacity(0.2)).frame(width: 80, height: 80); Circle().stroke(themeColor.opacity(0.5), lineWidth: 2).frame(width: 90, height: 90).rotationEffect(.degrees(pulse ? 360 : 0)).animation(.linear(duration: 10).repeatForever(autoreverses: false), value: pulse); Image(systemName: weatherCondition == .clear ? "sun.max.fill" : (weatherCondition == .rain ? "cloud.heavyrain.fill" : "snowflake")).font(.system(size: 40)).foregroundColor(themeColor).shadow(color: themeColor, radius: 10) }
                        VStack(alignment: .leading, spacing: 5) { Text(weatherCondition.rawValue).font(.title3.bold()).foregroundColor(.white); HStack(alignment: .top, spacing: 2) { Text("\(temp)").font(.system(size: 55, weight: .heavy, design: .rounded)).foregroundColor(.white); Text("°C").font(.title2.bold()).foregroundColor(themeColor).padding(.top, 8) } }
                        Spacer()
                    }.padding(20).background(.ultraThinMaterial).cornerRadius(30).overlay(RoundedRectangle(cornerRadius: 30).stroke(LinearGradient(colors: [themeColor, .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)).shadow(color: themeColor.opacity(0.15), radius: 20).padding(.horizontal, 20)

                    HStack(spacing: 15) { WeatherMiniStat(icon: "wind", title: "Ветер", value: String(format: "%.1f м/с", wind), color: AppTheme.accentCyan); WeatherMiniStat(icon: "humidity", title: "Влага", value: "\(Int.random(in: 40...90))%", color: AppTheme.accentBlue); WeatherMiniStat(icon: "barometer", title: "Давл.", value: "750 мм", color: AppTheme.accentPurple) }.padding(.horizontal, 20)

                    VStack(alignment: .leading) {
                        Text("ПРОГНОЗ НА 10 ДНЕЙ 🗓").font(.caption.bold()).foregroundColor(.gray).padding(.horizontal, 25)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(forecast) { day in Button(action: { triggerImpact(style: .light); withAnimation(.spring()) { selectedDayWeather = day } }) { VStack(spacing: 12) { Text("ДЕНЬ \(day.dayIndex+1)").font(.system(size: 10, weight: .black)).foregroundColor(.gray); Image(systemName: day.condition == .clear ? "sun.max.fill" : (day.condition == .rain ? "cloud.rain.fill" : "snowflake")).font(.title2).foregroundColor(day.condition == .clear ? AppTheme.gold : (day.condition == .rain ? AppTheme.accentBlue : AppTheme.accentCyan)); Text("\(day.temp)°").font(.headline.bold()).foregroundColor(.white) }.frame(width: 75, height: 110).background(.ultraThinMaterial).cornerRadius(20).overlay(RoundedRectangle(cornerRadius: 20).stroke(AnyShapeStyle(AppTheme.glassGradient), lineWidth: 1)) }.buttonStyle(BouncyButton()) }
                            }.padding(.horizontal, 20).padding(.vertical, 5)
                        }
                    }

                    VStack(alignment: .leading, spacing: 15) {
                        HStack { Image(systemName: "cpu").font(.title2).foregroundColor(AppTheme.neonGreen).symbolEffect(.pulse); VStack(alignment: .leading) { Text("ИИ КРОСС-АНАЛИЗ").font(.headline.bold()).foregroundColor(.white); Text("Выберите модуль для сканирования погоды").font(.caption).foregroundColor(.gray) } }.padding(.horizontal, 25)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                            ForEach(ActivityType.allCases, id: \.self) { sport in
                                Button(action: { triggerImpact(style: .heavy); sportToCheck = sport; isScanning = false; DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) { isScanning = true } } }) { HStack { Image(systemName: sport.icon).font(.title).foregroundColor(.white).frame(width: 30); Spacer(); VStack(alignment: .trailing) { Text("Модуль").font(.system(size: 8, weight: .bold)).foregroundColor(.gray); Text(sport.rawValue).font(.subheadline.bold()).foregroundColor(.white) } }.padding(15).background(LinearGradient(colors: [Color.white.opacity(0.1), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)).background(.ultraThinMaterial).cornerRadius(20).overlay(RoundedRectangle(cornerRadius: 20).stroke(AnyShapeStyle(AppTheme.glassGradient), lineWidth: 1)) }.buttonStyle(BouncyButton())
                            }
                        }.padding(.horizontal, 20)
                    }; Spacer(minLength: 50)
                }
            }
            
            if let day = selectedDayWeather {
                ZStack {
                    Color.black.opacity(0.85).ignoresSafeArea().onTapGesture { withAnimation { selectedDayWeather = nil } }
                    VStack(spacing: 20) {
                        HStack { Text("Анализ: День \(day.dayIndex + 1)").font(.title2.bold()).foregroundColor(.white); Spacer(); Button(action: { withAnimation { selectedDayWeather = nil } }) { Image(systemName: "xmark.circle.fill").font(.title2).foregroundColor(.gray) } }
                        let dayColor = day.condition == .clear ? AppTheme.gold : (day.condition == .rain ? AppTheme.accentBlue : AppTheme.accentCyan)
                        HStack(spacing: 20) { Image(systemName: day.condition == .clear ? "sun.max.fill" : (day.condition == .rain ? "cloud.rain.fill" : "snowflake")).font(.system(size: 50)).foregroundColor(dayColor).shadow(color: dayColor, radius: 10); VStack(alignment: .leading, spacing: 0) { Text(day.condition.rawValue).font(.title3.bold()).foregroundColor(.white); Text("\(day.temp)°C").font(.system(size: 35, weight: .heavy)).foregroundColor(dayColor) }; Spacer() }.padding(20).background(Color.white.opacity(0.05)).cornerRadius(20)
                        let advice = getBestActivityAdvice(for: day)
                        VStack(alignment: .leading, spacing: 10) { Text("СИСТЕМНАЯ РЕКОМЕНДАЦИЯ").font(.system(size: 10, weight: .bold)).foregroundColor(.gray); HStack(spacing: 15) { Image(systemName: advice.activity.icon).font(.largeTitle).foregroundColor(advice.color); VStack(alignment: .leading) { Text("Приоритет: \(advice.activity.rawValue)").font(.headline.bold()).foregroundColor(advice.color); Text(advice.text).font(.caption).foregroundColor(.gray) } }.padding(15).background(advice.color.opacity(0.1)).cornerRadius(15).overlay(RoundedRectangle(cornerRadius: 15).stroke(advice.color.opacity(0.3), lineWidth: 1)) }
                    }.padding(25).background(AppTheme.bgDark).cornerRadius(30).overlay(RoundedRectangle(cornerRadius: 30).stroke(AnyShapeStyle(AppTheme.glassGradient), lineWidth: 1)).padding(20).transition(.scale.combined(with: .opacity)).zIndex(100)
                }
            }
            
            if let sport = sportToCheck {
                let evaluation = evaluateSport(sport)
                ZStack {
                    Color.black.opacity(0.9).ignoresSafeArea().onTapGesture { withAnimation { sportToCheck = nil; isScanning = false } }
                    VStack(spacing: 20) {
                        HStack { Image(systemName: "cpu").foregroundColor(evaluation.status.color); Text("АНАЛИЗ: \(sport.rawValue.uppercased())").font(.headline.bold()).foregroundColor(.white); Spacer(); Button(action: { withAnimation { sportToCheck = nil; isScanning = false } }) { Image(systemName: "xmark.circle.fill").font(.title2).foregroundColor(.gray) } }
                        ZStack { Circle().fill(evaluation.status.color.opacity(0.1)).frame(width: 100, height: 100); Image(systemName: sport.icon).font(.system(size: 50)).foregroundColor(evaluation.status.color).shadow(color: evaluation.status.color, radius: 10); Rectangle().fill(LinearGradient(colors: [.clear, evaluation.status.color, .clear], startPoint: .leading, endPoint: .trailing)).frame(height: 2).offset(y: isScanning ? 40 : -40).opacity(0.8) }.frame(height: 100).clipped()
                        Text(evaluation.status.title).font(.system(size: 24, weight: .black, design: .rounded)).foregroundColor(evaluation.status.color).shadow(color: evaluation.status.color.opacity(0.5), radius: 5)
                        Text(evaluation.message).font(.subheadline).foregroundColor(.white).multilineTextAlignment(.center).lineSpacing(4).padding(.horizontal)
                        VStack(alignment: .leading, spacing: 10) { Text("ЭКИПИРОВКА:").font(.system(size: 10, weight: .black)).foregroundColor(.gray); ScrollView(.horizontal, showsIndicators: false) { HStack { ForEach(evaluation.gear, id: \.self) { item in Text(item).font(.caption2.bold()).padding(.horizontal, 10).padding(.vertical, 6).background(Color.white.opacity(0.1)).foregroundColor(.white).cornerRadius(8).overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.2), lineWidth: 1)) } } } }.padding(.top, 5).frame(maxWidth: .infinity, alignment: .leading)
                        if let alt = evaluation.alternative { VStack(alignment: .leading, spacing: 8) { Text("АЛЬТЕРНАТИВНЫЙ ПРОТОКОЛ").font(.system(size: 10, weight: .black)).foregroundColor(.gray); HStack { Image(systemName: alt.icon).font(.title2).foregroundColor(AppTheme.neonGreen); Text("Рекомендуется переключиться на: \(alt.rawValue)").font(.caption.bold()).foregroundColor(.white) }.padding(12).frame(maxWidth: .infinity, alignment: .leading).background(AppTheme.neonGreen.opacity(0.1)).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.neonGreen.opacity(0.3), lineWidth: 1)) } }
                        Button("ПРОТОКОЛ ПРИНЯТ") { triggerImpact(); withAnimation { sportToCheck = nil; isScanning = false } }.font(.headline.bold()).padding().frame(maxWidth: .infinity).background(evaluation.status.color.opacity(0.2)).foregroundColor(evaluation.status.color).cornerRadius(15).overlay(RoundedRectangle(cornerRadius: 15).stroke(evaluation.status.color, lineWidth: 1.5)).padding(.top, 10)
                    }.padding(25).background(AppTheme.bgDark).cornerRadius(30).overlay(RoundedRectangle(cornerRadius: 30).stroke(evaluation.status.color.opacity(0.5), lineWidth: 2)).shadow(color: evaluation.status.color.opacity(0.2), radius: 30).padding(20).transition(.scale.combined(with: .opacity)).zIndex(150)
                }
            }
        }.onAppear { withAnimation(.easeInOut(duration: 1.5).repeatForever()) { pulse = true }; if forecast.isEmpty { var newForecast: [DailyWeatherModel] = []; for i in 0..<10 { let c = CyberWeatherState.allCases.randomElement()!; newForecast.append(DailyWeatherModel(dayIndex: i, condition: c, temp: temp + Int.random(in: -8...8), wind: Double.random(in: 1.0...12.0), humidity: Int.random(in: 40...90))) }; forecast = newForecast } }
    }

    struct WeatherMiniStat: View {
        let icon: String; let title: String; let value: String; let color: Color
        var body: some View { VStack(spacing: 5) { Image(systemName: icon).font(.title3).foregroundColor(color); Text(value).font(.headline.bold()).foregroundColor(.white); Text(title).font(.caption2).foregroundColor(.gray) }.frame(maxWidth: .infinity).padding(.vertical, 12).background(.ultraThinMaterial).cornerRadius(20).overlay(RoundedRectangle(cornerRadius: 20).stroke(AnyShapeStyle(AppTheme.glassGradient), lineWidth: 1)) }
    }

    func getBestActivityAdvice(for day: DailyWeatherModel) -> (activity: ActivityType, text: String, color: Color) {
        switch day.condition { case .clear: if day.temp > 25 { return (.ride, "Оптимальный теплоотвод. Разгоняйте байк для естественного охлаждения систем.", AppTheme.neonGreen) } else { return (.run, "Синхронизация среды 100%. Идеальное сцепление с асфальтом. Время обновить рекорды.", AppTheme.neonGreen) }; case .rain: return (.walk, "Аномалия влажности. Включите термо-защиту и перейдите в режим энергосберегающей ходьбы.", AppTheme.accentBlue); case .snow: if day.wind > 5.0 { return (.walk, "Буря перегружает сенсоры. Двигайтесь медленно, берегите суставы от резких перепадов высот.", AppTheme.accentCyan) } else { return (.hike, "Атмосфера стабильна. Заснеженный рельеф отлично подходит для глубокого мышечного хайкинга.", AppTheme.accentCyan) } }
    }
    
    func evaluateSport(_ sport: ActivityType) -> SportSuitabilityCheck {
        var status: WeatherSuitability = .perfect; var msg = ""; var alt: ActivityType? = nil; var gear: [String] = []
        switch sport {
        case .walk: if weatherCondition == .rain { status = .acceptable; msg = "Сенсоры фиксируют влажность. Коэффициент скольжения увеличен."; gear = ["Водоотталкивающий плащ", "Зонт с подсветкой"] } else if weatherCondition == .snow && wind > 7.0 { status = .bad; msg = "Критическая ветровая нагрузка."; gear = ["Термо-щит (Куртка)", "Визор от снега"] } else { status = .perfect; msg = "Условия оптимальны."; gear = ["Легкие кроссовки", "Плеер с Synthwave"] }
        case .run: if weatherCondition == .rain { status = .bad; alt = .walk; msg = "Асфальт нестабилен. Шанс микротравм превышает 80%."; gear = ["Ветровка", "Кроссовки с агрессивным протектором"] } else if temp > 28 { status = .acceptable; alt = .ride; msg = "Ядро перегревается. Высокий пульс гарантирован."; gear = ["Гидратор", "Кепка"] } else { status = .perfect; msg = "Биоритмы и погода в полной синхронизации."; gear = ["Карбоновые кроссовки", "Датчик ЧСС"] }
        case .hike: if weatherCondition == .rain { status = .bad; alt = .walk; msg = "Грунтовые тропы размыты. Риск оползней."; gear = ["Аварийный маячок", "Непромокаемый костюм"] } else { status = .perfect; msg = "Ландшафт просканирован, почва сухая."; gear = ["Рюкзак", "GPS-Навигатор"] }
        case .ride: if weatherCondition == .rain || weatherCondition == .snow { status = .bad; alt = .walk; msg = "Сцепление покрышек близко к нулю. Модуль безопасности запрещает выезд."; gear = ["Грязевая резина", "Шлем"] } else { status = .perfect; msg = "Магистрали свободны. Разгоняйте свой транспорт!"; gear = ["Облегающий костюм", "Смазка для цепи"] }
        }
        if status == .bad && alt == nil { alt = .walk }
        return SportSuitabilityCheck(status: status, message: msg, gear: gear, alternative: alt)
    }
}
