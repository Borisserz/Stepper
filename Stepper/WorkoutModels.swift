//
//  WorkoutModels.swift
//  Stepper
//
//  SwiftData models that persist completed workouts (route + summary) to
//  the existing app-group SQLite store. The previous `@Model` stubs in
//  `footstepeRRApp.swift` were empty placeholders; these are the first real
//  schema definitions in the app.
//

import Foundation
import SwiftData

/// One persisted GPS-recorded workout. Distance, time and calories are
/// pre-computed at stop time so list views don't have to recompute them.
@Model
final class WorkoutSession {
    @Attribute(.unique) var id: UUID
    /// Stored as `ActivityType.rawValue`. Strings keep the schema decoupled
    /// from the enum so renames don't require a SwiftData migration.
    var activityRaw: String
    var startedAt: Date
    var endedAt: Date
    /// Total moving distance in metres, summed from `CLLocation` deltas.
    var distanceMeters: Double
    /// Total moving time in seconds (excludes paused intervals).
    var elapsedSeconds: Double
    /// Estimated calories burned, derived from activity type + duration.
    var caloriesKcal: Double
    /// Average pace in seconds per kilometre. `nil` for zero-distance.
    var avgPaceSecPerKm: Double?
    /// Optional title the user may add later. Defaults to a date-based name.
    var title: String

    @Relationship(deleteRule: .cascade, inverse: \WorkoutLocation.session)
    var locations: [WorkoutLocation] = []

    init(
        id: UUID = UUID(),
        activityRaw: String,
        startedAt: Date,
        endedAt: Date,
        distanceMeters: Double,
        elapsedSeconds: Double,
        caloriesKcal: Double,
        avgPaceSecPerKm: Double?,
        title: String
    ) {
        self.id = id
        self.activityRaw = activityRaw
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.distanceMeters = distanceMeters
        self.elapsedSeconds = elapsedSeconds
        self.caloriesKcal = caloriesKcal
        self.avgPaceSecPerKm = avgPaceSecPerKm
        self.title = title
    }
}

/// One GPS sample inside a `WorkoutSession`. Stored as a separate entity so
/// route polylines can be loaded lazily without rehydrating the whole list.
@Model
final class WorkoutLocation {
    var latitude: Double
    var longitude: Double
    var altitudeMeters: Double
    var horizontalAccuracy: Double
    var speed: Double
    var timestamp: Date
    var session: WorkoutSession?

    init(
        latitude: Double,
        longitude: Double,
        altitudeMeters: Double,
        horizontalAccuracy: Double,
        speed: Double,
        timestamp: Date
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitudeMeters = altitudeMeters
        self.horizontalAccuracy = horizontalAccuracy
        self.speed = speed
        self.timestamp = timestamp
    }
}
