//
//  HealthKitManager.swift
//  Stepper
//
//  Reads daily steps, distance and heart rate from HealthKit. Writes nothing
//  yet — workout writes are added in PR #3 once the GPS session ends.
//
//  HealthKit is unavailable on iPad and on the iOS simulator's "iPad"
//  destination, so all callers must tolerate `isAvailable == false`. The
//  manager exposes simple `Double` outputs so existing UI can drop the
//  hardcoded `steps = 6432` placeholder without restructuring views.
//

import Foundation
import HealthKit
import SwiftUI

@MainActor
@Observable
final class HealthKitManager {
    /// Total steps taken today (midnight → now), or `nil` if unknown.
    private(set) var todaySteps: Double?
    /// Total walking + running distance today (metres), or `nil` if unknown.
    private(set) var todayDistanceMeters: Double?
    /// Most recent heart-rate sample (BPM), or `nil` if unknown.
    private(set) var latestHeartRate: Double?
    /// Last error message surfaced to the UI.
    var lastError: String?
    /// True once `requestAuthorization()` returned without throwing.
    private(set) var hasRequestedAuthorization: Bool = false

    /// `HKHealthStore` conforms to `Sendable` and is thread-safe per Apple's
    /// docs. Holding a single retained instance keeps the underlying object
    /// alive for the lifetime of the manager — creating a throwaway store
    /// per query (the previous implementation) risked ARC deallocating it
    /// before the completion handler fired, which would suspend
    /// `withCheckedContinuation` forever.
    private nonisolated let store = HKHealthStore()

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    private var readTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = []
        if let steps = HKObjectType.quantityType(forIdentifier: .stepCount) { types.insert(steps) }
        if let distance = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) { types.insert(distance) }
        if let hr = HKObjectType.quantityType(forIdentifier: .heartRate) { types.insert(hr) }
        return types
    }

    private var writeTypes: Set<HKSampleType> {
        var types: Set<HKSampleType> = []
        types.insert(HKObjectType.workoutType())
        if let route = HKSeriesType.workoutRoute() as HKSampleType? {
            types.insert(route)
        }
        return types
    }

    /// Asks the user for HealthKit permission. iOS will only show the system
    /// sheet the first time; subsequent calls are no-ops.
    func requestAuthorization() async {
        guard isAvailable else {
            lastError = NSLocalizedString("health.error.unavailable",
                                          value: "Apple Health is not available on this device.",
                                          comment: "")
            return
        }
        do {
            try await store.requestAuthorization(toShare: writeTypes, read: readTypes)
            hasRequestedAuthorization = true
            await refreshAll()
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Pulls today's totals + latest HR. Call after authorization, on app
    /// foregrounding, or on a pull-to-refresh gesture.
    func refreshAll() async {
        guard isAvailable else { return }
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.refreshSteps() }
            group.addTask { await self.refreshDistance() }
            group.addTask { await self.refreshHeartRate() }
        }
    }

    // MARK: - Queries

    private func refreshSteps() async {
        guard let type = HKObjectType.quantityType(forIdentifier: .stepCount) else { return }
        if let total = await sumQuantityToday(type: type, unit: .count()) {
            self.todaySteps = total
        }
    }

    private func refreshDistance() async {
        guard let type = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) else { return }
        if let total = await sumQuantityToday(type: type, unit: HKUnit.meter()) {
            self.todayDistanceMeters = total
        }
    }

    private func refreshHeartRate() async {
        guard let type = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        if let bpm = await mostRecentHeartRate(type: type) {
            self.latestHeartRate = bpm
        }
    }

    // MARK: - Lower-level helpers (nonisolated to run off the main actor)

    private nonisolated func sumQuantityToday(type: HKQuantityType, unit: HKUnit) async -> Double? {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end = Date()
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, _ in
                continuation.resume(returning: statistics?.sumQuantity()?.doubleValue(for: unit))
            }
            store.execute(query)
        }
    }

    private nonisolated func mostRecentHeartRate(type: HKQuantityType) async -> Double? {
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sort]
            ) { _, samples, _ in
                let bpm = (samples?.first as? HKQuantitySample)?
                    .quantity.doubleValue(for: HKUnit(from: "count/min"))
                continuation.resume(returning: bpm)
            }
            store.execute(query)
        }
    }
}
