import AuthenticationServices
import SwiftUI

// Settings sheet: sign-in / profile, plus the daily reminder controls.
struct AccountView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss

    @AppStorage("reminderEnabled") private var reminderEnabled = false
    @AppStorage("reminderHour") private var reminderHour = 18
    @AppStorage("reminderMinute") private var reminderMinute = 0

    @State private var appleNonce = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    if authService.isSignedIn {
                        signedIn
                    } else {
                        signInOptions
                    }
                }

                Section("Daily Reminder") {
                    Toggle("Remind me to exercise", isOn: $reminderEnabled)
                    if reminderEnabled {
                        DatePicker("Time", selection: reminderTime, displayedComponents: .hourAndMinute)
                    }
                }
            }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onChange(of: reminderEnabled) { _, enabled in
                if enabled {
                    enableReminder()
                } else {
                    NotificationService.cancelReminder()
                }
            }
        }
    }

    private var signedIn: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(authService.displayName)
                .font(.headline)
            Text("Your workouts sync to the cloud.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Sign Out", role: .destructive) {
                try? authService.signOut()
            }
        }
    }

    private var signInOptions: some View {
        VStack(spacing: 12) {
            Text("Sign in to sync your workouts across devices.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: signInWithGoogle) {
                Label("Sign in with Google", systemImage: "g.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            SignInWithAppleButton(.signIn) { request in
                appleNonce = randomNonceString()
                request.requestedScopes = [.fullName, .email]
                request.nonce = sha256(appleNonce)
            } onCompletion: { result in
                handleAppleResult(result)
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 44)
        }
    }

    private func signInWithGoogle() {
        guard let presenter = topViewController() else { return }
        Task {
            try? await authService.signInWithGoogle(presenting: presenter)
        }
    }

    private func handleAppleResult(_ result: Result<ASAuthorization, Error>) {
        guard case .success(let authorization) = result,
              let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            return
        }
        let nonce = appleNonce
        Task {
            try? await authService.signInWithApple(credential: credential, nonce: nonce)
        }
    }

    // The reminder time as a Date the DatePicker can bind to.
    private var reminderTime: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(from: DateComponents(hour: reminderHour, minute: reminderMinute)) ?? Date()
            },
            set: { newValue in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                reminderHour = parts.hour ?? 18
                reminderMinute = parts.minute ?? 0
                if reminderEnabled {
                    NotificationService.scheduleDailyReminder(hour: reminderHour, minute: reminderMinute)
                }
            }
        )
    }

    private func enableReminder() {
        Task {
            if await NotificationService.requestAuthorization() {
                NotificationService.scheduleDailyReminder(hour: reminderHour, minute: reminderMinute)
            } else {
                reminderEnabled = false // permission denied: keep the toggle off
            }
        }
    }
}
