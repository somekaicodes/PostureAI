import Testing
import Foundation
import simd
@testable import PostureAI

// Drives a full squat through the Swift wrapper and the bridged C++ core,
// confirming the whole pipeline is callable end to end from Swift.
struct PostureCoreTests {

    // Tall, straight-legged stance: high knee angle.
    private func standing() -> SquatJoints {
        SquatJoints(
            shoulder: [0, 2.6, 0],
            leftHip: [-0.2, 2.0, 0],
            rightHip: [0.2, 2.0, 0],
            leftKnee: [-0.2, 1.0, 0],
            rightKnee: [0.2, 1.0, 0],
            leftAnkle: [-0.2, 0.0, 0],
            rightAnkle: [0.2, 0.0, 0]
        )
    }

    // Deep, upright squat with knees over the feet: low knee angle, good form.
    private func bottom() -> SquatJoints {
        SquatJoints(
            shoulder: [0, 1.6, 0],
            leftHip: [-0.2, 1.0, 0],
            rightHip: [0.2, 1.0, 0],
            leftKnee: [-0.2, 0.0, 0],
            rightKnee: [0.2, 0.0, 0],
            leftAnkle: [-0.2, 0.3, 0.5],
            rightAnkle: [0.2, 0.3, 0.5]
        )
    }

    @Test func countsOneRepWithGoodFormThroughTheBridge() {
        let core = PostureCore()
        var t: TimeInterval = 0
        let step = 1.0 / 60.0

        var result = core.update(joints: standing(), timestamp: t)
        for _ in 0..<39 { t += step; result = core.update(joints: standing(), timestamp: t) }
        for _ in 0..<40 { t += step; result = core.update(joints: bottom(), timestamp: t) }
        for _ in 0..<40 { t += step; result = core.update(joints: standing(), timestamp: t) }

        #expect(result.repCount == 1)
        #expect(result.insufficientDepth == false)
        #expect(result.excessiveForwardLean == false)
        #expect(result.kneesCavingIn == false)
    }
}
