//
//  RecordWorkoutView.swift
//  Stepper
//
//  Full-screen sheet that drives a real GPS-recorded workout: pick activity,
//  start, pause/resume, finish, save. Distances respect the user's chosen
//  unit from `SettingsStore`. The legacy gamified `GPSTabView` simulation
//  is left untouched — this is the production path that writes HKWorkout +
//  HKWorkoutRoute and persists a `WorkoutSession` to SwiftData.
//

import CoreLocation
import MapKit
import SwiftData
import SwiftUI

struct RecordWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(WorkoutRecorder.self) private var recorder
    @Environment(SettingsStore.self) private var settings

    @StateObject private var locManager = LocationManager()

    @State private var selectedActivity: ActivityType = .walk
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var showDiscardConfirm = false
    @State private var routeCoordinates: [CLLocationCoordinate2D] = []
    @State private var saveError: String?

    var body: some View {
        ZStack {
            AppTheme.bgDark.ignoresSafeArea()
            mapBackground
            FloatingParticlesView()
            VStack {
                topBar
                Spacer()
                statsCard
                controls
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .onAppear { locManager.requestAuth() }
        .onReceive(locManager.$location) { newValue in
            guard let loc = newValue else { return }
            recorder.ingest(loc)
            if recorder.state == .recording {
                routeCoordinates.append(loc.coordinate)
            }
        }
        .alert(Text("workout.record.discard.title"), isPresented: $showDiscardConfirm) {
            Button(role: .cancel) { } label: { Text("common.cancel") }
            Button(role: .destructive) {
                recorder.discard()
                routeCoordinates.removeAll()
                dismiss()
            } label: { Text("workout.record.discard.confirm") }
        } message: {
            Text("workout.record.discard.message")
        }
        .alert(Text("workout.record.error.title"),
               isPresented: Binding(get: { saveError != nil }, set: { if !$0 { saveError = nil } })) {
            Button(role: .cancel) { saveError = nil } label: { Text("common.ok") }
        } message: {
            Text(saveError ?? "")
        }
    }

    // MARK: - Map background

    private var mapBackground: some View {
        Map(position: $cameraPosition) {
            UserAnnotation()
            if routeCoordinates.count >= 2 {
                MapPolyline(coordinates: routeCoordinates)
                    .stroke(AppTheme.neonGreen, style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
            }
        }
        .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .all))
        .colorScheme(.dark)
        .ignoresSafeArea()
        .opacity(0.55)
    }

    // MARK: - Top bar (close)

    private var topBar: some View {
        HStack {
            Button {
                if recorder.state == .idle { dismiss() } else { showDiscardConfirm = true }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(.ultraThinMaterial, in: Circle())
            }
            Spacer()
            Text("workout.record.title")
                .font(.title3.bold())
                .foregroundStyle(.white)
            Spacer()
            // Spacer for symmetry with the close button.
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal)
        .padding(.top, 12)
    }

    // MARK: - Stats

    private var statsCard: some View {
        VStack(spacing: 16) {
            Text(formatDuration(recorder.elapsedSeconds))
                .font(.system(size: 64, weight: .black, design: .rounded).monospacedDigit())
                .foregroundStyle(.white)
                .shadow(color: AppTheme.accentCyan.opacity(0.5), radius: 12)

            HStack(spacing: 24) {
                StatBlock(
                    title: Text("workout.record.distance"),
                    value: settings.distanceUnit.format(meters: recorder.distanceMeters)
                )
                StatBlock(
                    title: Text("workout.record.pace"),
                    value: paceText
                )
                StatBlock(
                    title: Text("workout.record.calories"),
                    value: "\(Int(recorder.caloriesKcal)) kcal"
                )
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28))
        .overlay(
            RoundedRectangle(cornerRadius: 28).stroke(.white.opacity(0.15), lineWidth: 1)
        )
    }

    private var paceText: String {
        // Pace is intentionally always reported in time-per-distance even
        // though the user picked their preferred distance unit elsewhere —
        // running coaches universally use min/km or min/mi.
        guard let pace = recorder.paceSecPerKm, pace.isFinite, pace > 0 else { return "—" }
        let isMiles = settings.distanceUnit == .miles
        let secondsPerUnit = isMiles ? pace * 1.609344 : pace
        let minutes = Int(secondsPerUnit) / 60
        let seconds = Int(secondsPerUnit) % 60
        let lookupKey = isMiles ? "unit.minPerMi" : "unit.minPerKm"
        let suffix = NSLocalizedString(lookupKey, value: isMiles ? "/mi" : "/km", comment: "")
        return String(format: "%d:%02d %@", minutes, seconds, suffix)
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: 16) {
            if recorder.state == .idle {
                activityPicker
            }

            HStack(spacing: 16) {
                switch recorder.state {
                case .idle:
                    primaryButton(titleKey: "workout.record.start", color: AppTheme.neonGreen) {
                        recorder.start(activity: selectedActivity)
                        routeCoordinates.removeAll()
                    }
                case .recording:
                    secondaryButton(titleKey: "workout.record.pause") {
                        recorder.pause()
                    }
                    primaryButton(titleKey: "workout.record.finish", color: AppTheme.accentRed) {
                        Task { await finishRecording() }
                    }
                case .paused:
                    secondaryButton(titleKey: "workout.record.resume") {
                        recorder.resume()
                    }
                    primaryButton(titleKey: "workout.record.finish", color: AppTheme.accentRed) {
                        Task { await finishRecording() }
                    }
                }
            }
        }
    }

    private var activityPicker: some View {
        HStack(spacing: 10) {
            ForEach(ActivityType.allCases, id: \.self) { type in
                Button {
                    triggerImpact()
                    selectedActivity = type
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: type.icon)
                            .font(.title2)
                        Text(type.rawValue)
                            .font(.caption.bold())
                    }
                    .foregroundStyle(selectedActivity == type ? .black : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        selectedActivity == type
                        ? AnyShapeStyle(AppTheme.neonGreen)
                        : AnyShapeStyle(.ultraThinMaterial)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }
            }
        }
    }

    @ViewBuilder
    private func primaryButton(titleKey: LocalizedStringKey, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: { triggerImpact(style: .heavy); action() }) {
            Text(titleKey)
                .font(.title3.bold())
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .shadow(color: color.opacity(0.6), radius: 12)
        }
    }

    @ViewBuilder
    private func secondaryButton(titleKey: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: { triggerImpact(); action() }) {
            Text(titleKey)
                .font(.title3.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.2), lineWidth: 1))
        }
    }

    private func finishRecording() async {
        let saved = await recorder.stop(savingTo: modelContext)
        routeCoordinates.removeAll()
        if saved == nil, let err = recorder.lastError {
            saveError = err
            return
        }
        dismiss()
    }

    private func formatDuration(_ seconds: Double) -> String {
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }
}

private struct StatBlock: View {
    let title: Text
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            title
                .font(.caption2.bold())
                .foregroundStyle(.white.opacity(0.6))
                .textCase(.uppercase)
            Text(value)
                .font(.headline.monospacedDigit())
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
    }
}
