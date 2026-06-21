import ARKit
import RealityKit

// Draws the tracked body as spheres (joints) and thin bars (bones), following
// the ARKit skeleton each frame. We render a curated set of major joints rather
// than ARKit's full 91-joint skeleton, so fingers and face joints don't clutter
// the overlay. The skeleton stops at the neck, leaving the face clear.
final class SkeletonOverlay {
    private let root = Entity()

    // The major joints we draw, by ARKit joint name.
    private let jointNames = [
        "neck_1_joint", "spine_7_joint", "hips_joint",
        "left_shoulder_1_joint", "left_arm_joint", "left_forearm_joint", "left_hand_joint",
        "right_shoulder_1_joint", "right_arm_joint", "right_forearm_joint", "right_hand_joint",
        "left_upLeg_joint", "left_leg_joint", "left_foot_joint",
        "right_upLeg_joint", "right_leg_joint", "right_foot_joint",
    ]

    // Bones connect two named joints into a recognizable skeleton. There is no
    // bone above the neck, so nothing crosses the face.
    private let bonePairs: [(String, String)] = [
        ("hips_joint", "spine_7_joint"),
        ("spine_7_joint", "neck_1_joint"),
        ("spine_7_joint", "left_shoulder_1_joint"),
        ("spine_7_joint", "right_shoulder_1_joint"),
        ("left_shoulder_1_joint", "left_arm_joint"),
        ("left_arm_joint", "left_forearm_joint"),
        ("left_forearm_joint", "left_hand_joint"),
        ("right_shoulder_1_joint", "right_arm_joint"),
        ("right_arm_joint", "right_forearm_joint"),
        ("right_forearm_joint", "right_hand_joint"),
        ("hips_joint", "left_upLeg_joint"),
        ("hips_joint", "right_upLeg_joint"),
        ("left_upLeg_joint", "left_leg_joint"),
        ("left_leg_joint", "left_foot_joint"),
        ("right_upLeg_joint", "right_leg_joint"),
        ("right_leg_joint", "right_foot_joint"),
    ]

    private var jointEntities: [String: ModelEntity] = [:]
    private var boneEntities: [ModelEntity] = []

    private let jointRadius: Float = 0.015
    private let boneHeight: Float = 1.0 // base mesh height; we scale it per bone

    // Attach the overlay to the scene once.
    func addToScene(_ arView: ARView) {
        let anchor = AnchorEntity(world: .zero)
        anchor.addChild(root)
        arView.scene.addAnchor(anchor)
    }

    // Move every joint and bone to match the latest body anchor.
    func update(with body: ARBodyAnchor) {
        root.transform = Transform(matrix: body.transform)
        buildIfNeeded()

        let skeleton = body.skeleton

        // Current position of each joint, when ARKit is tracking it.
        var positions: [String: SIMD3<Float>] = [:]
        for name in jointNames {
            guard let transform = skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: name)) else {
                jointEntities[name]?.isEnabled = false
                continue
            }
            let column = transform.columns.3
            let position = SIMD3(column.x, column.y, column.z)
            positions[name] = position

            if let sphere = jointEntities[name] {
                sphere.isEnabled = true
                sphere.position = position
            }
        }

        // A bone shows only when both of its joints are tracked.
        for (index, pair) in bonePairs.enumerated() {
            let bone = boneEntities[index]
            guard let start = positions[pair.0], let end = positions[pair.1] else {
                bone.isEnabled = false
                continue
            }
            bone.isEnabled = true
            placeBone(bone, from: start, to: end)
        }
    }

    // Create the sphere and bar entities once.
    private func buildIfNeeded() {
        guard jointEntities.isEmpty else { return }

        let jointMesh = MeshResource.generateSphere(radius: jointRadius)
        let jointMaterial = SimpleMaterial(color: .green, isMetallic: false)
        for name in jointNames {
            let sphere = ModelEntity(mesh: jointMesh, materials: [jointMaterial])
            root.addChild(sphere)
            jointEntities[name] = sphere
        }

        let boneMesh = MeshResource.generateBox(size: [0.02, boneHeight, 0.02])
        let boneMaterial = SimpleMaterial(color: .white, isMetallic: false)
        for _ in bonePairs {
            let bar = ModelEntity(mesh: boneMesh, materials: [boneMaterial])
            root.addChild(bar)
            boneEntities.append(bar)
        }
    }

    // Stretch and rotate one bar to span from one joint to another.
    private func placeBone(_ bone: ModelEntity, from start: SIMD3<Float>, to end: SIMD3<Float>) {
        let middle = (start + end) / 2
        let direction = end - start
        let length = simd_length(direction)

        bone.position = middle
        guard length > 0 else { return }

        // The bar's mesh runs along +Y, so aim that axis down the bone.
        bone.orientation = simd_quatf(from: [0, 1, 0], to: direction / length)
        bone.scale = [1, length / boneHeight, 1]
    }
}
