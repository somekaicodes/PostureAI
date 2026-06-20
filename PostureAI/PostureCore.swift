import Foundation

// Swift-friendly wrapper around the libposture C analysis session.
// Holds one squat-analysis session and feeds it frames of 3D joints.
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
    func update(_ frame: PostureFrame) -> PostureResult {
        posture_session_update(session, frame)
    }
}
