import Foundation
import SwiftData

// One logged workout: when it started and how many reps of each exercise.
// `id` is stable across devices so it doubles as the Firestore document key.
@Model
final class WorkoutSession {
    var id: UUID = UUID()
    var startedAt: Date
    var squatReps: Int
    var lungeReps: Int

    init(id: UUID = UUID(), startedAt: Date, squatReps: Int, lungeReps: Int) {
        self.id = id
        self.startedAt = startedAt
        self.squatReps = squatReps
        self.lungeReps = lungeReps
    }
}
