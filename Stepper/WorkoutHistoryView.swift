//
//  WorkoutHistoryView.swift
//  Stepper
//
//  Lists every persisted `WorkoutSession`, newest first, with a lightweight
//  polyline preview per row. Tapping a row opens `WorkoutDetailView` with a
//  full-screen map. Reachable from `SettingsView` ("Workout History" row).
//

import MapKit
import SwiftData
import SwiftUI

struct WorkoutHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SettingsStore.self) private var settings
    @Query(sort: \WorkoutSession.startedAt, order: .reverse) private var sessions: [WorkoutSession]

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bgDark.ignoresSafeArea()
                if sessions.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(sessions) { session in
                            NavigationLink(value: session.id) {
                                WorkoutRow(session: session)
                            }
                            .listRowBackground(Color.white.opacity(0.05))
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle(Text("workout.history.title"))
            .navigationDestination(for: UUID.self) { id in
                if let session = sessions.first(where: { $0.id == id }) {
                    WorkoutDetailView(session: session)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.run.circle")
                .font(.system(size: 64))
                .foregroundStyle(AppTheme.neonGreen)
            Text("workout.history.empty.title")
                .font(.title3.bold())
                .foregroundStyle(.white)
            Text("workout.history.empty.subtitle")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
}

private struct WorkoutRow: View {
    let session: WorkoutSession
    @Environment(SettingsStore.self) private var settings

    var body: some View {
        HStack(spacing: 12) {
            RoutePreviewShape(coordinates: session.locations.map { $0.coordinate })
                .stroke(AppTheme.neonGreen, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .frame(width: 64, height: 64)
            VStack(alignment: .leading, spacing: 4) {
                Text(session.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                HStack(spacing: 10) {
                    Label(settings.distanceUnit.format(meters: session.distanceMeters),
                          systemImage: "ruler")
                    Label(formatDuration(session.elapsedSeconds), systemImage: "clock")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            Text(session.startedAt, format: .dateTime.day().month().hour().minute())
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }

    private func formatDuration(_ seconds: Double) -> String {
        let total = Int(seconds)
        let hours = total / 3600
        let mins = (total % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }
}

struct WorkoutDetailView: View {
    let session: WorkoutSession
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var modelContext
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var showDeleteConfirm = false

    var body: some View {
        ZStack(alignment: .bottom) {
            map
            summaryCard
        }
        .navigationTitle(session.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .alert(Text("workout.detail.delete.title"), isPresented: $showDeleteConfirm) {
            Button(role: .cancel) {} label: { Text("common.cancel") }
            Button(role: .destructive) {
                modelContext.delete(session)
                try? modelContext.save()
            } label: { Text("workout.detail.delete.confirm") }
        }
        .onAppear { fitCamera() }
    }

    private var map: some View {
        Map(position: $cameraPosition, interactionModes: .all) {
            if !session.locations.isEmpty {
                MapPolyline(coordinates: session.locations.map { $0.coordinate })
                    .stroke(AppTheme.neonGreen, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                if let start = session.locations.first {
                    Annotation("", coordinate: start.coordinate) {
                        Circle().fill(AppTheme.neonGreen).frame(width: 12, height: 12)
                    }
                }
                if let end = session.locations.last {
                    Annotation("", coordinate: end.coordinate) {
                        Circle().fill(AppTheme.accentRed).frame(width: 12, height: 12)
                    }
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .all))
        .ignoresSafeArea(edges: .bottom)
    }

    private var summaryCard: some View {
        HStack(spacing: 16) {
            stat(title: "workout.record.distance",
                 value: settings.distanceUnit.format(meters: session.distanceMeters))
            stat(title: "workout.record.duration",
                 value: formatDuration(session.elapsedSeconds))
            stat(title: "workout.record.calories",
                 value: "\(Int(session.caloriesKcal))")
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
        .padding(16)
    }

    @ViewBuilder
    private func stat(title: LocalizedStringKey, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2.bold())
                .foregroundStyle(.white.opacity(0.6))
                .textCase(.uppercase)
            Text(value)
                .font(.headline.monospacedDigit())
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
    }

    private func fitCamera() {
        let coords = session.locations.map { $0.coordinate }
        guard !coords.isEmpty else { return }
        let lats = coords.map { $0.latitude }
        let lons = coords.map { $0.longitude }
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLon = lons.min(), let maxLon = lons.max() else { return }
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.4, 0.005),
            longitudeDelta: max((maxLon - minLon) * 1.4, 0.005)
        )
        cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
    }

    private func formatDuration(_ seconds: Double) -> String {
        let total = Int(seconds)
        let hours = total / 3600
        let mins = (total % 3600) / 60
        let secs = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, mins, secs)
        }
        return String(format: "%02d:%02d", mins, secs)
    }
}

extension WorkoutLocation {
    /// Converts the persisted lat/lon pair into a `CLLocationCoordinate2D`.
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

/// Draws a polyline of normalised lat/lon coordinates inside the available
/// rect. Cheap to render — used as a thumbnail in the history list instead
/// of a full `Map` view per row.
private struct RoutePreviewShape: Shape {
    let coordinates: [CLLocationCoordinate2D]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard coordinates.count >= 2 else { return path }
        let lats = coordinates.map { $0.latitude }
        let lons = coordinates.map { $0.longitude }
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLon = lons.min(), let maxLon = lons.max() else { return path }
        let dLat = max(maxLat - minLat, 1e-6)
        let dLon = max(maxLon - minLon, 1e-6)

        for (idx, coord) in coordinates.enumerated() {
            let x = CGFloat((coord.longitude - minLon) / dLon) * rect.width
            // Latitudes increase northward but UIKit y grows downward.
            let y = rect.height - CGFloat((coord.latitude - minLat) / dLat) * rect.height
            let point = CGPoint(x: x, y: y)
            if idx == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        return path
    }
}
