import SwiftData
import SwiftUI

// Lists past workout sessions, newest first.
struct HistoryView: View {
    @Query(sort: \WorkoutSession.startedAt, order: .reverse) private var sessions: [WorkoutSession]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List {
            if sessions.isEmpty {
                ContentUnavailableView("No workouts yet",
                                       systemImage: "figure.strengthtraining.traditional",
                                       description: Text("Saved workouts will show up here."))
            } else {
                ForEach(sessions) { session in
                    row(for: session)
                }
                .onDelete(perform: delete)
            }
        }
        .navigationTitle("History")
    }

    private func row(for session: WorkoutSession) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(session.startedAt, format: .dateTime.month().day().year().hour().minute())
                .font(.headline)
            Text("Squat \(session.squatReps) · Lunge \(session.lungeReps)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sessions[index])
        }
    }
}
