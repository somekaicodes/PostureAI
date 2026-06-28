import Foundation
import WidgetKit

// The workout summary the widget reads. Duplicated in the widget target, since
// the two targets can't share types directly.
struct WorkoutSnapshot: Codable {
    var lastWorkoutDate: Date?
    var squatReps: Int
    var lungeReps: Int
    var totalSessions: Int
}

// Writes the snapshot to the shared App Group and refreshes the widget.
enum WidgetSync {
    private static let appGroup = "group.com.kaikim.PostureAI"
    private static let key = "workout_snapshot"

    static func write(_ snapshot: WorkoutSnapshot) {
        guard let defaults = UserDefaults(suiteName: appGroup),
              let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: key)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
