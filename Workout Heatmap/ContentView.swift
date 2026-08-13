//
//  ContentView.swift
//  Workout Heatmap
//
//  Created by Dami Ojetunji on 10/08/2026.
//
import SwiftUI

// MARK: - Models
struct Song: Identifiable {
    let id = UUID()
    let title: String
    let artist: String
    let playlistURL: String
    let imageName: String? // Local asset name (e.g., "novia-robot-cover")
}

struct WorkoutDay: Identifiable {
    let id = UUID()
    let date: Date
    let durationMinutes: Int // 0 = rest day
    let workoutType: String?
    let typeIcon: String?
    let location: String?
    let songs: [Song]
    
    var barColor: Color {
        switch durationMinutes {
        case 0:
            return Color.gray.opacity(0.2)
        case 1...30:
            return Color.pink.opacity(0.4)
        case 31...60:
            return Color.pink.opacity(0.75)
        default:
            return Color.pink
        }
    }
}

// MARK: - Shake Effect
struct ShakeEffect: GeometryEffect {
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
            let translation = 8 * sin(animatableData * .pi * 3)
            return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
        }
    }

    extension View {
        func errorShake(trigger: CGFloat) -> some View {
            self.modifier(ShakeEffect(animatableData: trigger))   }
}

// MARK: - Main View
struct WorkoutHeatmapView: View {
    @State private var days: [WorkoutDay] = WorkoutHeatmapView.generateMockData()
    @State private var selectedDay: WorkoutDay? = nil
    @State private var showRestToast: Bool = false
    @State private var shakeOffset: CGFloat = 0
    @State private var errorHapticFeedback: Int = 0
    @State private var toastID = UUID()
    
    private var currentStreak: Int {
        var streak = 0
        for day in days.reversed() {
            if day.durationMinutes > 0 {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }
    
    private var totalActiveDays: Int {
        days.filter { $0.durationMinutes > 0 }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            
            // MARK: Top Header & Stat Badges
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("July 2026")
                        .font(.system(size: 16, weight: .bold))
                    Text("Past 31 Days")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer(minLength: 12)
                
                HStack(spacing: 6) {
                    HStack(spacing: 3) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.yellow)
                        Text("\(totalActiveDays) workouts")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.yellow.opacity(0.3
                                                    ), in: Capsule())

                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.orange)
                        Text("\(currentStreak) Streak")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2), in: Capsule())
                }
            }
            
            // MARK: Vertical Heatmap
            HStack(spacing: 0) {
                ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                    let isSelected = selectedDay?.id == day.id
                    let isAnySelected = selectedDay != nil
                    
                    Capsule()
                        .fill(day.barColor)
                        .frame(width: 4, height: isSelected ? 48 : 32)
                        .shadow(color: isSelected ? Color.pink.opacity(0.6) : .clear, radius: 4)
                        .opacity(isAnySelected ? (isSelected ? 1.0 : 0.35) : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedDay?.id)
                        .onTapGesture {
                            if day.durationMinutes == 0 {
                                errorHapticFeedback += 1
                                toastID = UUID()
                                
                                if showRestToast {
                                    withAnimation(.spring(response: 0.18, dampingFraction: 0.2)) {
                                        shakeOffset = (shakeOffset == 0) ? 1 : 0
                                    }
                                } else {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        showRestToast = true
                                        selectedDay = nil
                                    }
                                }
                            } else {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    selectedDay = (selectedDay?.id == day.id) ? nil : day
                                }
                            }
                        }
                    
                    // Equal spacing between bars to push the last bar flush to the right edge
                    if index < days.count - 1 {
                        Spacer(minLength: 2)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .sensoryFeedback(.error, trigger: errorHapticFeedback)
            
            // MARK: Expandable Dropdown Card
            if let day = selectedDay {
                WorkoutDetailModal(day: day) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedDay = nil
                    }
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity.combined(with: .scale(scale: 0.98))
                ))
            }
            
            // MARK: Toast PopUp
            if showRestToast {
                HStack(spacing: 8) {
                    Text("🛌")
                        .font(.system(size: 12))
                    Text("Rest day!")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(white: 0.12), in: Capsule())
                .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 6)
                .errorShake(trigger: shakeOffset)
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .opacity
                    ))
                .onAppear {
                    // Trigger shake immediately when the toast appears on screen
                    withAnimation(.spring(response: 0.18, dampingFraction: 0.2)) {
                        shakeOffset = (shakeOffset == 0) ? 1 : 0
                    }
                }
                        .task(id: toastID) {
                            try? await Task.sleep(nanoseconds: 2_000_000_000)
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showRestToast = false
                            }
                        }
                        .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .fixedSize(horizontal: false, vertical: true)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - Mock Data
    static func generateMockData() -> [WorkoutDay] {
        let calendar = Calendar.current
        let today = Date()
        
        let sampleWorkouts = [
            ("Shoulders & Triceps", "figure.strengthtraining.traditional"),
            ("Quads & Adductors", "figure.strengthtraining.functional"),
            ("Cardio & Core", "figure.core.training"),
            ("Back & Biceps", "figure.indoor.rowing")
        ]
        
        let sampleSongs = [
            Song(title: "Novia Robot", artist: "Rosalia", playlistURL: "https://open.spotify.com/track/501aZny32oS5iewdx3e4Eu?si=9f1b84d3164a4d0b",imageName: "Rosalia_Lux"),
            Song(title: "Ungenzani", artist: "Dlala Thunkzin, MK Productions", playlistURL: "https://open.spotify.com/track/4vGofrv3muNtIaJHsq7Cj1?si=dccd5e60166a44c6", imageName: "Ungenzani"),
            Song(title: "Tenner - Yosa & Kevin Lndn Remix", artist: "Lojay, Yosa, Kevin Lndn", playlistURL: "https://open.spotify.com/track/0dZxsrOQHkBp6FXBoRS8JS?si=ad5a0fa4e6534358", imageName: "tenner")
        ]

        return (0..<30).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -(29 - offset), to: today) else { return nil }
            
            let isRestDay = Bool.random() && Bool.random()
            if isRestDay {
                return WorkoutDay(date: date, durationMinutes: 0, workoutType: nil, typeIcon: nil, location: nil, songs: [])
            } else {
                let workout = sampleWorkouts.randomElement()!
                let duration = [30, 45, 60].randomElement()!
                let location = Bool.random() ? "Gym" : "Home"
                let workoutSongs = Array(sampleSongs.shuffled().prefix(1))
                
                return WorkoutDay(
                    date: date,
                    durationMinutes: duration,
                    workoutType: workout.0,
                    typeIcon: workout.1,
                    location: location,
                    songs: workoutSongs
                )
            }
        }
    }
}

// MARK: - Dropdown Modal
struct WorkoutDetailModal: View {
    let day: WorkoutDay
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            
            // 1. Top Header Row (Workout Info + Integrated Close Button)
            HStack(alignment: .top) {
                // Workout Info
                VStack(alignment: .leading, spacing: 10) {
                    Label(day.workoutType ?? "Workout", systemImage: day.typeIcon ?? "figure.run")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                    
                    // White Emoji Badges
                    HStack(spacing: 6) {
                        // Duration Badge
                        HStack(spacing: 4) {
                            Text("⏱️")
                                .font(.system(size: 10))
                            Text("\(day.durationMinutes) mins")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.primary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white, in: Capsule())
                        .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)

                        // Location Badge
                        HStack(spacing: 4) {
                            Text(day.location == "Home" ? "🏠" : "🏋️‍♂️")
                                .font(.system(size: 10))
                            Text(day.location ?? "Gym")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.primary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white, in: Capsule())
                        .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                    }
                }
                
                Spacer(minLength: 8)

                // High-Contrast Black Close Button
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.primary)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(Color.black.opacity(0.03), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            // 2. Playlist Section Header & Card
            if let song = day.songs.first {
                VStack(alignment: .leading, spacing: 6) {
                    Text("WORKOUT PLAYLIST")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.tertiary)
                        .padding(.leading, 2)

                    InteractivePlaylistCard(song: song)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}
// MARK: - Interactive Music Card (Hover & Click States)
struct InteractivePlaylistCard: View {
    let song: Song
    @Environment(\.openURL) private var openURL // 1. Add Environment Key
    @State private var isPressed: Bool = false
    @State private var isHovered: Bool = false

    var body: some View {
        Button(action: {
            if let url = URL(string: song.playlistURL) {
                openURL(url) // 2. Use openURL instead of UIApplication
            }
        }) {
            HStack(spacing: 12) {
                SpotifyThumbnailView(imageName: song.imageName, urlString: song.playlistURL)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(song.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Text(song.artist)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
            }
            .padding(10)
            .background(
                Color.black.opacity(isPressed ? 0.07 : (isHovered ? 0.05 : 0.03)),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .scaleEffect(isPressed ? 0.98 : (isHovered ? 1.01 : 1.0))
            .animation(.easeOut(duration: 0.15), value: isPressed)
            .animation(.easeOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        ._onButtonGesture { pressing in
            isPressed = pressing
        } perform: {}
    }
}

struct SpotifyThumbnailView: View {
    let imageName: String?
    let urlString: String
    @State private var imageURL: URL?

    private var fallbackIcon: some View {
        ZStack {
            Color.gray.opacity(0.15)
            Image(systemName: "music.note")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.secondary)
        }
    }

    var body: some View {
        ZStack {
            // 1. Check for Local Asset Image
            if let imageName = imageName, !imageName.isEmpty {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            
            // 2. Fall back to Remote Spotify oEmbed Image
            } else if let imageURL = imageURL {
                AsyncImage(url: imageURL) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        fallbackIcon
                    }
                }
            
            // 3. Fallback placeholder icon
            } else {
                fallbackIcon
            }
        }
        .frame(width: 44, height: 44)
        .background(Color.black.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .task(id: urlString) {
            if imageName == nil || imageName?.isEmpty == true {
                await fetchThumbnail()
            }
        }
    }

    private func fetchThumbnail() async {
        guard let encoded = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let reqURL = URL(string: "https://open.spotify.com/oembed?url=\(encoded)") else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: reqURL)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let thumbnailString = json["thumbnail_url"] as? String,
               let parsedURL = URL(string: thumbnailString) {
                await MainActor.run {
                    self.imageURL = parsedURL
                }
            }
        } catch {
            // Fails silently to fallbackIcon
        }
    }
}
// MARK: - Preview Window
#Preview("Interaction Showcase") {
    ZStack {
        // Soft Canvas Background (Khagwal off-white)
        Color(red: 0.96, green: 0.96, blue: 0.97)
            .ignoresSafeArea()
        
        // Centered Floating Card Frame
        VStack {
            WorkoutHeatmapView()
                .frame(width: 340) // Fixed width for mobile aspect ratio
        }
        .padding(32) // Outer margin around the card
    }
    .frame(width: 500, height: 600) // Fixed canvas size for screen recording
    }
