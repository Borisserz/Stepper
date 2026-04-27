import SwiftUI
import MapKit
import Combine

struct GPSTabView: View {
    @EnvironmentObject var routeManager: RouteManager
    @Environment(HealthKitManager.self) private var health
    @StateObject private var locManager = LocationManager()
    
    @State private var sway = false; @State private var pulse = false; @State private var reflection = -1.0
    @State private var points = 1250; @State private var activeActivity: ActivityType = .walk
    @State private var caloriesBurned: Double = 0.0; @State private var currentPace = 0.0; @State private var currentBPM = 80
    @State private var comboMultiplier = 1.0; @State private var isAutoPaused = false
    
    @State private var isAnomalyActive = false; @State private var anomalyTimer = 0; @State private var minedCrypto = 0.0; @State private var radarSweep = false
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic); @State private var isSatelliteMode = false
    @State private var showLeague = false
    @State private var isCreatingRoute = false; @State private var showRoutePrompt = false; @State private var showActiveRouteWarning = false
    
    @State private var routePoints: [CLLocationCoordinate2D] = []
    @State private var calculatedRoute: MKRoute? = nil
    @State private var showStartRouteSheet = false; @State private var showCompletionSheet = false
    
    @State private var coachMessage = "Системы в норме 🟢"; @State private var userLevel = 1; @State private var showLevelUp = false
    @State private var weatherCondition = "Синхронизация 📡"; @State private var ghostTaunt = "Догоняй! 👻"
    
    @State private var scanlineOffset: CGFloat = -1000
    @State private var isGlitching = false
    
    @State private var showWeatherSheet = false
    @State private var showNeuralCore = false
    @State private var showRecordSheet = false

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            AppTheme.bgDark.ignoresSafeArea()
            if comboMultiplier >= 2.0 { RoundedRectangle(cornerRadius: 30).stroke(AppTheme.gold, lineWidth: pulse ? 8 : 2).blur(radius: 5).ignoresSafeArea().opacity(0.8).animation(.easeInOut(duration: 0.5), value: pulse) }
            
            mapLayer
            FloatingParticlesView()
            if routeManager.isTracking { CyberpunkRainView() }
            if isAnomalyActive { Rectangle().stroke(AppTheme.accentRed, lineWidth: pulse ? 15 : 5).blur(radius: 20).ignoresSafeArea().allowsHitTesting(false) }
            
            Rectangle().fill(LinearGradient(colors: [.clear, AppTheme.accentCyan.opacity(0.15), .clear], startPoint: .top, endPoint: .bottom)).frame(height: 40).offset(y: scanlineOffset).allowsHitTesting(false)
            
            uiOverlay
            
            if let toast = routeManager.globalToastMessage {
                VStack { CyberToast(message: toast).onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) { withAnimation { routeManager.globalToastMessage = nil } } }; Spacer() }.zIndex(999)
            }
            
            if showLevelUp {
                ZStack {
                    Color.black.opacity(0.8).ignoresSafeArea()
                    VStack(spacing: 20) {
                        Image(systemName: "arrow.up.circle.fill").font(.system(size: 100)).symbolRenderingMode(.multicolor).shadow(color: AppTheme.gold, radius: 20)
                        Text("LEVEL UP!").font(.system(size: 50, weight: .black, design: .rounded)).foregroundStyle(AppTheme.epicGradient).shadow(color: AppTheme.accentRed, radius: 10)
                        Text("Твой уровень: \(userLevel)").font(.title2.bold()).foregroundColor(.white)
                        Button("Забрать награду 🔥") { triggerImpact(style: .heavy); withAnimation(.spring()) { showLevelUp = false }; points += 500 }.padding().background(AppTheme.gold).foregroundColor(.black).cornerRadius(20).padding(.top, 20)
                    }
                }.transition(.scale.combined(with: .opacity)).zIndex(100)
            }
            
            if routeManager.incomingWarPopup {
                ZStack {
                    Color.black.opacity(0.9).ignoresSafeArea()
                    VStack(spacing: 25) {
                        Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 80)).symbolRenderingMode(.multicolor).shadow(color: .red, radius: 20).scaleEffect(pulse ? 1.1 : 0.9).animation(.easeInOut(duration: 0.5).repeatForever(), value: pulse)
                        Text("ВЫЗОВ НА ПОЕДИНОК! ⚔️").font(.system(size: 30, weight: .black, design: .rounded)).foregroundColor(.white).multilineTextAlignment(.center)
                        VStack(spacing: 10) { Text("Клуб Mountain Goats бросает вызов!").font(.headline).foregroundColor(.gray); Text("Ставка: 3000 поинтов 💰").font(.title3.bold()).foregroundColor(AppTheme.gold) }.padding().background(.ultraThinMaterial).cornerRadius(20)
                        HStack(spacing: 20) {
                            Button("Отклонить") { withAnimation { routeManager.incomingWarPopup = false } }.padding().frame(maxWidth: .infinity).background(Color.white.opacity(0.1)).foregroundColor(.white).cornerRadius(15)
                            Button("Принять Битву! 🔥") { triggerImpact(style: .heavy); withAnimation { routeManager.incomingWarPopup = false }; triggerNotification(type: .success) }.padding().frame(maxWidth: .infinity).background(AppTheme.accentRed).foregroundColor(.white).cornerRadius(15).shadow(color: AppTheme.accentRed, radius: 10)
                        }
                    }.padding(30)
                }.transition(.opacity).zIndex(200)
            }
        }
        .onAppear {
            locManager.requestAuth()
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) { sway = true; pulse = true }
            withAnimation(.easeOut(duration: 3).repeatForever(autoreverses: false)) { radarSweep = true }
            withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) { scanlineOffset = UIScreen.main.bounds.height + 200 }
            Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { _ in if Bool.random() { withAnimation(.spring(response: 0.1, dampingFraction: 0.2)) { isGlitching = true }; DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { withAnimation { isGlitching = false } } } }
            DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) { if routeManager.myOwnedClub != nil { withAnimation { routeManager.incomingWarPopup = true } } }
        }
        .onReceive(timer) { tick in
            updateTrackingLogic()
            // Pull a fresh heart-rate sample every ~5s while tracking so
            // the BPM widget reflects what Apple Watch / HealthKit just
            // wrote, rather than a 1-time snapshot from app launch.
            if routeManager.isTracking,
               Int(tick.timeIntervalSinceReferenceDate) % 5 == 0 {
                Task { await health.refreshAll() }
            }
        }
        .alert("Маршрут активен 🛑", isPresented: $showActiveRouteWarning) { Button("Ок", role: .cancel) { } } message: { Text("Заверши текущую пробежку.") }
        .alert("Создать маршрут? 🔥", isPresented: $showRoutePrompt) { Button("Да") { withAnimation { routeManager.previewRoute = nil; isCreatingRoute = true; routePoints.removeAll(); calculatedRoute = nil } }; Button("Отмена", role: .cancel) { } } message: { Text("Поставь 2 точки.") }
        .sheet(isPresented: $showStartRouteSheet) { StartRouteSheet(points: $routePoints, calculatedRoute: calculatedRoute, isCreatingRoute: $isCreatingRoute) }
        .sheet(isPresented: $routeManager.showLiveTracking) { LiveTrackingSheet() }
        .sheet(isPresented: $showLeague) { LeagueSheet(points: $points) }
        .sheet(isPresented: $showWeatherSheet) { WeatherCyberSheet() }
        .fullScreenCover(isPresented: $showNeuralCore) { AICoreHubView() }
        .fullScreenCover(isPresented: $routeManager.isHubPresented) { RoutesAndChallengesHub() }
        .sheet(isPresented: $showCompletionSheet, onDismiss: { resetAfterCompletion() }) { RouteCompletionSheet(calories: caloriesBurned, combo: comboMultiplier) }
        .fullScreenCover(isPresented: $showRecordSheet) { RecordWorkoutView() }
    }
    
    @ViewBuilder private var mapLayer: some View {
        MapReader { proxy in
            Map(position: $cameraPosition, interactionModes: .all) {
                UserAnnotation()
                if routeManager.isTracking { Annotation("Radar", coordinate: locManager.location?.coordinate ?? CLLocationCoordinate2D(latitude: 53.9, longitude: 27.5)) { Circle().fill(RadialGradient(colors: [AppTheme.neonGreen.opacity(0.4), .clear], center: .center, startRadius: 0, endRadius: radarSweep ? 250 : 0)).frame(width: radarSweep ? 500 : 0, height: radarSweep ? 500 : 0).opacity(radarSweep ? 0 : 1) } }
                ForEach(routePoints.indices, id: \.self) { i in Annotation("", coordinate: routePoints[i]) { ZStack { Circle().stroke(i == 0 ? AppTheme.neonGreen : AppTheme.accentRed, lineWidth: 2).frame(width: 40, height: 40).scaleEffect(pulse ? 1.5 : 0.5).opacity(pulse ? 0 : 1); Circle().fill(i == 0 ? AppTheme.neonGreen : AppTheme.accentRed).frame(width: 15, height: 15).shadow(color: .white, radius: 5) } } }
                if let route = calculatedRoute { MapPolyline(route).stroke(AppTheme.neonGreen, style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)) } else if routePoints.count == 2 { MapPolyline(coordinates: routePoints).stroke(AppTheme.neonGreen.opacity(0.8), style: StrokeStyle(lineWidth: 4, dash: [10, 5])) }
                if let preRoute = routeManager.previewRoute { MapPolyline(coordinates: preRoute.points).stroke(AppTheme.gold.opacity(0.3), style: StrokeStyle(lineWidth: 16, lineCap: .round, lineJoin: .round)); MapPolyline(coordinates: preRoute.points).stroke(AppTheme.gold, style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)); Annotation("Start", coordinate: preRoute.points.first ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)) { Circle().fill(AppTheme.neonGreen).frame(width: 15) }; Annotation("Finish", coordinate: preRoute.points.last ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)) { Circle().fill(AppTheme.accentRed).frame(width: 15) } }
                if let route = routeManager.activeRoute { MapPolyline(coordinates: route.points).stroke(AppTheme.accentBlue.opacity(0.3), style: StrokeStyle(lineWidth: 16, lineCap: .round, lineJoin: .round)); MapPolyline(coordinates: route.points).stroke(AppTheme.accentCyan, style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)); Annotation("Ghost", coordinate: interpolate(route.points, progress: routeManager.traveledProgress * 1.2)) { Image(systemName: "ghost.fill").foregroundColor(.white).opacity(0.8).shadow(color: .white, radius: 5) }; Annotation("You", coordinate: interpolate(route.points, progress: routeManager.traveledProgress)) { ZStack { Circle().stroke(AppTheme.accentCyan, style: StrokeStyle(lineWidth: 3, dash: [5, 5])).frame(width: 35, height: 35).rotationEffect(.degrees(pulse && !isAutoPaused ? 360 : 0)).animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: pulse).opacity(isAutoPaused ? 0.3 : 1); Circle().fill(AppTheme.accentRed).frame(width: 15).shadow(color: AppTheme.accentRed, radius: 15) } } }
            }.mapStyle(isSatelliteMode ? .imagery(elevation: .realistic) : .standard(elevation: .realistic, pointsOfInterest: .all)).mapControls { MapCompass(); MapPitchToggle() }.ignoresSafeArea().colorScheme(.dark).opacity(isCreatingRoute ? 0.7 : 1.0).onTapGesture { location in
                if isCreatingRoute, routePoints.count < 2 { if let coord = proxy.convert(location, from: .local) { triggerImpact(style: .light); routePoints.append(coord); if routePoints.count == 2 { calculateRealPath() } } }
            }
        }
    }
    
    private func calculateRealPath() {
        guard routePoints.count == 2 else { return }
        let request = MKDirections.Request(); request.source = MKMapItem(placemark: MKPlacemark(coordinate: routePoints[0])); request.destination = MKMapItem(placemark: MKPlacemark(coordinate: routePoints[1])); request.transportType = .walking
        withAnimation { coachMessage = "Прокладка маршрута... 🛰️" }
        MKDirections(request: request).calculate { resp, err in
            if let route = resp?.routes.first { withAnimation { self.calculatedRoute = route }; coachMessage = "Маршрут загружен 🟢" } else { coachMessage = "Ошибка сети. Прямой путь ⚠️" }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { showStartRouteSheet = true }
        }
    }
    
    @ViewBuilder private var uiOverlay: some View {
        VStack {
            HStack(spacing: 20) {
                HStack(spacing: 6) { Image(systemName: "figure.run").foregroundColor(routeManager.isTracking ? AppTheme.neonGreen : .gray); Text(String(format: "%.1f", routeManager.isTracking ? currentPace : 0.0)).font(.system(size: 16, weight: .bold, design: .monospaced)).foregroundColor(routeManager.isTracking ? .white : .gray); Text("km/h").font(.caption2).foregroundColor(.gray) }
                Divider().background(Color.gray).frame(height: 20)
                HStack(spacing: 6) { Image(systemName: "heart.fill").foregroundColor(routeManager.isTracking ? .pink : .gray).scaleEffect(pulse ? 1.2 : 0.9); Text(routeManager.isTracking && currentBPM > 0 ? "\(currentBPM)" : "—").font(.system(size: 16, weight: .bold, design: .monospaced)).foregroundColor(routeManager.isTracking ? .white : .gray) }
            }.padding(.horizontal, 25).padding(.vertical, 12).background(.ultraThinMaterial).clipShape(Capsule()).overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1)).shadow(color: AppTheme.neonGreen.opacity(pulse && routeManager.isTracking ? 0.4 : 0.0), radius: pulse ? 15 : 5).padding(.top, 10).transition(.move(edge: .top).combined(with: .opacity)).opacity(routeManager.isTracking ? 1.0 : 0.6)
            
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("GPS 🔥").font(.system(size: 36, weight: .black, design: .rounded)).foregroundColor(isGlitching ? AppTheme.accentRed : .white).overlay(LinearGradient(colors: [.clear, .white.opacity(0.8), .clear], startPoint: .topLeading, endPoint: .bottomTrailing).offset(x: reflection * 150).mask(Text("GPS 🔥").font(.system(size: 36, weight: .black, design: .rounded)))).shadow(color: AppTheme.accentBlue, radius: pulse ? 15 : 5).scaleEffect(pulse ? 1.05 : 0.95).rotationEffect(.degrees(sway ? 2 : -2)).offset(x: isGlitching ? CGFloat.random(in: -4...4) : 0, y: isGlitching ? CGFloat.random(in: -2...2) : 0)
                    HStack {
                        Button(action: { triggerImpact(); isSatelliteMode.toggle() }) { Image(systemName: isSatelliteMode ? "map.fill" : "globe.americas.fill").font(.title3).foregroundColor(.white).padding(10).background(.ultraThinMaterial).clipShape(Circle()).overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1)).shadow(color: AppTheme.accentCyan.opacity(0.5), radius: 5) }.buttonStyle(BouncyButton())
                        Button(action: { triggerImpact(); let center = locManager.location?.coordinate ?? CLLocationCoordinate2D(latitude: 53.9, longitude: 27.5); withAnimation { cameraPosition = .camera(MapCamera(centerCoordinate: center, distance: 800, heading: 0, pitch: 0)) } }) { Image(systemName: "location.fill").font(.title3).foregroundColor(.white).padding(10).background(.ultraThinMaterial).clipShape(Circle()).overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1)) }.buttonStyle(BouncyButton())
                        Button(action: { triggerImpact(style: .heavy); showRecordSheet = true }) {
                            HStack(spacing: 6) {
                                Circle().fill(AppTheme.accentRed).frame(width: 10, height: 10).shadow(color: AppTheme.accentRed, radius: 6).opacity(pulse ? 1.0 : 0.5)
                                Text("REC").font(.system(size: 13, weight: .heavy, design: .rounded)).foregroundColor(.white)
                            }
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(AppTheme.accentRed.opacity(0.7), lineWidth: 1))
                            .shadow(color: AppTheme.accentRed.opacity(0.5), radius: 6)
                        }.buttonStyle(BouncyButton()).accessibilityLabel(Text("workout.record.title"))
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 5) {
                    Button(action: { triggerImpact(); showLeague = true }) { HStack { Image(systemName: "star.fill").foregroundColor(AppTheme.gold); Text("\(points) pts").font(.headline.bold()).foregroundColor(.white) }.padding(10).background(.ultraThinMaterial).cornerRadius(15).overlay(RoundedRectangle(cornerRadius: 15).stroke(AppTheme.gold.opacity(0.5), lineWidth: 2)).shadow(color: AppTheme.gold.opacity(pulse ? 0.6 : 0.2), radius: 10) }.buttonStyle(BouncyButton())
                    Text("LVL \(userLevel)").font(.caption.bold()).padding(.horizontal, 10).padding(.vertical, 4).background(AppTheme.accentPurple).cornerRadius(10).foregroundColor(.white).shadow(color: AppTheme.accentPurple, radius: 5)
                }
            }.padding(.horizontal).padding(.top, 10)
            
            if isCreatingRoute { Text(routePoints.count == 0 ? "Поставь точку старта 📍" : "Поставь точку финиша 🏁").font(.headline.bold()).foregroundColor(.black).padding().background(AppTheme.neonGreen).cornerRadius(20).shadow(color: AppTheme.neonGreen, radius: 15).padding(.top, 10).transition(.move(edge: .top)) }
            
            if routeManager.activeRoute != nil {
                Button(action: { triggerImpact(style: .rigid); resetAfterCompletion() }) { HStack { Image(systemName: "stop.circle.fill"); Text("Завершить Маршрут 🛑") }.font(.headline.bold()).foregroundColor(.white).padding(.horizontal, 20).padding(.vertical, 10).background(Color.red.opacity(0.8)).cornerRadius(20).shadow(color: .red, radius: 10) }.buttonStyle(BouncyButton()).padding(.top, 10).transition(.scale)
            } else if let pre = routeManager.previewRoute {
                VStack(spacing: 10) {
                    Button(action: { triggerImpact(style: .heavy); routeManager.activeRoute = pre; routeManager.previewRoute = nil; routeManager.isTracking = true; routeManager.traveledProgress = 0.0 }) { Text("Начать: \(pre.name) 🚀").font(.title2.bold()).padding(.horizontal, 30).padding(.vertical, 15).background(AppTheme.accentBlue).foregroundColor(.white).cornerRadius(20).shadow(color: AppTheme.accentBlue, radius: 10) }.buttonStyle(BouncyButton())
                    Button(action: { triggerImpact(); routeManager.previewRoute = nil }) { HStack { Image(systemName: "xmark.circle.fill"); Text("Отменить предпросмотр") }.font(.caption.bold()).foregroundColor(.white).padding(.horizontal, 15).padding(.vertical, 8).background(Color.gray.opacity(0.8)).cornerRadius(20) }.buttonStyle(BouncyButton())
                }.padding(.top, 10).transition(.scale)
            }
            Spacer()
            
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 15) {
                        VStack(alignment: .leading, spacing: 2) { Text("ПУЛЬС").font(.system(size: 8, weight: .bold)).foregroundColor(.pink); HStack(spacing: 2) { Text(routeManager.isTracking && currentBPM > 0 ? "\(currentBPM)" : "—").font(.system(size: 18, weight: .heavy, design: .monospaced)).foregroundColor(routeManager.isTracking ? .white : .gray); Image(systemName: "heart.fill").foregroundColor(.pink).font(.caption2).scaleEffect(pulse ? 1.2 : 0.9) } }
                        VStack(alignment: .leading, spacing: 2) { Text("ТЕМП").font(.system(size: 8, weight: .bold)).foregroundColor(AppTheme.accentCyan); Text(String(format: "%.1f", routeManager.isTracking ? currentPace : 0.0)).font(.system(size: 18, weight: .heavy, design: .monospaced)).foregroundColor(routeManager.isTracking ? .white : .gray) }
                    }
                    HStack(spacing: 4) { Image(systemName: "bitcoinsign.circle.fill").foregroundColor(AppTheme.gold).font(.system(size: 10)); Text("+\(String(format: "%.2f", minedCrypto))").font(.system(size: 10, weight: .bold)).foregroundColor(AppTheme.gold) }
                    Text(routeManager.isTracking ? ghostTaunt : "Ожидание...").font(.system(size: 9)).foregroundColor(.gray).italic().lineLimit(1).frame(width: 110, alignment: .leading)
                }.padding(10).background(.ultraThinMaterial).cornerRadius(15).overlay(RoundedRectangle(cornerRadius: 15).stroke(AppTheme.accentCyan.opacity(routeManager.isTracking ? 0.5 : 0.2), lineWidth: 1)).opacity(routeManager.isTracking ? 1.0 : 0.6)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 5) {
                    if !routeManager.isTracking && !isCreatingRoute && routeManager.previewRoute == nil {
                        VStack(alignment: .trailing, spacing: 5) {
                            Text("СВОЯ ТРОПА 📍").font(.system(size: 9, weight: .bold)).foregroundColor(.black).padding(.horizontal, 6).padding(.vertical, 4).background(AppTheme.neonGreen).cornerRadius(8).shadow(color: AppTheme.neonGreen, radius: 5).offset(y: sway ? -3 : 0)
                            Button(action: { triggerImpact(style: .heavy); if routeManager.activeRoute != nil { showActiveRouteWarning = true } else { showRoutePrompt = true } }) { Image(systemName: "plus.viewfinder").font(.title2).foregroundColor(AppTheme.neonGreen).padding(10).background(.ultraThinMaterial).clipShape(Circle()).overlay(Circle().stroke(AppTheme.neonGreen, lineWidth: 2)).shadow(color: AppTheme.neonGreen.opacity(0.5), radius: 10).rotationEffect(.degrees(sway ? 10 : -10)) }.buttonStyle(BouncyButton())
                        }.padding(.bottom, 5)
                    }
                    if routeManager.isTracking && comboMultiplier > 1.0 && !isAutoPaused { Text("x\(String(format: "%.1f", comboMultiplier)) 🔥").font(.system(size: 10, weight: .bold)).foregroundColor(AppTheme.gold).shadow(color: AppTheme.accentOrange, radius: 10).scaleEffect(pulse ? 1.1 : 0.9).transition(.scale) }
                    ZStack { Circle().stroke(Color.white.opacity(0.1), lineWidth: 4).frame(width: 55, height: 55); Circle().trim(from: 0, to: min(caloriesBurned / 500.0, 1.0)).stroke(AppTheme.fireGradient, style: StrokeStyle(lineWidth: 4, lineCap: .round)).rotationEffect(.degrees(-90)).frame(width: 55, height: 55).shadow(color: AppTheme.accentOrange, radius: 4); VStack(spacing: 0) { Text(String(format: "%.0f", caloriesBurned)).font(.system(size: 14, weight: .heavy, design: .monospaced)).foregroundColor(.white); Text("KCAL").font(.system(size: 7, weight: .bold)).foregroundColor(.gray) } }.padding(10).background(.ultraThinMaterial).cornerRadius(15).overlay(RoundedRectangle(cornerRadius: 15).stroke(AppTheme.glassGradient, lineWidth: 1)).shadow(color: AppTheme.accentRed.opacity(pulse ? 0.3 : 0.1), radius: 10).scaleEffect(pulse ? 1.02 : 0.98)
                }
            }.padding(.horizontal); Spacer().frame(height: 15)
            
            HStack(spacing: 10) {
                ForEach(ActivityType.allCases, id: \.self) { type in Button(action: { triggerImpact(); activeActivity = type; withAnimation { routeManager.isTracking = true; isAutoPaused = false; isAnomalyActive = false; currentPace = 0.0; currentBPM = 0; minedCrypto = 0 } }) { VStack { Image(systemName: type.icon).font(.title2); Text(type.rawValue).font(.caption2.bold()) }.foregroundColor(activeActivity == type ? .white : .gray).frame(maxWidth: .infinity).padding(.vertical, 12).background(activeActivity == type ? AppTheme.accentBlue : Color.white.opacity(0.1)).cornerRadius(15).shadow(color: activeActivity == type ? AppTheme.accentBlue.opacity(0.6) : .clear, radius: 10) }.buttonStyle(BouncyButton()) }
            }.padding(.horizontal).background(.ultraThinMaterial).cornerRadius(25).padding(.horizontal)
            
            HStack(spacing: 8) {
                BottomActionButton(title: "Track", icon: "antenna.radiowaves.left.and.right", color: AppTheme.neonGreen) { routeManager.showLiveTracking = true }
                BottomActionButton(title: "Hub", icon: "globe.americas.fill", color: AppTheme.accentPurple) { routeManager.activeHubTab = "Routes"; routeManager.isHubPresented = true }
                BottomActionButton(title: "Weather", icon: "cloud.sun.bolt.fill", color: AppTheme.accentCyan) { showWeatherSheet = true }
                BottomActionButton(title: "AI Core", icon: "brain", color: AppTheme.accentOrange) { showNeuralCore = true }
            }.padding(.top, 15).padding(.bottom, 30).padding(.horizontal, 10)
        }
    }
    
    private func updateTrackingLogic() {
        if routeManager.isTracking {
            if isAnomalyActive {
                anomalyTimer -= 1
                if anomalyTimer <= 0 { withAnimation { isAnomalyActive = false }; if currentPace >= 8.0 { triggerNotification(type: .success); points += 500; coachMessage = "АНОМАЛИЯ ВЗЛОМАНА! +500 💰" } else { triggerImpact(style: .heavy); comboMultiplier = 1.0; coachMessage = "СБОЙ! Вы не успели 💀" } } else if currentPace >= 8.0 { minedCrypto += 0.5 }
            } else { if Int.random(in: 0...100) > 96 && currentPace > 3.0 && !isAutoPaused { triggerImpact(style: .heavy); withAnimation { isAnomalyActive = true; anomalyTimer = 30 } } }
            if Int.random(in: 0...15) == 5 { let w = ["Ветер: 3 м/с 💨", "Связь стабильна 📡", "Сыро 💧", "Магнитная буря ⚡️"]; withAnimation { weatherCondition = w.randomElement()! } }
            if Int.random(in: 0...20) == 5 { let t = ["Нейро-Спутник сзади! 🤖", "Ускоряйся! 👻", "Сигнал в норме 📡", "Не останавливайся! 🏃"]; withAnimation { ghostTaunt = t.randomElement()! } }
            // Real-time speed from CoreLocation (m/s -> km/h). Negative
            // speed means "unknown" per CLLocation docs.
            let rawSpeed = locManager.location?.speed ?? -1
            currentPace = rawSpeed > 0 ? rawSpeed * 3.6 : 0.0

            // Real heart rate from HealthKit (Apple Watch / connected
            // devices). Falls back to 0 (hidden in UI) when unavailable.
            if let bpm = health.latestHeartRate, bpm > 0 {
                currentBPM = Int(bpm.rounded())
            } else {
                currentBPM = 0
            }

            if currentPace < 1.0 {
                isAutoPaused = true
                withAnimation { coachMessage = "Система: Вы остановились ⏸️" }
            } else {
                isAutoPaused = false
                caloriesBurned += (activeActivity.burnRate * comboMultiplier)
                minedCrypto += (0.01 * comboMultiplier)
                if currentBPM > 140 { triggerImpact(style: .soft) }
                routeManager.addChallengeProgress(
                    amount: (activeActivity.burnRate * comboMultiplier) * 0.1
                )
                if Double.random(in: 0...1) > 0.85 {
                    withAnimation { comboMultiplier = min(2.5, comboMultiplier + 0.1) }
                }
            }
        }
        if routeManager.activeRoute != nil && routeManager.isTracking && !isAutoPaused {
            withAnimation { routeManager.traveledProgress = min(routeManager.traveledProgress + 0.01, 1.0) }
            if routeManager.traveledProgress >= 1.0 && !showCompletionSheet { triggerNotification(type: .success); routeManager.isTracking = false; showCompletionSheet = true; points += Int(minedCrypto * 100); if points > 3000 && userLevel == 1 { DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { userLevel = 2; triggerImpact(style: .heavy); withAnimation(.spring()) { showLevelUp = true } } } }
        }
    }
    
    private func resetAfterCompletion() { routeManager.activeRoute = nil; routeManager.previewRoute = nil; routePoints.removeAll(); calculatedRoute = nil; routeManager.traveledProgress = 0.0; comboMultiplier = 1.0; points += 1500; minedCrypto = 0; isAnomalyActive = false; routeManager.isTracking = false }
    
    private func interpolate(_ points: [CLLocationCoordinate2D], progress: CGFloat) -> CLLocationCoordinate2D {
        guard points.count >= 2 else { return points.first ?? CLLocationCoordinate2D(latitude: 0, longitude: 0) }
        let p = min(max(progress, 0), 1.0); let t = CGFloat(points.count - 1); let e = p * t; let l = Int(e); let u = min(l + 1, points.count - 1); let f = e - CGFloat(l)
        let lat = points[l].latitude + (points[u].latitude - points[l].latitude) * Double(f); let lon = points[l].longitude + (points[u].longitude - points[l].longitude) * Double(f)
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}

// Вспомогательные шторки для GPS карты
struct StartRouteSheet: View {
    @EnvironmentObject var routeManager: RouteManager; @Environment(\.dismiss) var dismiss
    @Binding var points: [CLLocationCoordinate2D]; var calculatedRoute: MKRoute?; @Binding var isCreatingRoute: Bool
    @State private var selectedAct: ActivityType = .walk
    
    var body: some View {
        ZStack {
            AppTheme.bgDark.ignoresSafeArea(); MeshGradientBackground()
            VStack(spacing: 25) {
                Capsule().fill(Color.gray).frame(width: 40, height: 5).padding(.top); Text("Маршрут построен! 🔥").font(.largeTitle.bold()).foregroundColor(.white)
                let dist = calculatedRoute != nil ? (calculatedRoute!.distance / 1000.0) : (CLLocation(latitude: points[0].latitude, longitude: points[0].longitude).distance(from: CLLocation(latitude: points[1].latitude, longitude: points[1].longitude)) / 1000.0)
                let time = calculatedRoute != nil ? (calculatedRoute!.expectedTravelTime / 60.0) : (dist * 12)
                
                HStack(spacing: 30) { VStack { Text("Дистанция").foregroundColor(.gray); Text(String(format: "%.1f км", dist)).font(.title2.bold()).foregroundColor(AppTheme.neonGreen) }; VStack { Text("Время").foregroundColor(.gray); Text("\(Int(time)) мин").font(.title2.bold()).foregroundColor(AppTheme.accentCyan) } }.padding().background(.ultraThinMaterial).cornerRadius(20)
                VStack(alignment: .leading) { Text("Перепад высот 🏔️").font(.caption.bold()).foregroundColor(.gray); HStack(alignment: .bottom, spacing: 4) { ForEach(0..<25, id: \.self) { _ in Capsule().fill(AppTheme.accentPurple).frame(width: 6, height: CGFloat.random(in: 10...50)) } }.frame(height: 60) }.padding().background(.ultraThinMaterial).cornerRadius(20)
                Text("Как пойдем?").font(.headline).foregroundColor(.white)
                HStack { ForEach(ActivityType.allCases, id: \.self) { act in Button(action: { triggerImpact(); selectedAct = act }) { VStack { Image(systemName: act.icon).font(.title); Text(act.rawValue).font(.caption) }.padding().background(selectedAct == act ? AppTheme.accentPurple : Color.white.opacity(0.1)).cornerRadius(15).foregroundColor(.white) }.buttonStyle(BouncyButton()) } }
                Spacer()
                Button("Начать Маршрут 🔥") {
                    let finalPoints = calculatedRoute?.coordinates ?? points
                    let newRoute = CustomRoute(name: "Моя Тропа (\(selectedAct.rawValue))", points: finalPoints, activity: selectedAct, distance: dist, isUserCreated: true, desc: "Ваш личный маршрут.", popularity: 1)
                    routeManager.addRoute(newRoute); routeManager.activeRoute = newRoute; routeManager.traveledProgress = 0.0; isCreatingRoute = false; routeManager.isTracking = true; triggerNotification(type: .success); dismiss()
                }.font(.title2.bold()).padding().frame(maxWidth: .infinity).background(AppTheme.accentBlue).foregroundColor(.white).cornerRadius(20).shadow(color: AppTheme.accentBlue, radius: 10).padding(.bottom, 40).buttonStyle(BouncyButton())
            }.padding()
        }
    }
}

struct RouteCompletionSheet: View {
    @Environment(\.dismiss) var dismiss; let calories: Double; let combo: Double
    var body: some View {
        ZStack {
            AppTheme.bgDark.ignoresSafeArea(); MeshGradientBackground(); FloatingParticlesView()
            VStack(spacing: 30) {
                Image(systemName: "trophy.fill").font(.system(size: 100)).symbolRenderingMode(.multicolor).shadow(color: AppTheme.gold, radius: 30).padding(.top, 40)
                Text("ПОБЕДА 🔥").font(.system(size: 50, weight: .black, design: .rounded)).foregroundColor(.white); Text("Ты прошел этот маршрут!").foregroundColor(.gray)
                Text("Маршрут добавлен в тропы 📍").font(.headline).foregroundColor(AppTheme.neonGreen).padding().background(.ultraThinMaterial).cornerRadius(15)
                Spacer()
                Button("Супер! 🔥") { triggerImpact(); dismiss() }.font(.title2.bold()).frame(maxWidth: .infinity).padding().background(AppTheme.neonGreen).foregroundColor(.black).cornerRadius(20).padding(.horizontal, 30).padding(.bottom, 40).buttonStyle(BouncyButton())
            }
        }
    }
}
