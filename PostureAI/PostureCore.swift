import Foundation
import simd

// The 3D joints needed to analyze one squat frame. Positions are in metres,
// matching what ARKit's body-tracking skeleton provides.
struct SquatJoints {
    var shoulder: SIMD3<Float>
    var leftHip: SIMD3<Float>
    var rightHip: SIMD3<Float>
    var leftKnee: SIMD3<Float>
    var rightKnee: SIMD3<Float>
    var leftAnkle: SIMD3<Float>
    var rightAnkle: SIMD3<Float>
}

// The analysis result for one frame, in plain Swift types.
struct SquatResult {
    var repCount: Int
    var kneeAngle: Float          // smoothed, degrees
    var repJustCompleted: Bool
    var insufficientDepth: Bool
    var excessiveForwardLean: Bool
    var kneesCavingIn: Bool
}

// Swift-friendly wrapper around the libposture C analysis session.
final class PostureCore {
    private let session: OpaquePointer

    init() {
        session = posture_session_create()
    }

    deinit {
        posture_session_destroy(session)
    }

    // Start a new set: clears the rep count and history.
    func reset() {
        posture_session_reset(session)
    }

    // Feed one frame of joints and get the latest analysis result.
    func update(joints: SquatJoints, timestamp: TimeInterval) -> SquatResult {
        var frame = PostureFrame()
        frame.timestamp = timestamp
        frame.shoulder = vec(joints.shoulder)
        frame.leftHip = vec(joints.leftHip)
        frame.rightHip = vec(joints.rightHip)
        frame.leftKnee = vec(joints.leftKnee)
        frame.rightKnee = vec(joints.rightKnee)
        frame.leftAnkle = vec(joints.leftAnkle)
        frame.rightAnkle = vec(joints.rightAnkle)

        let result = posture_session_update(session, frame)

        return SquatResult(
            repCount: Int(result.repCount),
            kneeAngle: result.kneeAngle,
            repJustCompleted: result.repJustCompleted != 0,
            insufficientDepth: result.insufficientDepth != 0,
            excessiveForwardLean: result.excessiveForwardLean != 0,
            kneesCavingIn: result.kneesCavingIn != 0
        )
    }

    private func vec(_ v: SIMD3<Float>) -> PostureVec3 {
        PostureVec3(x: v.x, y: v.y, z: v.z)
    }
}
