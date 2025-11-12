//
//  SwipeCardView.swift
//  SwipeSound
//
//  Card view for displaying song information with swipe gestures
//

import SwiftUI

struct SwipeCardView: View {
    let song: Song
    let onSwipe: (SwipeAction) -> Void

    @State private var offset = CGSize.zero
    @State private var rotation: Double = 0
    @State private var feedbackOpacity: Double = 0
    @State private var feedbackText: String = ""

    // Thresholds for swipe detection
    private let swipeThreshold: CGFloat = 100
    private let rotationAmount: Double = 10

    var body: some View {
        ZStack {
            // Card background and content
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(radius: 10)

            VStack(spacing: 0) {
                // Album Art
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(1, contentMode: .fit)

                    // Placeholder for album art
                    // In production, use AsyncImage to load from song.albumArt URL
                    Image(systemName: "music.note")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 300)
                .clipped()

                // Song Information
                VStack(alignment: .leading, spacing: 12) {
                    // Title and Artist
                    VStack(alignment: .leading, spacing: 4) {
                        Text(song.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text(song.artist)
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(1)
                    }

                    Divider()
                        .background(Color.white.opacity(0.3))

                    // Genre tags
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(song.genre, id: \.self) { genre in
                                Text(genre)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.2))
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }
                    }

                    // Song metadata
                    HStack(spacing: 16) {
                        Label(song.durationFormatted, systemImage: "clock")
                        Label(song.energyLevel.rawValue, systemImage: "bolt.fill")
                    }
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))

                    // Mood tags
                    if !song.mood.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "heart.fill")
                                .font(.caption2)
                            Text(song.mood.map { $0.rawValue }.joined(separator: ", "))
                                .font(.caption2)
                        }
                        .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Swipe feedback overlay
            if feedbackOpacity > 0 {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(feedbackText == "Liked" ? Color.green.opacity(0.8) : Color.red.opacity(0.8))

                    VStack {
                        Image(systemName: feedbackText == "Liked" ? "heart.fill" : "xmark")
                            .font(.system(size: 60))
                            .foregroundColor(.white)

                        Text(feedbackText)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
                .opacity(feedbackOpacity)
            }
        }
        .frame(width: 350, height: 500)
        .offset(x: offset.width, y: offset.height * 0.4)
        .rotationEffect(.degrees(rotation))
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    offset = gesture.translation
                    rotation = Double(gesture.translation.width / 20)

                    // Show feedback as user swipes
                    if abs(gesture.translation.width) > swipeThreshold {
                        feedbackText = gesture.translation.width > 0 ? "Liked" : "Skipped"
                        feedbackOpacity = min(abs(gesture.translation.width) / 200, 0.7)
                    } else {
                        feedbackOpacity = 0
                    }
                }
                .onEnded { gesture in
                    let swipeDistance = gesture.translation.width

                    if swipeDistance > swipeThreshold {
                        // Swipe right - Like
                        animateSwipeOff(to: .trailing, action: .like)
                    } else if swipeDistance < -swipeThreshold {
                        // Swipe left - Skip
                        animateSwipeOff(to: .leading, action: .skip)
                    } else {
                        // Reset card position
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            offset = .zero
                            rotation = 0
                            feedbackOpacity = 0
                        }
                    }
                }
        )
    }

    /// Animate card swiping off screen
    private func animateSwipeOff(to edge: Edge, action: SwipeAction) {
        let swipeOffDistance: CGFloat = 500

        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            offset = CGSize(
                width: edge == .trailing ? swipeOffDistance : -swipeOffDistance,
                height: 0
            )
            rotation = edge == .trailing ? rotationAmount * 2 : -rotationAmount * 2
            feedbackOpacity = 1.0
        }

        // Trigger callback after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            onSwipe(action)
        }
    }
}

// MARK: - Preview

#Preview {
    SwipeCardView(
        song: Song(
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
        onSwipe: { _ in }
    )
    .padding()
}
