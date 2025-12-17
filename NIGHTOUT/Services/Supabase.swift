//
//  Supabase.swift
//  NIGHTOUT
//
//  Created by Henry Vantieghem on 12/7/25.
//

import Foundation
import Supabase

// MARK: - Configuration Error

enum SupabaseConfigurationError: LocalizedError {
    case missingSecretsFile
    case missingKey(String)
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .missingSecretsFile:
            return "Configuration file not found. Please contact support."
        case .missingKey(let key):
            return "Missing configuration for \(key). Please reinstall the app."
        case .invalidURL:
            return "Invalid server configuration. Please update the app."
        }
    }
}

// MARK: - Secrets Manager

enum Secrets {
    private static var cachedPlist: [String: Any]?

    static func value(_ key: String) throws -> String {
        // Load and cache plist
        if cachedPlist == nil {
            guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
                  let data = try? Data(contentsOf: url),
                  let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
                  let dict = plist as? [String: Any] else {
                throw SupabaseConfigurationError.missingSecretsFile
            }
            cachedPlist = dict
        }

        guard let value = cachedPlist?[key] as? String, !value.isEmpty else {
            throw SupabaseConfigurationError.missingKey(key)
        }
        return value
    }

    /// Legacy non-throwing accessor for backward compatibility
    /// Falls back to placeholder values that will fail gracefully at runtime
    static func valueOrPlaceholder(_ key: String) -> String {
        (try? value(key)) ?? "MISSING_\(key)"
    }
}

// MARK: - Supabase Client Manager

@Observable
final class SupabaseManager: @unchecked Sendable {
    static let shared = SupabaseManager()

    private(set) var client: SupabaseClient?
    private(set) var configurationError: SupabaseConfigurationError?

    var isConfigured: Bool { client != nil }

    private init() {
        configureClient()
    }

    private func configureClient() {
        do {
            let urlString = try Secrets.value("SupabaseURL")
            let key = try Secrets.value("SupabaseKey")

            guard let url = URL(string: urlString) else {
                throw SupabaseConfigurationError.invalidURL
            }

            client = SupabaseClient(
                supabaseURL: url,
                supabaseKey: key,
                options: SupabaseClientOptions(
                    auth: SupabaseClientOptions.AuthOptions(
                        emitLocalSessionAsInitialSession: true
                    )
                )
            )
        } catch let error as SupabaseConfigurationError {
            configurationError = error
            print("⚠️ Supabase configuration error: \(error.localizedDescription)")
        } catch {
            configurationError = .missingSecretsFile
            print("⚠️ Unexpected configuration error: \(error)")
        }
    }
}

// MARK: - Global Accessor (Backward Compatible)

/// Global Supabase client accessor
/// - Note: Uses SupabaseManager internally for graceful error handling
var supabase: SupabaseClient {
    guard let client = SupabaseManager.shared.client else {
        // Return a dummy client that will fail gracefully on API calls
        // This prevents crashes and allows the app to show an error state
        return SupabaseClient(
            supabaseURL: URL(string: "https://placeholder.supabase.co")!,
            supabaseKey: "placeholder_key",
            options: SupabaseClientOptions(
                auth: SupabaseClientOptions.AuthOptions(
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
    }
    return client
}
