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

// MARK: - Custom Shake Effect Modifier
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 8
    var shakesPerUnit: CGFloat = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(translationX: amount * sin(animatableData * .pi * shakesPerUnit), y: 0)
        )
    }
}

extension View {
    func errorShake(trigger: Int) -> some View {
        self.modifier(ShakeEffect(animatableData: CGFloat(trigger)))
    }
}

// MARK: - Main View
struct WorkoutHeatmapView: View {
    @State private var days: [WorkoutDay] = WorkoutHeatmapView.generateMockData()
    @State private var selectedDay: WorkoutDay? = nil
    @State private var showRestToast: Bool = false
    @State private var shakeTrigger: Int = 0
    @State private var errorHapticFeedback: Int = 0
    
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
                    Text("August 2026")
                        .font(.system(size: 16, weight: .bold))
                    Text("Past 30 Days")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer(minLength: 12)
                
                HStack(spacing: 6) {
                    HStack(spacing: 3) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.pink)
                        Text("\(totalActiveDays) workouts")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.pink.opacity(0.1), in: Capsule())

                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.orange)
                        Text("\(currentStreak) Streak")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1), in: Capsule())
                }
            }
            
            // MARK: Vertical Bar Heatmap
            HStack(spacing: 4) {
                ForEach(days) { day in
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
                                // Trigger error feedback & shake animation
                                errorHapticFeedback += 1
                                withAnimation(.default) {
                                    shakeTrigger += 1
                                    showRestToast = true
                                }
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedDay = nil
                                }
                            } else {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    selectedDay = (selectedDay?.id == day.id) ? nil : day
                                }
                            }
                        }
                }
            }
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
                .errorShake(trigger: shakeTrigger)
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .opacity
                ))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showRestToast = false
                        }
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

    // MARK: - Mock Data Generator
    static func generateMockData() -> [WorkoutDay] {
        let calendar = Calendar.current
        let today = Date()
        
        let sampleWorkouts = [
            ("Upper Body Push", "figure.strengthtraining.traditional"),
            ("Lower Body Heavy", "figure.squat"),
            ("Cardio & Core", "figure.run"),
            ("Pull & Biceps", "figure.cross.training")
        ]
        
        let sampleSongs = [
            Song(title: "Novia Robot", artist: "Rosalia", playlistURL: "https://open.spotify.com/track/501aZny32oS5iewdx3e4Eu?si=9f1b84d3164a4d0b"),
            Song(title: "Tennessee Heat", artist: "Katie Tupper", playlistURL: "https://open.spotify.com"),
            Song(title: "Be About You", artist: "Winston Surfshirt", playlistURL: "https://open.spotify.com")
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

// MARK: - Dropdown Modal Subview
struct WorkoutDetailModal: View {
    let day: WorkoutDay
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            
            // Header Row with Top-Right Close Button
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Label(day.workoutType ?? "Workout", systemImage: day.typeIcon ?? "figure.run")
                        .font(.system(size: 13, weight: .semibold))
                    
                    HStack(spacing: 12) {
                        Label("\(day.durationMinutes) mins", systemImage: "clock")
                        Label(day.location ?? "Gym", systemImage: day.location == "Home" ? "house.fill" : "building.2.fill")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Top-Right Icon-Only Close Button
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(4)
                }
            }
            .padding(12)
            .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            // Music / Playlist Link Card
            if let song = day.songs.first, let url = URL(string: song.playlistURL) {
                Link(destination: url) {
                    HStack(spacing: 12) {
                        // Squoval Thumbnail Image
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                            
                            Image(systemName: "music.note.list")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .frame(width: 44, height: 44)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Workout Playlist")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.primary)
                            
                            Text("\(song.title) • \(song.artist)")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(10)
                    .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                    )
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.gray.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Preview Window
#Preview("Centered Device Prototype") {
    ZStack {
        // Multi Platform Screen Background
        Color(.white)
            .ignoresSafeArea()
        
        // Centered Card Container with Inset Padding
        WorkoutHeatmapView()
            .frame(maxWidth: 360)
            .padding(.horizontal, 24)
            .padding(.vertical, 40)
    }
}
