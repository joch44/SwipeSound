//
//  FilterView.swift
//  SwipeSound
//
//  Filter panel for controlling song discovery preferences
//

import SwiftUI

struct FilterView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var currentFilter: SongFilter
    let availableGenres: [String]
    let onApply: (SongFilter) -> Void
    let onReset: () -> Void

    @State private var workingFilter: SongFilter

    init(
        currentFilter: Binding<SongFilter>,
        availableGenres: [String],
        onApply: @escaping (SongFilter) -> Void,
        onReset: @escaping () -> Void
    ) {
        self._currentFilter = currentFilter
        self.availableGenres = availableGenres
        self.onApply = onApply
        self.onReset = onReset
        self._workingFilter = State(initialValue: currentFilter.wrappedValue)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Filter Status
                    if workingFilter.hasActiveFilters {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Filters Active")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(10)
                    }

                    // Genre Filter Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "music.note.list")
                                .foregroundColor(.blue)
                            Text("Genres")
                                .font(.headline)
                        }

                        Text("Select one or more genres")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                            ForEach(availableGenres, id: \.self) { genre in
                                GenreTag(
                                    genre: genre,
                                    isSelected: workingFilter.selectedGenres.contains(genre)
                                ) {
                                    toggleGenre(genre)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Duration Filter Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.purple)
                            Text("Duration")
                                .font(.headline)
                        }

                        Text("Maximum song length")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        ForEach(DurationOption.allCases) { option in
                            DurationOptionRow(
                                option: option,
                                isSelected: workingFilter.maxDuration == option.rawValue
                            ) {
                                if workingFilter.maxDuration == option.rawValue {
                                    workingFilter.maxDuration = nil
                                } else {
                                    workingFilter.maxDuration = option.rawValue
                                }
                            }
                        }

                        if workingFilter.maxDuration != nil {
                            Button(action: {
                                workingFilter.maxDuration = nil
                            }) {
                                HStack {
                                    Image(systemName: "xmark.circle.fill")
                                    Text("Remove duration limit")
                                }
                                .font(.caption)
                                .foregroundColor(.red)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Energy Level Filter Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "bolt.fill")
                                .foregroundColor(.orange)
                            Text("Energy Level")
                                .font(.headline)
                        }

                        Text("Select song energy levels")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        ForEach(EnergyLevel.allCases, id: \.self) { level in
                            EnergyLevelRow(
                                level: level,
                                isSelected: workingFilter.energyLevels.contains(level)
                            ) {
                                toggleEnergyLevel(level)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Mood Filter Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.pink)
                            Text("Mood Tags")
                                .font(.headline)
                        }

                        Text("Select one or more moods")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                            ForEach(MoodTag.allCases, id: \.self) { mood in
                                MoodTagButton(
                                    mood: mood,
                                    isSelected: workingFilter.moods.contains(mood)
                                ) {
                                    toggleMood(mood)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Filter Songs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        workingFilter.reset()
                        onReset()
                        dismiss()
                    }
                    .foregroundColor(.red)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        onApply(workingFilter)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func toggleGenre(_ genre: String) {
        if workingFilter.selectedGenres.contains(genre) {
            workingFilter.selectedGenres.remove(genre)
        } else {
            workingFilter.selectedGenres.insert(genre)
        }
    }

    private func toggleEnergyLevel(_ level: EnergyLevel) {
        if workingFilter.energyLevels.contains(level) {
            workingFilter.energyLevels.remove(level)
        } else {
            workingFilter.energyLevels.insert(level)
        }
    }

    private func toggleMood(_ mood: MoodTag) {
        if workingFilter.moods.contains(mood) {
            workingFilter.moods.remove(mood)
        } else {
            workingFilter.moods.insert(mood)
        }
    }
}

// MARK: - Supporting Views

struct GenreTag: View {
    let genre: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(genre)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                )
        }
    }
}

struct DurationOptionRow: View {
    let option: DurationOption
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .purple : .gray)
                Text(option.label)
                Spacer()
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

struct EnergyLevelRow: View {
    let level: EnergyLevel
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isSelected ? .orange : .gray)
                Text(level.rawValue)
                Spacer()
                energyIcon
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var energyIcon: some View {
        switch level {
        case .chill:
            Image(systemName: "cloud.fill")
        case .moderate:
            Image(systemName: "bolt")
        case .upbeat:
            Image(systemName: "bolt.fill")
        case .energetic:
            Image(systemName: "flame.fill")
        }
    }
}

struct MoodTagButton: View {
    let mood: MoodTag
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(mood.rawValue)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.pink : Color(.systemGray5))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.pink : Color.clear, lineWidth: 2)
                )
        }
    }
}

// MARK: - Preview

#Preview {
    FilterView(
        currentFilter: .constant(SongFilter()),
        availableGenres: ["Pop", "Rock", "Jazz", "Electronic", "Hip Hop"],
        onApply: { _ in },
        onReset: { }
    )
}
