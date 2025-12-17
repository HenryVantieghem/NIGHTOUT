//
//  SessionManager.swift
//  NIGHTOUT
//
//  Centralized session state management - Single source of truth for auth state
//

import Foundation
import Observation
import Supabase

@MainActor
@Observable
final class SessionManager {
    static let shared = SessionManager()

    // MARK: - Published State
    private(set) var session: Session?
    private(set) var currentUser: AuthUser?
    private(set) var isAuthenticated: Bool = false
    private(set) var isLoading: Bool = true  // Track restoration in progress
    private(set) var isGuestMode: Bool = false  // Track guest mode separately

    // MARK: - Computed Properties
    var userId: UUID? {
        currentUser?.id
    }
    
    /// Get user email from session userMetadata
    var userEmail: String? {
        guard let session = session else { return nil }
        // Email is stored in userMetadata in Supabase
        return session.user.userMetadata["email"]?.stringValue
    }

    /// Returns true if user can access app (authenticated or guest)
    var canAccessApp: Bool {
        isAuthenticated || isGuestMode
    }

    // MARK: - Initialization
    private init() {
        // Don't call restoreSession here - let NIGHTOUTApp handle it
        // This prevents race conditions with view rendering
    }

    // MARK: - Session Management

    /// Restore session from Supabase on app launch
    /// Call this from NIGHTOUTApp.body with .task modifier
    func restoreSession() async {
        isLoading = true
        defer { isLoading = false }

        // Get current session from Supabase
        let session = supabase.auth.currentSession

        // Check if session exists and is not expired
        if let session = session, !session.isExpired {
            self.session = session
            self.currentUser = session.user
            self.isAuthenticated = true
            
            // Note: Demo seeding handled by NIGHTOUTApp with ModelContext
        } else {
            // Session is expired or doesn't exist
            self.session = nil
            self.currentUser = nil
            self.isAuthenticated = false
        }
    }

    /// Update session after sign in/sign up
    func updateSession(_ newSession: Session?) {
        session = newSession
        currentUser = newSession?.user
        isAuthenticated = newSession != nil
        isLoading = false
    }

    /// Clear session on sign out
    func clearSession() {
        session = nil
        currentUser = nil
        isAuthenticated = false
        isGuestMode = false
        isLoading = false
    }

    // MARK: - Guest Mode

    /// Enable guest mode for limited app access without authentication
    /// Guest users can explore the app but cannot:
    /// - Create nights that sync to cloud
    /// - Access social features (friends, comments, likes)
    /// - Have their data persisted across devices
    func enableGuestMode() {
        isGuestMode = true
        isAuthenticated = false
        session = nil
        currentUser = nil
        isLoading = false
    }

    /// Check if user is in guest mode (for feature gating)
    func requiresAuthentication(for feature: GuestRestrictedFeature) -> Bool {
        return isGuestMode && feature.requiresAuth
    }
}

// MARK: - Guest Mode Feature Restrictions

enum GuestRestrictedFeature {
    case createNight
    case syncToCloud
    case socialFeed
    case friends
    case comments
    case likes
    case liveUpdates
    case achievements

    var requiresAuth: Bool {
        switch self {
        case .createNight:
            return false  // Can create local-only nights
        case .syncToCloud, .socialFeed, .friends, .comments, .likes, .liveUpdates, .achievements:
            return true
        }
    }

    var restrictionMessage: String {
        switch self {
        case .createNight:
            return ""
        case .syncToCloud:
            return "Sign in to sync your nights across devices"
        case .socialFeed:
            return "Sign in to see what your friends are up to"
        case .friends:
            return "Sign in to add and manage friends"
        case .comments:
            return "Sign in to comment on nights"
        case .likes:
            return "Sign in to like nights"
        case .liveUpdates:
            return "Sign in to share live updates"
        case .achievements:
            return "Sign in to unlock and view achievements"
        }
    }
}
