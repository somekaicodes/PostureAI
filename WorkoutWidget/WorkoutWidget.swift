//
//  WorkoutWidget.swift
//  WorkoutWidget
//
//  Created by Kai Kim on 2026-06-26.
//

import SwiftUI
import WidgetKit

// Mirror of the snapshot the app writes to the shared App Group. The widget
// can't read SwiftData directly, so it reads this small JSON summary instead.
struct WorkoutSnapshot: Codable {
    var lastWorkoutDate: Date?
    var squatReps: Int
    var lungeReps: Int
    var totalSessions: Int

    static let empty = WorkoutSnapshot(lastWorkoutDate: nil, squatReps: 0, lungeReps: 0, totalSessions: 0)
}

enum WidgetStore {
    static let appGroup = "group.com.kaikim.PostureAI"
    static let key = "workout_snapshot"

    static func read() -> WorkoutSnapshot {
        guard let defaults = UserDefaults(suiteName: appGroup),
              let data = defaults.data(forKey: key),
              let snapshot = try? JSONDecoder().decode(WorkoutSnapshot.self, from: data) else {
            return .empty
        }
        return snapshot
    }
}

struct WorkoutEntry: TimelineEntry {
    let date: Date
    let snapshot: WorkoutSnapshot
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> WorkoutEntry {
        WorkoutEntry(date: Date(), snapshot: .empty)
    }

    func getSnapshot(in context: Context, completion: @escaping (WorkoutEntry) -> Void) {
        completion(WorkoutEntry(date: Date(), snapshot: WidgetStore.read()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WorkoutEntry>) -> Void) {
        // The app reloads the widget on save; refresh hourly as a fallback.
        let entry = WorkoutEntry(date: Date(), snapshot: WidgetStore.read())
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

struct WorkoutWidgetEntryView: View {
    var entry: WorkoutEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Last Workout", systemImage: "figure.strengthtraining.traditional")
                .font(.caption2)
                .foregroundStyle(.secondary)

            if let date = entry.snapshot.lastWorkoutDate {
                Text("\(entry.snapshot.squatReps + entry.snapshot.lungeReps)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                Text("reps")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
                Text("squat \(entry.snapshot.squatReps) · lunge \(entry.snapshot.lungeReps)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(date, format: .relative(presentation: .named))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            } else {
                Spacer()
                Text("No workouts yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct WorkoutWidget: Widget {
    let kind = "WorkoutWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WorkoutWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Last Workout")
        .description("Your most recent reps.")
        .supportedFamilies([.systemSmall])
    }
}

#Preview(as: .systemSmall) {
    WorkoutWidget()
} timeline: {
    WorkoutEntry(date: .now,
                 snapshot: WorkoutSnapshot(lastWorkoutDate: .now, squatReps: 12, lungeReps: 5, totalSessions: 3))
}
