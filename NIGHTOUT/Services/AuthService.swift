import Foundation
import Supabase

/// Authentication service for sign in/up operations
final class AuthService: @unchecked Sendable {
    static let shared = AuthService()

    private var client: SupabaseClient? {
        SupabaseManager.shared.client
    }

    private init() {}

    // MARK: - Sign In

    /// Sign in with email and password
    func signIn(email: String, password: String) async throws {
        guard let client else {
            throw AuthError.notConfigured
        }

        try await client.auth.signIn(email: email, password: password)
    }

    /// Sign in with magic link (passwordless)
    func signInWithMagicLink(email: String) async throws {
        guard let client else {
            throw AuthError.notConfigured
        }

        try await client.auth.signInWithOTP(email: email)
    }

    /// Sign in with Apple
    func signInWithApple(idToken: String, nonce: String) async throws {
        guard let client else {
            throw AuthError.notConfigured
        }

        try await client.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
        )
    }

    // MARK: - Sign Up

    /// Create new account with email and password
    func signUp(email: String, password: String, username: String, displayName: String) async throws {
        guard let client else {
            throw AuthError.notConfigured
        }

        // Create auth user
        let response = try await client.auth.signUp(email: email, password: password)

        let userId = response.user.id

        // Create profile
        let profile = SupabaseProfileInsert(
            id: userId,
            username: username,
            displayName: displayName,
            email: email
        )

        try await client.from("profiles")
            .upsert(profile)
            .execute()
    }

    // MARK: - Sign Out

    /// Sign out current user
    func signOut() async throws {
        guard let client else {
            throw AuthError.notConfigured
        }

        try await client.auth.signOut()
    }

    // MARK: - Password Reset

    /// Send password reset email
    func resetPassword(email: String) async throws {
        guard let client else {
            throw AuthError.notConfigured
        }

        try await client.auth.resetPasswordForEmail(email)
    }

    /// Update password (when logged in)
    func updatePassword(newPassword: String) async throws {
        guard let client else {
            throw AuthError.notConfigured
        }

        try await client.auth.update(user: .init(password: newPassword))
    }

    // MARK: - Session

    /// Get current session
    func getSession() async throws -> Session? {
        guard let client else {
            throw AuthError.notConfigured
        }

        return try await client.auth.session
    }

    /// Get current user
    func getCurrentUser() async throws -> AuthUser? {
        guard let client else {
            throw AuthError.notConfigured
        }

        return try await client.auth.user()
    }

    /// Refresh session if needed
    func refreshSession() async throws {
        guard let client else {
            throw AuthError.notConfigured
        }

        _ = try await client.auth.refreshSession()
    }
}

// MARK: - Auth Errors
enum AuthError: LocalizedError {
    case notConfigured
    case userCreationFailed
    case profileCreationFailed
    case invalidCredentials
    case emailNotVerified
    case userNotFound
    case sessionExpired

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Authentication service is not configured"
        case .userCreationFailed:
            return "Failed to create user account"
        case .profileCreationFailed:
            return "Failed to create user profile"
        case .invalidCredentials:
            return "Invalid email or password"
        case .emailNotVerified:
            return "Please verify your email address"
        case .userNotFound:
            return "User not found"
        case .sessionExpired:
            return "Session has expired. Please sign in again"
        }
    }
}
