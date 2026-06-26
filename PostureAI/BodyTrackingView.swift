import ARKit
import Combine
import RealityKit
import SwiftUI

// Runs the camera + ARKit body tracking and feeds each frame's joints into
// libposture. Reports the rep result through `onResult` and the classified
// exercise through `onExercise`.
struct BodyTrackingView: UIViewRepresentable {
    let onResult: (SquatResult) -> Void
    let onExercise: (ExercisePrediction) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onResult: onResult, onExercise: onExercise)
    }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.session.run(ARBodyTrackingConfiguration())
        context.coordinator.start(on: arView)
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    final class Coordinator {
        private let core = PostureCore()
        private let overlay = SkeletonOverlay()
        private let recognizer = ExerciseRecognizer()
        private let onResult: (SquatResult) -> Void
        private let onExercise: (ExercisePrediction) -> Void
        private var frameSubscription: Cancellable?

        init(onResult: @escaping (SquatResult) -> Void,
             onExercise: @escaping (ExercisePrediction) -> Void) {
            self.onResult = onResult
            self.onExercise = onExercise
        }

        // Process one body-tracking frame on every scene update (main thread).
        func start(on arView: ARView) {
            overlay.addToScene(arView)
            frameSubscription = arView.scene.subscribe(to: SceneEvents.Update.self) { [weak self, weak arView] _ in
                guard let self, let frame = arView?.session.currentFrame else { return }

                // Name the exercise from the camera image via Vision + Core ML.
                // Runs on a background queue so it never stalls AR rendering.
                self.recognizer?.process(pixelBuffer: frame.capturedImage,
                                         timestamp: frame.timestamp) { [weak self] prediction in
                    self?.onExercise(prediction)
                }

                guard let body = frame.anchors.compactMap({ $0 as? ARBodyAnchor }).first else { return }

                self.overlay.update(with: body)

                guard let joints = Coordinator.squatJoints(from: body) else { return }
                let result = self.core.update(joints: joints, timestamp: frame.timestamp)
                self.onResult(result)
            }
        }

        // Read one joint's position (relative to the hips) from the skeleton.
        private static func position(_ skeleton: ARSkeleton3D, _ name: String) -> SIMD3<Float>? {
            guard let transform = skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: name)) else {
                return nil
            }
            let t = transform.columns.3
            return SIMD3(t.x, t.y, t.z)
        }

        // Map ARKit's skeleton to the joints libposture needs for a squat.
        private static func squatJoints(from body: ARBodyAnchor) -> SquatJoints? {
            let skeleton = body.skeleton
            guard
                let leftShoulder = position(skeleton, "left_shoulder_1_joint"),
                let rightShoulder = position(skeleton, "right_shoulder_1_joint"),
                let leftHip = position(skeleton, "left_upLeg_joint"),
                let rightHip = position(skeleton, "right_upLeg_joint"),
                let leftKnee = position(skeleton, "left_leg_joint"),
                let rightKnee = position(skeleton, "right_leg_joint"),
                let leftAnkle = position(skeleton, "left_foot_joint"),
                let rightAnkle = position(skeleton, "right_foot_joint")
            else {
                return nil
            }

            return SquatJoints(
                shoulder: (leftShoulder + rightShoulder) / 2,
                leftHip: leftHip,
                rightHip: rightHip,
                leftKnee: leftKnee,
                rightKnee: rightKnee,
                leftAnkle: leftAnkle,
                rightAnkle: rightAnkle
            )
        }
    }
}
