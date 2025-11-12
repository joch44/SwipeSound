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

    private var allAvailableSongs: [Song] = []

    init() {
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
                title: "Blinding Lights",
                artist: "The Weeknd",
                albumArt: "",
                genre: ["Pop", "Synthwave"],
                duration: 200,
                previewURL: nil,
                energyLevel: .upbeat,
                mood: [.happy, .party]
            ),
            Song(
                id: "2",
                title: "Shape of You",
                artist: "Ed Sheeran",
                albumArt: "",
                genre: ["Pop", "Dance"],
                duration: 234,
                previewURL: nil,
                energyLevel: .upbeat,
                mood: [.happy, .romantic]
            ),
            Song(
                id: "3",
                title: "Bohemian Rhapsody",
                artist: "Queen",
                albumArt: "",
                genre: ["Rock", "Classic Rock"],
                duration: 354,
                previewURL: nil,
                energyLevel: .energetic,
                mood: [.motivated, .happy]
            ),
            Song(
                id: "4",
                title: "Someone Like You",
                artist: "Adele",
                albumArt: "",
                genre: ["Pop", "Ballad"],
                duration: 285,
                previewURL: nil,
                energyLevel: .chill,
                mood: [.sad, .melancholic]
            ),
            Song(
                id: "5",
                title: "Levitating",
                artist: "Dua Lipa",
                albumArt: "",
                genre: ["Pop", "Disco"],
                duration: 203,
                previewURL: nil,
                energyLevel: .energetic,
                mood: [.party, .happy]
            ),
            Song(
                id: "6",
                title: "Stairway to Heaven",
                artist: "Led Zeppelin",
                albumArt: "",
                genre: ["Rock", "Classic Rock"],
                duration: 482,
                previewURL: nil,
                energyLevel: .moderate,
                mood: [.motivated, .melancholic]
            ),
            Song(
                id: "7",
                title: "Lo-Fi Study Beats",
                artist: "ChilledCow",
                albumArt: "",
                genre: ["Lo-Fi", "Hip Hop"],
                duration: 158,
                previewURL: nil,
                energyLevel: .chill,
                mood: [.focus, .relaxed]
            ),
            Song(
                id: "8",
                title: "Uptown Funk",
                artist: "Mark Ronson ft. Bruno Mars",
                albumArt: "",
                genre: ["Funk", "Pop"],
                duration: 269,
                previewURL: nil,
                energyLevel: .energetic,
                mood: [.party, .happy]
            ),
            Song(
                id: "9",
                title: "Circles",
                artist: "Post Malone",
                albumArt: "",
                genre: ["Pop", "Hip Hop"],
                duration: 215,
                previewURL: nil,
                energyLevel: .moderate,
                mood: [.relaxed, .melancholic]
            ),
            Song(
                id: "10",
                title: "Take Five",
                artist: "Dave Brubeck",
                albumArt: "",
                genre: ["Jazz", "Classic Jazz"],
                duration: 324,
                previewURL: nil,
                energyLevel: .chill,
                mood: [.relaxed, .focus]
            ),
            Song(
                id: "11",
                title: "Thunderstruck",
                artist: "AC/DC",
                albumArt: "",
                genre: ["Rock", "Hard Rock"],
                duration: 292,
                previewURL: nil,
                energyLevel: .energetic,
                mood: [.motivated, .party]
            ),
            Song(
                id: "12",
                title: "Perfect",
                artist: "Ed Sheeran",
                albumArt: "",
                genre: ["Pop", "Ballad"],
                duration: 263,
                previewURL: nil,
                energyLevel: .chill,
                mood: [.romantic, .happy]
            ),
            Song(
                id: "13",
                title: "God's Plan",
                artist: "Drake",
                albumArt: "",
                genre: ["Hip Hop", "Rap"],
                duration: 219,
                previewURL: nil,
                energyLevel: .moderate,
                mood: [.motivated, .happy]
            ),
            Song(
                id: "14",
                title: "Moonlight Sonata",
                artist: "Beethoven",
                albumArt: "",
                genre: ["Classical", "Piano"],
                duration: 900,
                previewURL: nil,
                energyLevel: .chill,
                mood: [.melancholic, .focus]
            ),
            Song(
                id: "15",
                title: "Bad Guy",
                artist: "Billie Eilish",
                albumArt: "",
                genre: ["Pop", "Alternative"],
                duration: 194,
                previewURL: nil,
                energyLevel: .moderate,
                mood: [.motivated, .party]
            ),
            Song(
                id: "16",
                title: "Don't Stop Believin'",
                artist: "Journey",
                albumArt: "",
                genre: ["Rock", "Classic Rock"],
                duration: 251,
                previewURL: nil,
                energyLevel: .upbeat,
                mood: [.motivated, .happy]
            ),
            Song(
                id: "17",
                title: "Sicko Mode",
                artist: "Travis Scott",
                albumArt: "",
                genre: ["Hip Hop", "Trap"],
                duration: 312,
                previewURL: nil,
                energyLevel: .energetic,
                mood: [.party, .motivated]
            ),
            Song(
                id: "18",
                title: "Bitter Sweet Symphony",
                artist: "The Verve",
                albumArt: "",
                genre: ["Alternative", "Rock"],
                duration: 358,
                previewURL: nil,
                energyLevel: .moderate,
                mood: [.melancholic, .motivated]
            ),
            Song(
                id: "19",
                title: "Watermelon Sugar",
                artist: "Harry Styles",
                albumArt: "",
                genre: ["Pop", "Rock"],
                duration: 174,
                previewURL: nil,
                energyLevel: .upbeat,
                mood: [.happy, .party]
            ),
            Song(
                id: "20",
                title: "Lucid Dreams",
                artist: "Juice WRLD",
                albumArt: "",
                genre: ["Hip Hop", "Emo Rap"],
                duration: 239,
                previewURL: nil,
                energyLevel: .moderate,
                mood: [.sad, .melancholic]
            ),
            Song(
                id: "21",
                title: "Sweet Child O' Mine",
                artist: "Guns N' Roses",
                albumArt: "",
                genre: ["Rock", "Hard Rock"],
                duration: 356,
                previewURL: nil,
                energyLevel: .energetic,
                mood: [.happy, .motivated]
            ),
            Song(
                id: "22",
                title: "Summertime Sadness",
                artist: "Lana Del Rey",
                albumArt: "",
                genre: ["Pop", "Indie"],
                duration: 265,
                previewURL: nil,
                energyLevel: .moderate,
                mood: [.melancholic, .romantic]
            ),
            Song(
                id: "23",
                title: "Ocean Eyes",
                artist: "Billie Eilish",
                albumArt: "",
                genre: ["Pop", "Indie"],
                duration: 200,
                previewURL: nil,
                energyLevel: .chill,
                mood: [.relaxed, .romantic]
            ),
            Song(
                id: "24",
                title: "HUMBLE.",
                artist: "Kendrick Lamar",
                albumArt: "",
                genre: ["Hip Hop", "Rap"],
                duration: 177,
                previewURL: nil,
                energyLevel: .energetic,
                mood: [.motivated, .party]
            ),
            Song(
                id: "25",
                title: "Imagine",
                artist: "John Lennon",
                albumArt: "",
                genre: ["Rock", "Classic"],
                duration: 183,
                previewURL: nil,
                energyLevel: .chill,
                mood: [.relaxed, .happy]
            )
        ]
    }

    // MARK: - Available Genres (for filter options)

    var availableGenres: [String] {
        let allGenres = allAvailableSongs.flatMap { $0.genre }
        return Array(Set(allGenres)).sorted()
    }
}
