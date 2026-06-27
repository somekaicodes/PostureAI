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

    // Apple sign-in goes here once the capability is available (paid account).

    func signOut() throws {
        GIDSignIn.sharedInstance.signOut()
        try Auth.auth().signOut()
    }
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
