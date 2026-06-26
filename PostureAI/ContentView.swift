import ARKit
import Combine
import SwiftData
import SwiftUI

// Holds the current workout session: live analysis plus per-exercise rep counts.
final class SquatViewModel: ObservableObject {
    @Published var squatReps = 0
    @Published var lungeReps = 0
    @Published var kneeAngle: Float = 0
    @Published var insufficientDepth = false
    @Published var excessiveForwardLean = false
    @Published var kneesCavingIn = false
    @Published var exercise = "—"

    private(set) var startedAt = Date()
    private var currentLabel = "idle"

    var totalReps: Int { squatReps + lungeReps }

    // Begin a fresh session: clear counts and stamp the start time.
    func start() {
        startedAt = Date()
        squatReps = 0
        lungeReps = 0
    }

    func apply(_ result: SquatResult) {
        kneeAngle = result.kneeAngle
        insufficientDepth = result.insufficientDepth
        excessiveForwardLean = result.excessiveForwardLean
        kneesCavingIn = result.kneesCavingIn

        // Credit each completed rep to the exercise currently classified. The
        // rep counter is squat-tuned, so anything but lunge falls back to squat.
        if result.repJustCompleted {
            if currentLabel == "lunge" {
                lungeReps += 1
            } else {
                squatReps += 1
            }
        }
    }

    func applyExercise(_ prediction: ExercisePrediction) {
        currentLabel = prediction.label
        exercise = "\(prediction.label)  \(Int(prediction.confidence * 100))%"
    }
}

struct ContentView: View {
    @StateObject private var viewModel = SquatViewModel()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            ZStack {
                if ARBodyTrackingConfiguration.isSupported {
                    BodyTrackingView(onResult: { viewModel.apply($0) },
                                     onExercise: { viewModel.applyExercise($0) })
                        .ignoresSafeArea()
                } else {
                    unsupportedMessage
                }

                VStack {
                    Spacer()
                    repPanel
                }
            }
            .navigationTitle("Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        HistoryView()
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
            }
            .onAppear { viewModel.start() }
        }
    }

    private var repPanel: some View {
        VStack(spacing: 4) {
            Text("\(viewModel.totalReps)")
                .font(.system(size: 72, weight: .bold, design: .rounded))
            Text("reps")
                .foregroundStyle(.secondary)

            // Per-exercise breakdown for the current session.
            Text("squat \(viewModel.squatReps) · lunge \(viewModel.lungeReps)")
                .font(.footnote)
                .foregroundStyle(.secondary)

            // Live knee angle — use this to calibrate the rep thresholds.
            Text("knee \(Int(viewModel.kneeAngle))°")
                .font(.system(.footnote, design: .monospaced))
                .foregroundStyle(.secondary)

            // Exercise named by the Core ML action classifier.
            Text(viewModel.exercise.uppercased())
                .font(.system(.subheadline, design: .rounded).bold())
                .foregroundStyle(.tint)

            if viewModel.insufficientDepth {
                Label("Go deeper", systemImage: "arrow.down.circle")
            }
            if viewModel.excessiveForwardLean {
                Label("Chest up", systemImage: "figure.stand")
            }
            if viewModel.kneesCavingIn {
                Label("Push knees out", systemImage: "arrow.left.and.right.circle")
            }

            Button("Save Workout") { saveWorkout() }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.totalReps == 0)
                .padding(.top, 8)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding()
    }

    private var unsupportedMessage: some View {
        Text("Body tracking needs an iPhone with an A12 chip or newer.")
            .multilineTextAlignment(.center)
            .padding()
    }

    // Log the current session, then reset for the next one.
    private func saveWorkout() {
        let session = WorkoutSession(startedAt: viewModel.startedAt,
                                     squatReps: viewModel.squatReps,
                                     lungeReps: viewModel.lungeReps)
        modelContext.insert(session)
        viewModel.start()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: WorkoutSession.self, inMemory: true)
}
