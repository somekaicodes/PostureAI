//
//  PostureAIApp.swift
//  PostureAI
//
//  Created by Kai Kim on 2026-06-19.
//

import SwiftData
import SwiftUI

@main
struct PostureAIApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: WorkoutSession.self)
    }
}
