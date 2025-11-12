//
//  SpotifyService.swift
//  SwipeSound
//
//  Spotify OAuth 2.0 integration and playlist management
//

import Foundation
import AuthenticationServices

/// Manages Spotify authentication and API interactions
@MainActor
class SpotifyService: NSObject, ObservableObject {
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    @Published var playlistURL: String?

    private var accessToken: String?
    private var refreshToken: String?
    private var userId: String?
    private var swipeSoundPlaylistId: String?

    // Spotify OAuth credentials (In production, these should be in a secure configuration)
    private let clientId = "YOUR_SPOTIFY_CLIENT_ID"
    private let clientSecret = "YOUR_SPOTIFY_CLIENT_SECRET"
    private let redirectURI = "swipesound://spotify-callback"
    private let scopes = "playlist-modify-public playlist-modify-private user-read-private"

    // Track songs already in playlist to prevent duplicates
    private var playlistSongURIs = Set<String>()

    /// Authenticate with Spotify using OAuth 2.0
    func authenticate() {
        // Build authorization URL
        var components = URLComponents(string: "https://accounts.spotify.com/authorize")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "scope", value: scopes),
            URLQueryItem(name: "show_dialog", value: "true")
        ]

        guard let url = components.url else {
            errorMessage = "Failed to create authorization URL"
            return
        }

        // In a real implementation, this would open Safari or ASWebAuthenticationSession
        // For now, this is a placeholder for the OAuth flow
        print("Opening Spotify authorization URL: \(url)")

        // Simulated successful authentication for demo purposes
        // In production, this would be replaced with actual OAuth flow
        simulateSuccessfulAuth()
    }

    /// Handle OAuth callback with authorization code
    func handleCallback(code: String) async {
        do {
            // Exchange authorization code for access token
            let tokens = try await exchangeCodeForToken(code: code)
            self.accessToken = tokens.accessToken
            self.refreshToken = tokens.refreshToken

            // Fetch user profile
            try await fetchUserProfile()

            // Create or find SoundSwipe playlist
            try await setupPlaylist()

            isAuthenticated = true
            errorMessage = nil
        } catch {
            errorMessage = "Authentication failed: \(error.localizedDescription)"
            isAuthenticated = false
        }
    }

    /// Exchange authorization code for access token
    private func exchangeCodeForToken(code: String) async throws -> (accessToken: String, refreshToken: String) {
        var request = URLRequest(url: URL(string: "https://accounts.spotify.com/api/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let authString = "\(clientId):\(clientSecret)"
        let authData = authString.data(using: .utf8)!.base64EncodedString()
        request.setValue("Basic \(authData)", forHTTPHeaderField: "Authorization")

        let bodyParameters = [
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": redirectURI
        ]
        request.httpBody = bodyParameters.percentEncoded()

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SpotifyError.authenticationFailed
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        return (tokenResponse.access_token, tokenResponse.refresh_token ?? "")
    }

    /// Fetch Spotify user profile
    private func fetchUserProfile() async throws {
        guard let token = accessToken else {
            throw SpotifyError.notAuthenticated
        }

        var request = URLRequest(url: URL(string: "https://api.spotify.com/v1/me")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SpotifyError.apiError
        }

        let userProfile = try JSONDecoder().decode(UserProfile.self, from: data)
        self.userId = userProfile.id
    }

    /// Create or find the SoundSwipe playlist
    private func setupPlaylist() async throws {
        guard let token = accessToken,
              let userId = userId else {
            throw SpotifyError.notAuthenticated
        }

        // First, check if playlist already exists
        let playlists = try await fetchUserPlaylists()

        if let existing = playlists.first(where: { $0.name == "SoundSwipe Playlist" }) {
            swipeSoundPlaylistId = existing.id
            playlistURL = existing.external_urls.spotify
            // Load existing songs to prevent duplicates
            try await loadPlaylistTracks()
        } else {
            // Create new playlist
            let playlist = try await createPlaylist()
            swipeSoundPlaylistId = playlist.id
            playlistURL = playlist.external_urls.spotify
        }
    }

    /// Fetch user's playlists
    private func fetchUserPlaylists() async throws -> [PlaylistInfo] {
        guard let token = accessToken,
              let userId = userId else {
            throw SpotifyError.notAuthenticated
        }

        var request = URLRequest(url: URL(string: "https://api.spotify.com/v1/users/\(userId)/playlists")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(PlaylistsResponse.self, from: data)
        return response.items
    }

    /// Create a new SoundSwipe playlist
    private func createPlaylist() async throws -> PlaylistInfo {
        guard let token = accessToken,
              let userId = userId else {
            throw SpotifyError.notAuthenticated
        }

        var request = URLRequest(url: URL(string: "https://api.spotify.com/v1/users/\(userId)/playlists")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "name": "SoundSwipe Playlist",
            "description": "Songs I discovered and loved on SwipeSound",
            "public": false
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(PlaylistInfo.self, from: data)
    }

    /// Load existing tracks from playlist to prevent duplicates
    private func loadPlaylistTracks() async throws {
        guard let token = accessToken,
              let playlistId = swipeSoundPlaylistId else {
            return
        }

        var request = URLRequest(url: URL(string: "https://api.spotify.com/v1/playlists/\(playlistId)/tracks")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(PlaylistTracksResponse.self, from: data)

        playlistSongURIs = Set(response.items.map { $0.track.uri })
    }

    /// Add a liked song to the Spotify playlist
    func addSongToPlaylist(spotifyURI: String) async {
        // Check for duplicates
        if playlistSongURIs.contains(spotifyURI) {
            print("Song already in playlist, skipping: \(spotifyURI)")
            return
        }

        guard let token = accessToken,
              let playlistId = swipeSoundPlaylistId else {
            errorMessage = "Not authenticated with Spotify"
            return
        }

        do {
            var request = URLRequest(url: URL(string: "https://api.spotify.com/v1/playlists/\(playlistId)/tracks")!)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let body: [String: Any] = ["uris": [spotifyURI]]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (_, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 201 {
                playlistSongURIs.insert(spotifyURI)
                print("Successfully added song to playlist")
                errorMessage = nil
            } else {
                throw SpotifyError.apiError
            }
        } catch {
            errorMessage = "Failed to add song to playlist. Retry available."
            print("Error adding song: \(error)")
        }
    }

    /// Retry adding a song if previous attempt failed
    func retryAddSong(spotifyURI: String) async {
        await addSongToPlaylist(spotifyURI: spotifyURI)
    }

    /// Sign out
    func signOut() {
        isAuthenticated = false
        accessToken = nil
        refreshToken = nil
        userId = nil
        swipeSoundPlaylistId = nil
        playlistURL = nil
        playlistSongURIs.removeAll()
        errorMessage = nil
    }

    // MARK: - Demo/Simulation Methods

    /// Simulate successful authentication (for demo purposes)
    private func simulateSuccessfulAuth() {
        // Simulate OAuth success
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.accessToken = "demo_access_token"
            self?.userId = "demo_user"
            self?.swipeSoundPlaylistId = "demo_playlist_id"
            self?.playlistURL = "https://open.spotify.com/playlist/demo"
            self?.isAuthenticated = true
            self?.errorMessage = nil
        }
    }
}

// MARK: - Supporting Types

enum SpotifyError: Error {
    case notAuthenticated
    case authenticationFailed
    case apiError
    case networkError
}

struct TokenResponse: Codable {
    let access_token: String
    let token_type: String
    let scope: String
    let expires_in: Int
    let refresh_token: String?
}

struct UserProfile: Codable {
    let id: String
    let display_name: String?
    let email: String?
}

struct PlaylistsResponse: Codable {
    let items: [PlaylistInfo]
}

struct PlaylistInfo: Codable {
    let id: String
    let name: String
    let external_urls: ExternalURLs
}

struct ExternalURLs: Codable {
    let spotify: String
}

struct PlaylistTracksResponse: Codable {
    let items: [PlaylistTrackItem]
}

struct PlaylistTrackItem: Codable {
    let track: TrackInfo
}

struct TrackInfo: Codable {
    let uri: String
}

// MARK: - Helper Extensions

extension Dictionary {
    func percentEncoded() -> Data? {
        return map { key, value in
            let escapedKey = "\(key)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            let escapedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            return escapedKey + "=" + escapedValue
        }
        .joined(separator: "&")
        .data(using: .utf8)
    }
}

extension CharacterSet {
    static let urlQueryValueAllowed: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@"
        let subDelimitersToEncode = "!$&'()*+,;="

        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        return allowed
    }()
}
