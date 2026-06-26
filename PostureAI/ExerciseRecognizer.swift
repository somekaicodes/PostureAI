import CoreML
import Foundation
import ImageIO
import Vision

// One exercise guess from the Create ML action classifier.
struct ExercisePrediction {
    let label: String
    let confidence: Float
}

// Lets us hand a non-Sendable value to a background queue. Safe here because
// the camera frame is only read, never mutated, off the main thread.
private struct Unchecked<T>: @unchecked Sendable {
    let value: T
    init(_ value: T) { self.value = value }
}

// Runs Vision body pose on the camera feed and feeds a rolling 60-frame window
// into the ExerciseClassifier Core ML model to name the current exercise. The
// heavy work runs on a background queue so it never stalls AR rendering.
final class ExerciseRecognizer: @unchecked Sendable {
    private let model: ExerciseClassifier
    private let poseRequest = VNDetectHumanBodyPoseRequest()
    private let queue = DispatchQueue(label: "ExerciseRecognizer")

    // The model was trained on 60-frame windows at 30 fps.
    private let windowSize = 60
    private let sampleInterval = 1.0 / 30.0

    private var window: [MLMultiArray] = [] // touched only on `queue`
    private var lastSampleTime: TimeInterval = 0 // touched only on the main thread
    private var isBusy = false // touched only on the main thread

    init?() {
        guard let model = try? ExerciseClassifier(configuration: MLModelConfiguration()) else {
            return nil
        }
        self.model = model
    }

    // Feed one camera frame (call on the main thread). Delivers a prediction on
    // the main thread when the window is full. Skips frames while one is in
    // flight, so the background work never backs up.
    func process(pixelBuffer: CVPixelBuffer,
                 timestamp: TimeInterval,
                 completion: @escaping (ExercisePrediction) -> Void) {
        guard !isBusy, timestamp - lastSampleTime >= sampleInterval else { return }
        lastSampleTime = timestamp
        isBusy = true

        let frame = Unchecked(pixelBuffer)
        let done = Unchecked(completion)
        queue.async { [self] in
            let prediction = classify(frame.value)
            DispatchQueue.main.async {
                self.isBusy = false
                if let prediction { done.value(prediction) }
            }
        }
    }

    // Body pose -> rolling window -> model prediction. Runs on `queue`.
    private func classify(_ pixelBuffer: CVPixelBuffer) -> ExercisePrediction? {
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
