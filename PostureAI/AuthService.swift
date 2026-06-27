import AuthenticationServices
import CryptoKit
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import UIKit

// Firebase authentication. Sign-in is opt-in — the app works fully offline
// without an account. Currently supports Google; Apple slots in later once a
// paid Apple Developer account enables the "Sign in with Apple" capability.
@MainActor
@Observable
final class AuthService {
    var user: User?

    private var listener: AuthStateDidChangeListenerHandle?

    init() {
        listener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
        }
    }

    var isSignedIn: Bool { user != nil }
    var displayName: String { user?.displayName ?? user?.email ?? "Signed in" }

    // Get a Google token, then exchange it for a Firebase credential.
    func signInWithGoogle(presenting: UIViewController) async throws {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenting)
        guard let idToken = result.user.idToken?.tokenString else { return }
        let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                       accessToken: result.user.accessToken.tokenString)
        try await Auth.auth().signIn(with: credential)
    }

    // Exchange an Apple ID credential for a Firebase credential and sign in.
    // `nonce` is the raw (unhashed) value used when making the Apple request.
    func signInWithApple(credential: ASAuthorizationAppleIDCredential, nonce: String) async throws {
        guard let tokenData = credential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8) else { return }
        let firebaseCredential = OAuthProvider.appleCredential(withIDToken: idToken,
                                                              rawNonce: nonce,
                                                              fullName: credential.fullName)
        try await Auth.auth().signIn(with: firebaseCredential)
    }

    func signOut() throws {
        GIDSignIn.sharedInstance.signOut()
        try Auth.auth().signOut()
    }
}

// A random string to tie an Apple sign-in request to its response (replay-safe).
func randomNonceString(length: Int = 32) -> String {
    let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
    return String((0..<length).map { _ in charset.randomElement()! })
}

// SHA256 hash, sent to Apple while we keep the raw nonce for Firebase.
func sha256(_ input: String) -> String {
    SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
}

// The view controller to present the Google sign-in sheet from.
@MainActor
func topViewController() -> UIViewController? {
    let scene = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .first { $0.activationState == .foregroundActive }
    var controller = scene?.keyWindow?.rootViewController
    while let presented = controller?.presentedViewController {
        controller = presented
    }
    return controller
}
