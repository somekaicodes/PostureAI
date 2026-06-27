import SwiftUI

// Profile sheet: sign-in options when signed out, profile + sign-out when in.
struct AccountView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if authService.isSignedIn {
                    signedIn
                } else {
                    signInOptions
                }
            }
            .padding()
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var signedIn: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            Text(authService.displayName)
                .font(.headline)
            Text("Your workouts sync to the cloud.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Sign Out", role: .destructive) {
                try? authService.signOut()
            }
            .buttonStyle(.bordered)
        }
    }

    private var signInOptions: some View {
        VStack(spacing: 16) {
            Text("Sign in to sync your workouts across devices.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button(action: signInWithGoogle) {
                Label("Sign in with Google", systemImage: "g.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func signInWithGoogle() {
        guard let presenter = topViewController() else { return }
        Task {
            try? await authService.signInWithGoogle(presenting: presenter)
        }
    }
}
