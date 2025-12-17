//
//  NIGHTOUTApp.swift
//  NIGHTOUT
//
//  The Strava for Going Out - iOS 26 Liquid Glass Edition
//

import SwiftUI
import SwiftData
import Supabase
import UIKit

@main
struct NIGHTOUTApp: App {
    // Session manager as state for environment injection
    @State private var sessionManager = SessionManager.shared
    
    init() {
        // Configure navigation bar appearance globally to ensure text is visible
        // This fixes the issue where navigation bar text has the same color as background
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .clear
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        
        // Set title text colors to ensure visibility on dark background
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor(white: 0.95, alpha: 1.0) // NightOutColors.chrome
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(white: 0.95, alpha: 1.0) // NightOutColors.chrome
        ]
        
        // Apply to all navigation bars
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Set bar button item colors to ensure visibility
        UINavigationBar.appearance().tintColor = UIColor(white: 0.78, alpha: 1.0) // NightOutColors.silver
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            User.self,
            Night.self,
            Drink.self,
            Venue.self,
            Media.self,
            MoodEntry.self,
            Achievement.self,
            Friendship.self,
            LocationPoint.self,
            CustomDrinkTemplate.self,
            LiveUpdate.self,
            Comment.self,
            Song.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(sessionManager)
                .preferredColorScheme(.dark)
                .task {
                    // Restore session on app launch
                    await sessionManager.restoreSession()
                }
                .onOpenURL { url in
                    Task {
                        do {
                            try await supabase.auth.session(from: url)
                        } catch {
                            print("[NIGHTOUTApp] Failed to handle deep link: \(error.localizedDescription)")
                        }
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
