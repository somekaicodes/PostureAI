import CoreML
import ImageIO
import Vision

// One exercise guess from the Create ML action classifier.
struct ExercisePrediction {
    let label: String
    let confidence: Float
}

// Runs Vision body pose on the camera feed and feeds a rolling 60-frame window
// into the ExerciseClassifier Core ML model to name the current exercise.
@MainActor
final class ExerciseRecognizer {
    private let model: ExerciseClassifier
    private let poseRequest = VNDetectHumanBodyPoseRequest()

    // The model was trained on 60-frame windows at 30 fps.
    private let windowSize = 60
    private let sampleInterval = 1.0 / 30.0

    private var window: [MLMultiArray] = []
    private var lastSampleTime: TimeInterval = 0

    init?() {
        guard let model = try? ExerciseClassifier(configuration: MLModelConfiguration()) else {
            return nil
        }
        self.model = model
    }

    // Feed one camera frame; returns a prediction once the window is full.
    func process(pixelBuffer: CVPixelBuffer, timestamp: TimeInterval) -> ExercisePrediction? {
        // Sample at the model's 30 fps rather than every ARKit frame.
        guard timestamp - lastSampleTime >= sampleInterval else { return nil }
        lastSampleTime = timestamp

        // Rear camera in portrait arrives rotated; `.right` puts it upright.
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])
        guard (try? handler.perform([poseRequest])) != nil,
              let pose = poseRequest.results?.first as? VNHumanBodyPoseObservation,
              let keypoints = try? pose.keypointsMultiArray() else {
            return nil
        }

        window.append(keypoints)
        if window.count > windowSize {
            window.removeFirst(window.count - windowSize)
        }
        guard window.count == windowSize, let poses = stack(window) else { return nil }

        guard let output = try? model.prediction(poses: poses) else { return nil }
        let label = output.label
        let confidence = Float(output.labelProbabilities[label] ?? 0)
        return ExercisePrediction(label: label, confidence: confidence)
    }

    // Stack 60 per-frame [1, 3, 18] arrays into one [60, 3, 18] array.
    private func stack(_ frames: [MLMultiArray]) -> MLMultiArray? {
        guard let first = frames.first else { return nil }
        let perFrame = first.count // 3 * 18 = 54 values
        let shape = [frames.count, first.shape[1].intValue, first.shape[2].intValue]
        guard let result = try? MLMultiArray(shape: shape as [NSNumber], dataType: .float32) else {
            return nil
        }

        for (frameIndex, frame) in frames.enumerated() {
            let base = frameIndex * perFrame
            for i in 0..<perFrame {
                result[base + i] = frame[i]
            }
        }
        return result
    }
}
