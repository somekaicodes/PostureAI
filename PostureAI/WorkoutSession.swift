import Foundation
import SwiftData

// One logged workout: when it started and how many reps of each exercise.
@Model
final class WorkoutSession {
    var startedAt: Date
    var squatReps: Int
    var lungeReps: Int

    init(startedAt: Date, squatReps: Int, lungeReps: Int) {
        self.startedAt = startedAt
        self.squatReps = squatReps
        self.lungeReps = lungeReps
    }
}
