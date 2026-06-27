//
//  PostureAIApp.swift
//  PostureAI
//
//  Created by Kai Kim on 2026-06-19.
//

import FirebaseCore
import GoogleSignIn
import SwiftData
import SwiftUI

@main
struct PostureAIApp: App {
    @State private var authService: AuthService

    init() {
        FirebaseApp.configure()
        _authService = State(initialValue: AuthService())
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authService)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
        .modelContainer(for: WorkoutSession.self)
    }
}
