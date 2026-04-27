import SwiftUI
import CoreLocation
import Combine
import Foundation
import HealthKit
import CoreMotion


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

class NeuroKineticsManager: ObservableObject {
    @Published var todaySteps: Double = 0
    @Published var todayDistance: Double = 0
    @Published var todayCalories: Double = 0
    @Published var todayExerciseTime: Double = 0
    
    // НОВЫЕ БИОМЕТРИЧЕСКИЕ ДАННЫЕ
    @Published var latestBPM: Int = 0
    @Published var sleepDurationText: String = "0h 0m"
    @Published var recoveryScore: Int = 0 // от 0 до 100%
    
    private let healthStore = HKHealthStore()
    private let pedometer = CMPedometer()
    
    func bootKineticsCore() {
        if HKHealthStore.isHealthDataAvailable() {
            requestHealthKitPermissions()
        } else {
            startPedometerFallback()
        }
    }
    
    private func requestHealthKitPermissions() {
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount),
              let distType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning),
              let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
              let exerciseType = HKObjectType.quantityType(forIdentifier: .appleExerciseTime),
              let hrType = HKObjectType.quantityType(forIdentifier: .heartRate),
              let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN),
              let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        
        let typesToRead: Set = [stepType, distType, energyType, exerciseType, hrType, hrvType, sleepType]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { [weak self] success, error in
            if success {
                self?.startHealthKitObservers()
                self?.fetchBioMetrics() // Запрашиваем новые метрики
            } else {
                self?.startPedometerFallback()
            }
        }
    }
    
    private func startHealthKitObservers() {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let distType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let exerciseType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)!
        
        fetchDailyTotal(for: stepType, unit: HKUnit.count()) { val in DispatchQueue.main.async { self.todaySteps = val } }
        fetchDailyTotal(for: distType, unit: HKUnit.meter()) { val in DispatchQueue.main.async { self.todayDistance = val / 1000.0 } }
        fetchDailyTotal(for: energyType, unit: HKUnit.kilocalorie()) { val in DispatchQueue.main.async { self.todayCalories = val } }
        fetchDailyTotal(for: exerciseType, unit: HKUnit.minute()) { val in DispatchQueue.main.async { self.todayExerciseTime = val } }
    }
    
    // MARK: - БИОМЕТРИЯ (ЧТЕНИЕ РАЗОВЫХ ЗНАЧЕНИЙ)
    func fetchBioMetrics() {
        fetchLatestHeartRate()
        fetchSleepAnalysis()
        fetchHRVForRecovery()
    }
    
    // 1. Последний пульс
    private func fetchLatestHeartRate() {
        guard let hrType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: hrType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
            guard let sample = samples?.first as? HKQuantitySample else { return }
            let bpm = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
            DispatchQueue.main.async { self.latestBPM = Int(bpm) }
        }
        healthStore.execute(query)
    }
    
    // 2. Сон за последнюю ночь
    private func fetchSleepAnalysis() {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        
        // Смотрим с 6 вечера вчерашнего дня до сейчас
        let startDate = Calendar.current.date(byAdding: .hour, value: -18, to: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, _ in
            guard let samples = samples as? [HKCategorySample] else { return }
            
            // Фильтруем только время, когда человек реально спал
            let asleepSamples = samples.filter { $0.value == HKCategoryValueSleepAnalysis.asleep.rawValue || $0.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue || $0.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue || $0.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue }
            
            let totalSleepTime = asleepSamples.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
            
            let hours = Int(totalSleepTime / 3600)
            let minutes = Int((totalSleepTime.truncatingRemainder(dividingBy: 3600)) / 60)
            
            DispatchQueue.main.async {
                if hours > 0 || minutes > 0 {
                    self.sleepDurationText = "\(hours)h \(minutes)m"
                } else {
                    self.sleepDurationText = "No data"
                }
            }
        }
        healthStore.execute(query)
    }
    
    // 3. Восстановление (на основе HRV - Вариабельности)
    private func fetchHRVForRecovery() {
        guard let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return }
        let startDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        // Берем последние 3 замера HRV и усредняем
        let query = HKSampleQuery(sampleType: hrvType, predicate: predicate, limit: 3, sortDescriptors: [sortDescriptor]) { _, samples, _ in
            guard let samples = samples as? [HKQuantitySample], !samples.isEmpty else {
                DispatchQueue.main.async { self.recoveryScore = 50 } // Значение по умолчанию
                return
            }
            let avgHRV = samples.reduce(0.0) { $0 + $1.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli)) } / Double(samples.count)
            
            // Алгоритм ЦНС: нормальное HRV обычно от 20 до 100 мс.
            // Привяжем 20мс к 20% восстановления, а 80+ мс к 100%.
            var score = (avgHRV / 80.0) * 100.0
            score = max(10, min(100, score)) // Ограничиваем от 10% до 100%
            
            DispatchQueue.main.async { self.recoveryScore = Int(score) }
        }
        healthStore.execute(query)
    }
    private func fetchDailyTotal(for type: HKQuantityType, unit: HKUnit, completion: @escaping (Double) -> Void) {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let sum = result?.sumQuantity() else { return }
            completion(sum.doubleValue(for: unit))
        }
        healthStore.execute(query)
    }
    
    private func setupObserver(for type: HKQuantityType, unit: HKUnit, completion: @escaping (Double) -> Void) {
        let query = HKObserverQuery(sampleType: type, predicate: nil) { [weak self] _, _, _ in
            self?.fetchDailyTotal(for: type, unit: unit, completion: completion)
        }
        healthStore.execute(query)
    }
    
    private func startPedometerFallback() {
        guard CMPedometer.isStepCountingAvailable() else { return }
        let startOfDay = Calendar.current.startOfDay(for: Date())
        
        pedometer.startUpdates(from: startOfDay) { [weak self] data, error in
            guard let data = data, error == nil else { return }
            DispatchQueue.main.async {
                self?.todaySteps = data.numberOfSteps.doubleValue
                if let dist = data.distance?.doubleValue { self?.todayDistance = dist / 1000.0 }
                self?.todayCalories = data.numberOfSteps.doubleValue * 0.045
                self?.todayExerciseTime = data.numberOfSteps.doubleValue * 0.009
            }
        }
    }
}
