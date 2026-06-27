import FirebaseFirestore
import Foundation

// A workout session as stored in Firestore, ready to rebuild a WorkoutSession.
struct RemoteSession {
    let id: UUID
    let startedAt: Date
    let squatReps: Int
    let lungeReps: Int

    init?(_ data: [String: Any]) {
        guard let idString = data["id"] as? String, let id = UUID(uuidString: idString),
              let startedAt = (data["startedAt"] as? Timestamp)?.dateValue(),
              let squatReps = (data["squatReps"] as? NSNumber)?.intValue,
              let lungeReps = (data["lungeReps"] as? NSNumber)?.intValue else {
            return nil
        }
        self.id = id
        self.startedAt = startedAt
        self.squatReps = squatReps
        self.lungeReps = lungeReps
    }
}

// Reads and writes workout sessions under users/{uid}/sessions/{sessionID}.
struct FirestoreService {
    private let db = Firestore.firestore()

    private func sessions(for uid: String) -> CollectionReference {
        db.collection("users").document(uid).collection("sessions")
    }

    func upload(_ session: WorkoutSession, for uid: String) async throws {
        try await sessions(for: uid).document(session.id.uuidString).setData([
            "id": session.id.uuidString,
            "startedAt": Timestamp(date: session.startedAt),
            "squatReps": session.squatReps,
            "lungeReps": session.lungeReps,
        ])
    }

    func fetchAll(for uid: String) async throws -> [RemoteSession] {
        let snapshot = try await sessions(for: uid).getDocuments()
        return snapshot.documents.compactMap { RemoteSession($0.data()) }
    }
}
