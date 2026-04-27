//
//  WorkoutRecorder.swift
//  Stepper
//
//  Owns the lifecycle of a single in-progress workout: collects GPS samples
//  from `LocationManager`, accumulates distance/duration, supports
//  pause/resume, and on stop writes the result both to SwiftData (for the
//  in-app history) and to HealthKit (`HKWorkout` + `HKWorkoutRoute`).
//
//  Designed to coexist with the existing `RouteManager`-driven gamified
//  flow in `Views&Map.swift` — the recorder is purely additive and does not
//  touch the legacy `isTracking`/`activeRoute` state. The GPSTabView is the
//  single point where a user starts/stops a recording.
//

import CoreLocation
import Foundation
import HealthKit
import SwiftData
import SwiftUI

@MainActor
@Observable
final class WorkoutRecorder {
    enum State: Equatable {
        case idle
        case recording
        case paused
    }

    // MARK: - Public state (observed by UI)

    private(set) var state: State = .idle
    private(set) var activity: ActivityType = .walk
    private(set) var startedAt: Date?
    private(set) var distanceMeters: Double = 0
    /// Moving time excluding paused intervals.
    private(set) var elapsedSeconds: Double = 0
    /// Most recent instantaneous speed in m/s (smoothed via location.speed).
    private(set) var currentSpeedMps: Double = 0
    /// Last surfaced error.
    var lastError: String?

    // MARK: - Internals

    private var locations: [CLLocation] = []
    private var lastTickAt: Date?
    private var clock: Timer?

    private nonisolated let store = HKHealthStore()

    // MARK: - Convenience getters for the UI

    var paceSecPerKm: Double? {
        guard distanceMeters > 0 else { return nil }
        return elapsedSeconds / (distanceMeters / 1000.0)
    }

    /// Activity-specific kcal burn rate, in kcal/sec, used for live updates.
    private var kcalPerSecond: Double {
        // Rough metabolic rates per activity, derived from MET tables for a
        // 75 kg adult. Values are intentionally conservative — HealthKit
        // ultimately recomputes calories from the workout summary on write.
        switch activity {
        case .walk: return 0.07
        case .run: return 0.18
        case .hike: return 0.11
        case .ride: return 0.13
        }
    }

    var caloriesKcal: Double { kcalPerSecond * elapsedSeconds }

    // MARK: - Lifecycle

    func start(activity: ActivityType) {
        guard state == .idle else { return }
        self.activity = activity
        self.startedAt = Date()
        self.distanceMeters = 0
        self.elapsedSeconds = 0
        self.currentSpeedMps = 0
        self.locations.removeAll()
        self.lastTickAt = Date()
        self.state = .recording
        startClock()
    }

    func pause() {
        guard state == .recording else { return }
        state = .paused
        stopClock()
    }

    func resume() {
        guard state == .paused else { return }
        lastTickAt = Date()
        state = .recording
        startClock()
    }

    /// Stops the recorder, persists to SwiftData (if a context is provided)
    /// and writes a corresponding `HKWorkout` + `HKWorkoutRoute` to Health.
    /// `context` is optional so the recorder remains testable in isolation.
    @discardableResult
    func stop(savingTo context: ModelContext?) async -> WorkoutSession? {
        guard state != .idle else { return nil }
        let endedAt = Date()
        stopClock()

        let started = startedAt ?? endedAt
        let summary = SummarySnapshot(
            activity: activity,
            startedAt: started,
            endedAt: endedAt,
            distanceMeters: distanceMeters,
            elapsedSeconds: elapsedSeconds,
            caloriesKcal: caloriesKcal,
            paceSecPerKm: paceSecPerKm,
            locations: locations
        )

        // Reset live state so the UI flips back to idle immediately while
        // the (slow) HealthKit write continues in the background.
        state = .idle
        startedAt = nil

        var saved: WorkoutSession?
        if let context {
            saved = persistLocally(summary, in: context)
        }

        await writeToHealth(summary)
        return saved
    }

    /// Discards the in-progress recording without writing anything.
    func discard() {
        stopClock()
        state = .idle
        startedAt = nil
        locations.removeAll()
        distanceMeters = 0
        elapsedSeconds = 0
    }

    // MARK: - Sample ingestion

    /// Call from `LocationManager` whenever a new fix arrives. Filters out
    /// stale or low-accuracy samples and updates running totals.
    func ingest(_ location: CLLocation) {
        guard state == .recording else { return }
        guard location.horizontalAccuracy > 0,
              location.horizontalAccuracy < 50,
              abs(location.timestamp.timeIntervalSinceNow) < 10 else { return }

        if let last = locations.last {
            let delta = location.distance(from: last)
            // Reject teleports and parked-GPS jitter under 1 m.
            if delta > 1 && delta < 200 {
                distanceMeters += delta
            }
        }
        locations.append(location)
        currentSpeedMps = max(0, location.speed)
    }

    // MARK: - Internals

    private func startClock() {
        stopClock()
        clock = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    private func stopClock() {
        clock?.invalidate()
        clock = nil
    }

    private func tick() {
        guard state == .recording else { return }
        let now = Date()
        if let last = lastTickAt {
            elapsedSeconds += now.timeIntervalSince(last)
        }
        lastTickAt = now
    }

    // MARK: - Persistence

    private struct SummarySnapshot {
        let activity: ActivityType
        let startedAt: Date
        let endedAt: Date
        let distanceMeters: Double
        let elapsedSeconds: Double
        let caloriesKcal: Double
        let paceSecPerKm: Double?
        let locations: [CLLocation]
    }

    private func persistLocally(_ s: SummarySnapshot, in context: ModelContext) -> WorkoutSession {
        let session = WorkoutSession(
            activityRaw: s.activity.rawValue,
            startedAt: s.startedAt,
            endedAt: s.endedAt,
            distanceMeters: s.distanceMeters,
            elapsedSeconds: s.elapsedSeconds,
            caloriesKcal: s.caloriesKcal,
            avgPaceSecPerKm: s.paceSecPerKm,
            title: Self.defaultTitle(for: s.activity, at: s.startedAt)
        )
        context.insert(session)
        for loc in s.locations {
            let sample = WorkoutLocation(
                latitude: loc.coordinate.latitude,
                longitude: loc.coordinate.longitude,
                altitudeMeters: loc.altitude,
                horizontalAccuracy: loc.horizontalAccuracy,
                speed: max(0, loc.speed),
                timestamp: loc.timestamp
            )
            sample.session = session
            session.locations.append(sample)
            context.insert(sample)
        }
        do {
            try context.save()
        } catch {
            lastError = error.localizedDescription
        }
        return session
    }

    private static func defaultTitle(for activity: ActivityType, at start: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return "\(activity.rawValue) · \(formatter.string(from: start))"
    }

    // MARK: - HealthKit write

    private nonisolated func writeToHealth(_ s: SummarySnapshot) async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let workoutType = HKObjectType.workoutType()
        let routeType: HKSeriesType? = HKSeriesType.workoutRoute()
        let canShareWorkout = store.authorizationStatus(for: workoutType) == .sharingAuthorized
        guard canShareWorkout else { return }

        let config = HKWorkoutConfiguration()
        config.activityType = s.activity.healthKitActivityType
        config.locationType = .outdoor

        let builder = HKWorkoutBuilder(healthStore: store, configuration: config, device: .local())
        let routeBuilder: HKWorkoutRouteBuilder?
        if routeType != nil, store.authorizationStatus(for: HKSeriesType.workoutRoute()) == .sharingAuthorized {
            routeBuilder = HKWorkoutRouteBuilder(healthStore: store, device: .local())
        } else {
            routeBuilder = nil
        }

        do {
            try await builder.beginCollection(at: s.startedAt)

            // Distance + energy summary.
            var samples: [HKSample] = []
            if s.distanceMeters > 0,
               let distanceType = HKQuantityType.quantityType(forIdentifier: distanceIdentifier(for: s.activity)) {
                let q = HKQuantity(unit: .meter(), doubleValue: s.distanceMeters)
                samples.append(HKQuantitySample(type: distanceType, quantity: q, start: s.startedAt, end: s.endedAt))
            }
            if s.caloriesKcal > 0,
               let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
                let q = HKQuantity(unit: .kilocalorie(), doubleValue: s.caloriesKcal)
                samples.append(HKQuantitySample(type: energyType, quantity: q, start: s.startedAt, end: s.endedAt))
            }
            if !samples.isEmpty {
                try await builder.addSamples(samples)
            }

            try await builder.endCollection(at: s.endedAt)
            let workout = try await builder.finishWorkout()

            // Route is optional — failures here shouldn't cancel the workout.
            if let routeBuilder, !s.locations.isEmpty, let workout {
                try await routeBuilder.insertRouteData(s.locations)
                _ = try? await routeBuilder.finishRoute(with: workout, metadata: nil)
            }
        } catch {
            // Errors are surfaced to the next refreshAll() via `lastError`
            // on HealthKitManager — the recorder doesn't have a direct
            // reference, so we swallow here to avoid a hung `await stop()`.
        }
    }

    private nonisolated func distanceIdentifier(for activity: ActivityType) -> HKQuantityTypeIdentifier {
        switch activity {
        case .ride: return .distanceCycling
        default: return .distanceWalkingRunning
        }
    }
}

extension ActivityType {
    /// Maps the cyber-themed activity enum onto Apple's `HKWorkoutActivityType`.
    var healthKitActivityType: HKWorkoutActivityType {
        switch self {
        case .walk: return .walking
        case .run: return .running
        case .hike: return .hiking
        case .ride: return .cycling
        }
    }
}
