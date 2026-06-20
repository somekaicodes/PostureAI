import ARKit
import Combine
import SwiftUI

// Holds the latest analysis result for the UI to display.
final class SquatViewModel: ObservableObject {
    @Published var repCount = 0
    @Published var insufficientDepth = false
    @Published var excessiveForwardLean = false
    @Published var kneesCavingIn = false

    func apply(_ result: SquatResult) {
        repCount = result.repCount
        insufficientDepth = result.insufficientDepth
        excessiveForwardLean = result.excessiveForwardLean
        kneesCavingIn = result.kneesCavingIn
    }
}

struct ContentView: View {
    @StateObject private var viewModel = SquatViewModel()

    var body: some View {
        ZStack {
            if ARBodyTrackingConfiguration.isSupported {
                BodyTrackingView { viewModel.apply($0) }
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
