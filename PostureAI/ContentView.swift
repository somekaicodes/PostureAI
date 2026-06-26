import ARKit
import Combine
import SwiftUI

// Holds the latest analysis result for the UI to display.
final class SquatViewModel: ObservableObject {
    @Published var repCount = 0
    @Published var kneeAngle: Float = 0
    @Published var insufficientDepth = false
    @Published var excessiveForwardLean = false
    @Published var kneesCavingIn = false
    @Published var exercise = "—"

    func apply(_ result: SquatResult) {
        repCount = result.repCount
        kneeAngle = result.kneeAngle
        insufficientDepth = result.insufficientDepth
        excessiveForwardLean = result.excessiveForwardLean
        kneesCavingIn = result.kneesCavingIn
    }

    func applyExercise(_ prediction: ExercisePrediction) {
        exercise = "\(prediction.label)  \(Int(prediction.confidence * 100))%"
    }
}

struct ContentView: View {
    @StateObject private var viewModel = SquatViewModel()

    var body: some View {
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
    }

    private var repPanel: some View {
        VStack(spacing: 4) {
            Text("\(viewModel.repCount)")
                .font(.system(size: 72, weight: .bold, design: .rounded))
            Text("reps")
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
}

#Preview {
    ContentView()
}
