//
//  MusicDiscoveryViewModel.swift
//  SwipeSound
//
//  View model for managing music discovery flow
//

import Foundation
import SwiftUI

@MainActor
class MusicDiscoveryViewModel: ObservableObject {
    @Published var songQueue: [Song] = []
    @Published var currentFilter = SongFilter()
    @Published var likedSongs: [Song] = []
    @Published var skippedSongs: [Song] = []
    @Published var showFilterPanel = false

    private let spotifyService: SpotifyService
    private var allAvailableSongs: [Song] = []

    init(spotifyService: SpotifyService) {
        self.spotifyService = spotifyService
        loadMockSongs()
        updateSongQueue()
    }

    // MARK: - Song Queue Management

    /// Get the current top song to display
    var currentSong: Song? {
        songQueue.first
    }

    /// Remove the current song and show the next one
    func nextSong() {
        if !songQueue.isEmpty {
            songQueue.removeFirst()
        }

        // If queue is running low, refill it
        if songQueue.count < 3 {
            updateSongQueue()
        }
    }

    /// Update song queue based on current filters
    func updateSongQueue() {
        let filteredSongs = allAvailableSongs.filter { song in
            // Don't show already interacted songs
            let notLiked = !likedSongs.contains(where: { $0.id == song.id })
            let notSkipped = !skippedSongs.contains(where: { $0.id == song.id })
            let notInQueue = !songQueue.contains(where: { $0.id == song.id })

            // Apply user filters
            let matchesFilter = currentFilter.matches(song)

            return notLiked && notSkipped && notInQueue && matchesFilter
        }

        // Add new songs to queue
        let songsToAdd = min(10, filteredSongs.count)
        songQueue.append(contentsOf: filteredSongs.prefix(songsToAdd))

        // Shuffle for variety
        songQueue.shuffle()
    }

    // MARK: - Swipe Actions

    /// Handle swipe action on a song
    func handleSwipe(action: SwipeAction, song: Song) {
        switch action {
        case .like:
            handleLike(song)
        case .skip:
            handleSkip(song)
        case .none:
            break
        }

        nextSong()
    }

    /// Handle liking a song
    private func handleLike(_ song: Song) {
        likedSongs.append(song)

        // If connected to Spotify, add to playlist
        if spotifyService.isAuthenticated {
            Task {
                await spotifyService.addSongToPlaylist(spotifyURI: song.spotifyURI)
            }
        }
    }

    /// Handle skipping a song
    private func handleSkip(_ song: Song) {
        skippedSongs.append(song)
    }

    // MARK: - Filter Management

    /// Apply new filters
    func applyFilter(_ filter: SongFilter) {
        currentFilter = filter

        // Clear current queue and refill with filtered songs
        songQueue.removeAll()
        updateSongQueue()

        showFilterPanel = false
    }

    /// Reset filters to show all songs
    func resetFilters() {
        currentFilter.reset()
        songQueue.removeAll()
        updateSongQueue()
    }

    // MARK: - Data Loading

    /// Load mock song data for testing
    private func loadMockSongs() {
        allAvailableSongs = [
            Song(
                id: "1",
                title: "Midnight Dreams",
                artist: "The Dream Makers",
                albumArt: "https://example.com/album1.jpg",
                genre: ["Pop", "Electronic"],
                duration: 243,
                previewURL: "https://example.com/preview1.mp3",
                spotifyURI: "spotify:track:midnight-dreams",
                energyLevel: .upbeat,
                mood: [.happy, .motivated]
            ),
            Song(
                id: "2",
                title: "Sunset Boulevard",
                artist: "Coastal Vibes",
                albumArt: "https://example.com/album2.jpg",
                genre: ["Indie", "Alternative"],
                duration: 195,
                previewURL: "https://example.com/preview2.mp3",
                spotifyURI: "spotify:track:sunset-boulevard",
                energyLevel: .chill,
                mood: [.relaxed, .happy]
            ),
            Song(
                id: "3",
                title: "Thunder Strike",
                artist: "Electric Storm",
                albumArt: "https://example.com/album3.jpg",
                genre: ["Rock", "Electronic"],
                duration: 287,
                previewURL: "https://example.com/preview3.mp3",
                spotifyURI: "spotify:track:thunder-strike",
                energyLevel: .energetic,
                mood: [.motivated, .party]
            ),
            Song(
                id: "4",
                title: "Whispered Secrets",
                artist: "Acoustic Soul",
                albumArt: "https://example.com/album4.jpg",
                genre: ["Acoustic", "Folk"],
                duration: 214,
                previewURL: "https://example.com/preview4.mp3",
                spotifyURI: "spotify:track:whispered-secrets",
                energyLevel: .chill,
                mood: [.romantic, .melancholic]
            ),
            Song(
                id: "5",
                title: "City Lights",
                artist: "Urban Beats",
                albumArt: "https://example.com/album5.jpg",
                genre: ["Hip Hop", "R&B"],
                duration: 201,
                previewURL: "https://example.com/preview5.mp3",
                spotifyURI: "spotify:track:city-lights",
                energyLevel: .moderate,
                mood: [.focus, .motivated]
            ),
            Song(
                id: "6",
                title: "Ocean Waves",
                artist: "Chill Masters",
                albumArt: "https://example.com/album6.jpg",
                genre: ["Ambient", "Electronic"],
                duration: 324,
                previewURL: "https://example.com/preview6.mp3",
                spotifyURI: "spotify:track:ocean-waves",
                energyLevel: .chill,
                mood: [.relaxed, .focus]
            ),
            Song(
                id: "7",
                title: "Dance Revolution",
                artist: "Party Squad",
                albumArt: "https://example.com/album7.jpg",
                genre: ["EDM", "Dance"],
                duration: 178,
                previewURL: "https://example.com/preview7.mp3",
                spotifyURI: "spotify:track:dance-revolution",
                energyLevel: .energetic,
                mood: [.party, .happy]
            ),
            Song(
                id: "8",
                title: "Rainy Day Blues",
                artist: "Melancholy Hearts",
                albumArt: "https://example.com/album8.jpg",
                genre: ["Blues", "Jazz"],
                duration: 256,
                previewURL: "https://example.com/preview8.mp3",
                spotifyURI: "spotify:track:rainy-day-blues",
                energyLevel: .chill,
                mood: [.sad, .melancholic]
            ),
            Song(
                id: "9",
                title: "Morning Motivation",
                artist: "Energy Boost",
                albumArt: "https://example.com/album9.jpg",
                genre: ["Pop", "Rock"],
                duration: 189,
                previewURL: "https://example.com/preview9.mp3",
                spotifyURI: "spotify:track:morning-motivation",
                energyLevel: .upbeat,
                mood: [.motivated, .happy]
            ),
            Song(
                id: "10",
                title: "Jazz in the Night",
                artist: "Smooth Jazz Collective",
                albumArt: "https://example.com/album10.jpg",
                genre: ["Jazz", "Smooth Jazz"],
                duration: 298,
                previewURL: "https://example.com/preview10.mp3",
                spotifyURI: "spotify:track:jazz-night",
                energyLevel: .moderate,
                mood: [.relaxed, .romantic]
            ),
            Song(
                id: "11",
                title: "Workout Anthem",
                artist: "Fitness Beats",
                albumArt: "https://example.com/album11.jpg",
                genre: ["Electronic", "Workout"],
                duration: 167,
                previewURL: "https://example.com/preview11.mp3",
                spotifyURI: "spotify:track:workout-anthem",
                energyLevel: .energetic,
                mood: [.motivated, .party]
            ),
            Song(
                id: "12",
                title: "Study Session",
                artist: "Lo-Fi Vibes",
                albumArt: "https://example.com/album12.jpg",
                genre: ["Lo-Fi", "Hip Hop"],
                duration: 145,
                previewURL: "https://example.com/preview12.mp3",
                spotifyURI: "spotify:track:study-session",
                energyLevel: .chill,
                mood: [.focus, .relaxed]
            ),
            Song(
                id: "13",
                title: "Summer Breeze",
                artist: "Tropical Sounds",
                albumArt: "https://example.com/album13.jpg",
                genre: ["Reggae", "Pop"],
                duration: 221,
                previewURL: "https://example.com/preview13.mp3",
                spotifyURI: "spotify:track:summer-breeze",
                energyLevel: .moderate,
                mood: [.happy, .relaxed]
            ),
            Song(
                id: "14",
                title: "Heartbreak Hotel",
                artist: "Emotional Express",
                albumArt: "https://example.com/album14.jpg",
                genre: ["Pop", "Ballad"],
                duration: 267,
                previewURL: "https://example.com/preview14.mp3",
                spotifyURI: "spotify:track:heartbreak-hotel",
                energyLevel: .chill,
                mood: [.sad, .romantic]
            ),
            Song(
                id: "15",
                title: "Victory March",
                artist: "Epic Orchestra",
                albumArt: "https://example.com/album15.jpg",
                genre: ["Classical", "Epic"],
                duration: 312,
                previewURL: "https://example.com/preview15.mp3",
                spotifyURI: "spotify:track:victory-march",
                energyLevel: .energetic,
                mood: [.motivated, .happy]
            )
        ]
    }

    // MARK: - Available Genres (for filter options)

    var availableGenres: [String] {
        let allGenres = allAvailableSongs.flatMap { $0.genre }
        return Array(Set(allGenres)).sorted()
    }
}
