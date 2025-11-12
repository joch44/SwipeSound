//
//  ContentView.swift
//  SwipeSound
//
//  Main view for music discovery interface
//

import SwiftUI

struct ContentView: View {
    @StateObject private var spotifyService = SpotifyService()
    @StateObject private var viewModel: MusicDiscoveryViewModel

    @State private var showSpotifyAuth = false

    init() {
        let spotify = SpotifyService()
        _spotifyService = StateObject(wrappedValue: spotify)
        _viewModel = StateObject(wrappedValue: MusicDiscoveryViewModel(spotifyService: spotify))
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    headerView
                        .padding()

                    Spacer()

                    // Main swipe area
                    if let currentSong = viewModel.currentSong {
                        SwipeCardView(song: currentSong) { action in
                            viewModel.handleSwipe(action: action, song: currentSong)
                        }
                        .transition(.scale.combined(with: .opacity))
                    } else {
                        emptyStateView
                    }

                    Spacer()

                    // Bottom controls
                    controlsView
                        .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $viewModel.showFilterPanel) {
                FilterView(
                    currentFilter: $viewModel.currentFilter,
                    availableGenres: viewModel.availableGenres,
                    onApply: { filter in
                        viewModel.applyFilter(filter)
                    },
                    onReset: {
                        viewModel.resetFilters()
                    }
                )
            }
            .sheet(isPresented: $showSpotifyAuth) {
                SpotifyAuthView(spotifyService: spotifyService)
            }
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                // App title
                VStack(alignment: .leading, spacing: 4) {
                    Text("SwipeSound")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Discover your next favorite song")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Spotify connection button
                spotifyButton
            }

            // Stats bar
            HStack(spacing: 20) {
                StatBadge(
                    icon: "heart.fill",
                    count: viewModel.likedSongs.count,
                    color: .green
                )

                StatBadge(
                    icon: "xmark",
                    count: viewModel.skippedSongs.count,
                    color: .red
                )

                Spacer()

                // Filter indicator
                if viewModel.currentFilter.hasActiveFilters {
                    HStack(spacing: 4) {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .foregroundColor(.blue)
                        Text("Filtered")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(12)
                }
            }
        }
    }

    private var spotifyButton: some View {
        Button(action: {
            if spotifyService.isAuthenticated {
                // Show Spotify info
            } else {
                showSpotifyAuth = true
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: spotifyService.isAuthenticated ? "checkmark.circle.fill" : "music.note")
                Text(spotifyService.isAuthenticated ? "Connected" : "Connect")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(spotifyService.isAuthenticated ? Color.green : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(20)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note.list")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No More Songs")
                .font(.title2)
                .fontWeight(.bold)

            Text("Try adjusting your filters to discover more music")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button("Reset Filters") {
                viewModel.resetFilters()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(25)
        }
    }

    // MARK: - Controls View

    private var controlsView: some View {
        HStack(spacing: 40) {
            // Manual skip button
            Button(action: {
                if let song = viewModel.currentSong {
                    viewModel.handleSwipe(action: .skip, song: song)
                }
            }) {
                Image(systemName: "xmark")
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.red)
                    .clipShape(Circle())
                    .shadow(radius: 5)
            }
            .disabled(viewModel.currentSong == nil)

            // Filter button
            Button(action: {
                viewModel.showFilterPanel = true
            }) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.gray.opacity(0.8))
                    .clipShape(Circle())
                    .shadow(radius: 5)
            }

            // Manual like button
            Button(action: {
                if let song = viewModel.currentSong {
                    viewModel.handleSwipe(action: .like, song: song)
                }
            }) {
                Image(systemName: "heart.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.green)
                    .clipShape(Circle())
                    .shadow(radius: 5)
            }
            .disabled(viewModel.currentSong == nil)
        }
        .padding(.bottom, 20)
    }
}

// MARK: - Supporting Views

struct StatBadge: View {
    let icon: String
    let count: Int
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text("\(count)")
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.2))
        .cornerRadius(12)
    }
}

struct SpotifyAuthView: View {
    @ObservedObject var spotifyService: SpotifyService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()

                // Spotify logo placeholder
                Image(systemName: "music.note.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.green)

                VStack(spacing: 12) {
                    Text("Connect to Spotify")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Automatically add your liked songs to a custom Spotify playlist")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                VStack(spacing: 16) {
                    FeatureRow(icon: "checkmark.circle", text: "Secure OAuth 2.0 authentication")
                    FeatureRow(icon: "music.note.list", text: "Auto-create 'SoundSwipe Playlist'")
                    FeatureRow(icon: "arrow.triangle.2.circlepath", text: "Automatic song syncing")
                    FeatureRow(icon: "shield.fill", text: "No duplicate songs")
                }
                .padding(.horizontal, 40)

                Button(action: {
                    spotifyService.authenticate()
                    // Simulated auth - in production would use OAuth flow
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                }) {
                    HStack {
                        Image(systemName: "music.note")
                        Text("Connect with Spotify")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(25)
                }
                .padding(.horizontal, 40)

                if let error = spotifyService.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 40)
                }

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
