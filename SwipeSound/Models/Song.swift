//
//  Song.swift
//  SwipeSound
//
//  Created for music discovery feature
//

import Foundation

/// Represents a song in the music discovery feed
struct Song: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let artist: String
    let albumArt: String // URL string to album art
    let genre: [String]
    let duration: Int // Duration in seconds
    let previewURL: String? // URL to 15-30 second preview
    let energyLevel: EnergyLevel
    let mood: [MoodTag]

    // Helper computed property for duration display
    var durationFormatted: String {
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

/// Energy level of a song
enum EnergyLevel: String, Codable, CaseIterable {
    case chill = "Chill"
    case moderate = "Moderate"
    case upbeat = "Upbeat"
    case energetic = "Energetic"
}

/// Mood tags for songs
enum MoodTag: String, Codable, CaseIterable {
    case happy = "Happy"
    case sad = "Sad"
    case relaxed = "Relaxed"
    case motivated = "Motivated"
    case romantic = "Romantic"
    case party = "Party"
    case focus = "Focus"
    case melancholic = "Melancholic"
}

/// Action taken on a song
enum SwipeAction {
    case like
    case skip
    case none
}
