//
//  SongFilter.swift
//  SwipeSound
//
//  Filter model for song discovery
//

import Foundation

/// Filter criteria for song discovery
struct SongFilter: Equatable {
    var selectedGenres: Set<String> = []
    var maxDuration: Int? = nil // Maximum duration in seconds
    var minDuration: Int? = nil // Minimum duration in seconds
    var energyLevels: Set<EnergyLevel> = []
    var moods: Set<MoodTag> = []

    /// Check if any filters are active
    var hasActiveFilters: Bool {
        return !selectedGenres.isEmpty ||
               maxDuration != nil ||
               minDuration != nil ||
               !energyLevels.isEmpty ||
               !moods.isEmpty
    }

    /// Reset all filters to default (no filtering)
    mutating func reset() {
        selectedGenres.removeAll()
        maxDuration = nil
        minDuration = nil
        energyLevels.removeAll()
        moods.removeAll()
    }

    /// Check if a song matches all active filter criteria
    func matches(_ song: Song) -> Bool {
        // If no filters are active, all songs match
        if !hasActiveFilters {
            return true
        }

        // Check genre filter
        if !selectedGenres.isEmpty {
            let hasMatchingGenre = song.genre.contains { selectedGenres.contains($0) }
            if !hasMatchingGenre {
                return false
            }
        }

        // Check duration filters
        if let max = maxDuration, song.duration > max {
            return false
        }

        if let min = minDuration, song.duration < min {
            return false
        }

        // Check energy level filter
        if !energyLevels.isEmpty && !energyLevels.contains(song.energyLevel) {
            return false
        }

        // Check mood filter
        if !moods.isEmpty {
            let hasMatchingMood = song.mood.contains { moods.contains($0) }
            if !hasMatchingMood {
                return false
            }
        }

        return true
    }
}

/// Predefined duration options for filtering
enum DurationOption: Int, CaseIterable, Identifiable {
    case short = 120      // 2 minutes
    case medium = 240     // 4 minutes
    case long = 360       // 6 minutes
    case veryLong = 600   // 10 minutes

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .short: return "< 2 min"
        case .medium: return "< 4 min"
        case .long: return "< 6 min"
        case .veryLong: return "< 10 min"
        }
    }
}
