import ARKit
import Combine
import RealityKit
import SwiftUI

// Runs the camera + ARKit body tracking and feeds each frame's joints into
// libposture. Reports the latest result back through `onResult`.
struct BodyTrackingView: UIViewRepresentable {
    let onResult: (SquatResult) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onResult: onResult)
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
        private let onResult: (SquatResult) -> Void
        private var frameSubscription: Cancellable?

        init(onResult: @escaping (SquatResult) -> Void) {
            self.onResult = onResult
        }

        // Process one body-tracking frame on every scene update (main thread).
        func start(on arView: ARView) {
            frameSubscription = arView.scene.subscribe(to: SceneEvents.Update.self) { [weak self, weak arView] _ in
                guard let self, let frame = arView?.session.currentFrame else { return }
                guard let body = frame.anchors.compactMap({ $0 as? ARBodyAnchor }).first,
                      let joints = Coordinator.squatJoints(from: body) else { return }

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
                let leftKnee = position(skeleton, "left_leg_joint"),
                let rightKnee = position(skeleton, "right_leg_joint"),
                let leftAnkle = position(skeleton, "left_foot_joint"),
                let rightAnkle = position(skeleton, "right_foot_joint")
            else {
                return nil
            }

            return SquatJoints(
                shoulder: (leftShoulder + rightShoulder) / 2,
                hip: SIMD3<Float>(0, 0, 0), // the hips joint is the skeleton's origin
                leftKnee: leftKnee,
                rightKnee: rightKnee,
                leftAnkle: leftAnkle,
                rightAnkle: rightAnkle
            )
        }
    }
}
