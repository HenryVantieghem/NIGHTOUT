//
//  MusicService.swift
//  NIGHTOUT
//
//  Apple Music integration service using MusicKit
//

import Foundation
import MusicKit

/// Search result for a song from Apple Music
struct MusicSearchResult: Identifiable {
    let id: String
    let title: String
    let artist: String
    let albumName: String?
    let artworkURL: URL?

    var displayText: String {
        "\(title) - \(artist)"
    }
}

/// Service for Apple Music integration
@Observable
class MusicService {
    var authorizationStatus: MusicAuthorization.Status = .notDetermined
    var searchResults: [MusicSearchResult] = []
    var isSearching = false
    var errorMessage: String?

    // MARK: - Authorization

    func requestAuthorization() async {
        // Check current status first to avoid unnecessary prompts
        let currentStatus = MusicAuthorization.currentStatus
        
        // Only request if status is not determined
        guard currentStatus == .notDetermined else {
            await MainActor.run {
                self.authorizationStatus = currentStatus
                self.updateErrorMessageForStatus(currentStatus)
            }
            return
        }
        
        // Request authorization (MusicAuthorization.request() is non-throwing)
        let status = await MusicAuthorization.request()
        await MainActor.run {
            self.authorizationStatus = status
            self.updateErrorMessageForStatus(status)
        }
    }

    @MainActor
    func checkAuthorizationStatus() {
        authorizationStatus = MusicAuthorization.currentStatus
        updateErrorMessageForStatus(authorizationStatus)
    }

    var isAuthorized: Bool {
        authorizationStatus == .authorized
    }
    
    // MARK: - Status Messages
    
    private func updateErrorMessageForStatus(_ status: MusicAuthorization.Status) {
        switch status {
        case .authorized:
            errorMessage = nil
        case .denied:
            errorMessage = "Apple Music access was denied. Please enable it in Settings > NIGHTOUT > Apple Music."
        case .restricted:
            errorMessage = "Apple Music access is restricted on this device. Please check your device restrictions."
        case .notDetermined:
            errorMessage = nil
        @unknown default:
            errorMessage = "Apple Music access status is unknown. Please try again."
        }
    }
    
    func statusMessage(for status: MusicAuthorization.Status) -> String {
        switch status {
        case .authorized:
            return ""
        case .denied:
            return "Apple Music access was denied. Please enable it in Settings > NIGHTOUT > Apple Music."
        case .restricted:
            return "Apple Music access is restricted on this device. Please check your device restrictions."
        case .notDetermined:
            return "Apple Music access is required to search and add songs to your night."
        @unknown default:
            return "Apple Music access status is unknown. Please try again."
        }
    }

    // MARK: - Search

    func searchSongs(query: String) async {
        guard !query.isEmpty else {
            await MainActor.run {
                self.searchResults = []
            }
            return
        }
        
        // Check authorization before searching with user-friendly message
        guard authorizationStatus == .authorized else {
            await MainActor.run {
                self.errorMessage = statusMessage(for: authorizationStatus)
                self.searchResults = []
                self.isSearching = false
            }
            return
        }

        await MainActor.run {
            self.isSearching = true
            self.errorMessage = nil
        }

        do {
            var request = MusicCatalogSearchRequest(term: query, types: [MusicKit.Song.self])
            request.limit = 20

            let response = try await request.response()

            // Safely map songs with defensive guards
            let results = response.songs.compactMap { song -> MusicSearchResult? in
                // Safely access song ID (rawValue is non-throwing, but ensure it's not empty)
                let songId = song.id.rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !songId.isEmpty else {
                    // Skip songs with invalid IDs
                    return nil
                }
                
                // Ensure title and artist are not empty
                let title = song.title.trimmingCharacters(in: .whitespacesAndNewlines)
                let artist = song.artistName.trimmingCharacters(in: .whitespacesAndNewlines)
                
                guard !title.isEmpty, !artist.isEmpty else {
                    // Skip songs with missing essential data
                    return nil
                }
                
                // Safely access optional properties
                let albumName = song.albumTitle?.trimmingCharacters(in: .whitespacesAndNewlines)
                let artworkURL = song.artwork?.url(width: 100, height: 100)
                
                return MusicSearchResult(
                    id: songId,
                    title: title,
                    artist: artist,
                    albumName: albumName?.isEmpty == false ? albumName : nil,
                    artworkURL: artworkURL
                )
            }

            await MainActor.run {
                self.searchResults = results
                self.isSearching = false
            }
        } catch {
            await MainActor.run {
                // Provide user-friendly error message
                let errorDescription = error.localizedDescription
                if errorDescription.contains("network") || errorDescription.contains("connection") {
                    self.errorMessage = "Unable to search Apple Music. Please check your internet connection."
                } else if errorDescription.contains("authorization") || errorDescription.contains("permission") {
                    self.errorMessage = "Apple Music access is required. Please enable it in Settings."
                } else {
                    self.errorMessage = "Failed to search Apple Music. Please try again."
                }
                self.searchResults = []
                self.isSearching = false
            }
        }
    }

    func clearSearch() {
        searchResults = []
        errorMessage = nil
    }
}
