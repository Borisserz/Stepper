//
//  FirestoreSyncService.swift
//  Stepper
//
//  Pushes `WorkoutSession` SwiftData entities to Firestore at
//  `users/{uid}/workouts/{sessionId}` on save, and pulls them on first
//  launch on a fresh device. SwiftData stays the source of truth for
//  offline UX; Firestore is the cloud backup. Conflict resolution:
//  last-write-wins keyed by `startedAt` (workout sessions are immutable
//  after they finish in practice, so collisions are rare).
//
//  Wrapped in `#if canImport(FirebaseFirestore)` so the project compiles
//  before the SPM package is added.
//

import Foundation
import SwiftData
import CoreLocation

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

@MainActor
final class FirestoreSyncService {
    static let shared = FirestoreSyncService()
    private init() {}

    /// Pushes a single workout to Firestore. Silently no-ops when Firebase
    /// isn't configured or the user isn't signed in — local persistence
    /// already happened in `WorkoutRecorder.persistLocally`.
    func push(_ session: WorkoutSession) async {
        #if canImport(FirebaseFirestore)
        guard FirebaseBootstrap.isConfigured,
              let uid = FirebaseAuthBridge.currentUID else { return }
        let db = Firestore.firestore()
        let docRef = db.collection("users").document(uid)
            .collection("workouts").document(session.id.uuidString)

        do {
            try await docRef.setData(Self.encode(session: session), merge: true)
        } catch {
            // Pure best-effort — local SwiftData copy is the source of
            // truth, so we don't surface errors to the user.
            #if DEBUG
            print("[FirestoreSync] push failed: \(error)")
            #endif
        }
        #else
        _ = session
        #endif
    }

    /// Pulls every workout for the current user that the local store doesn't
    /// already have. Called once on app launch when a SwiftData store is
    /// empty (e.g. fresh install, restored device).
    func pullIfNeeded(into context: ModelContext) async {
        #if canImport(FirebaseFirestore)
        guard FirebaseBootstrap.isConfigured,
              let uid = FirebaseAuthBridge.currentUID else { return }

        // Fast bail-out: if SwiftData already has rows, assume we're up to
        // date — the user can pull-to-refresh from the history screen later.
        let descriptor = FetchDescriptor<WorkoutSession>()
        if let existing = try? context.fetch(descriptor), !existing.isEmpty {
            return
        }

        let db = Firestore.firestore()
        let snapshot: QuerySnapshot
        do {
            snapshot = try await db.collection("users").document(uid)
                .collection("workouts").getDocuments()
        } catch {
            #if DEBUG
            print("[FirestoreSync] pull failed: \(error)")
            #endif
            return
        }

        for doc in snapshot.documents {
            guard let session = Self.decode(documentID: doc.documentID,
                                            data: doc.data()) else { continue }
            context.insert(session)
        }
        try? context.save()
        #else
        _ = context
        #endif
    }

    /// Wipes every cloud workout for the current user. Called by
    /// `AccountManager.deleteAccount` so the deletion is total per Apple
    /// Guideline 5.1.1(v).
    func deleteAllForCurrentUser() async {
        #if canImport(FirebaseFirestore)
        guard FirebaseBootstrap.isConfigured,
              let uid = FirebaseAuthBridge.currentUID else { return }
        let db = Firestore.firestore()
        do {
            let snapshot = try await db.collection("users").document(uid)
                .collection("workouts").getDocuments()
            for doc in snapshot.documents {
                try? await doc.reference.delete()
            }
            try? await db.collection("users").document(uid).delete()
        } catch {
            #if DEBUG
            print("[FirestoreSync] delete failed: \(error)")
            #endif
        }
        #endif
    }

    // MARK: - Codec

    #if canImport(FirebaseFirestore)
    /// Mirrors the SwiftData schema as a flat Firestore document. We don't
    /// use `Codable` because `@Model` types can't conform safely with
    /// relationships, and Firestore wants its own primitive map.
    static func encode(session: WorkoutSession) -> [String: Any] {
        [
            "id": session.id.uuidString,
            "activityRaw": session.activityRaw,
            "startedAt": Timestamp(date: session.startedAt),
            "endedAt": Timestamp(date: session.endedAt),
            "distanceMeters": session.distanceMeters,
            "elapsedSeconds": session.elapsedSeconds,
            "caloriesKcal": session.caloriesKcal,
            "avgPaceSecPerKm": session.avgPaceSecPerKm as Any,
            "title": session.title,
            "locations": session.locations.map { loc in
                [
                    "lat": loc.latitude,
                    "lon": loc.longitude,
                    "alt": loc.altitudeMeters,
                    "acc": loc.horizontalAccuracy,
                    "spd": loc.speed,
                    "ts": Timestamp(date: loc.timestamp)
                ]
            }
        ]
    }

    static func decode(documentID: String, data: [String: Any]) -> WorkoutSession? {
        guard let activityRaw = data["activityRaw"] as? String,
              let startedAt = (data["startedAt"] as? Timestamp)?.dateValue(),
              let endedAt = (data["endedAt"] as? Timestamp)?.dateValue(),
              let distance = data["distanceMeters"] as? Double,
              let elapsed = data["elapsedSeconds"] as? Double,
              let calories = data["caloriesKcal"] as? Double,
              let title = data["title"] as? String else {
            return nil
        }

        let id = UUID(uuidString: documentID) ?? UUID()
        let session = WorkoutSession(
            id: id,
            activityRaw: activityRaw,
            startedAt: startedAt,
            endedAt: endedAt,
            distanceMeters: distance,
            elapsedSeconds: elapsed,
            caloriesKcal: calories,
            avgPaceSecPerKm: data["avgPaceSecPerKm"] as? Double,
            title: title
        )

        if let locArr = data["locations"] as? [[String: Any]] {
            session.locations = locArr.compactMap { dict in
                guard let lat = dict["lat"] as? Double,
                      let lon = dict["lon"] as? Double,
                      let alt = dict["alt"] as? Double,
                      let acc = dict["acc"] as? Double,
                      let spd = dict["spd"] as? Double,
                      let ts = (dict["ts"] as? Timestamp)?.dateValue() else { return nil }
                let location = WorkoutLocation(
                    latitude: lat, longitude: lon,
                    altitudeMeters: alt, horizontalAccuracy: acc,
                    speed: spd, timestamp: ts
                )
                location.session = session
                return location
            }
        }
        return session
    }
    #endif
}
