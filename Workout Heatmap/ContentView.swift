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
}

struct WorkoutDay: Identifiable {
    let id = UUID()
    let date: Date
    let durationMinutes: Int
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

// MARK: - Main View
struct WorkoutHeatmapView: View {
    @State private var days: [WorkoutDay] = WorkoutHeatmapView.generateMockData()
    @State private var selectedDay: WorkoutDay? = nil
    @State private var showRestToast: Bool = false
    
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
            
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("August 2026")
                        .font(.system(size: 16, weight: .medium))
                    Text("Past 30 Days")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer(minLength: 12)
                
                // Stat Pills
                HStack(spacing: 6) {
                    HStack(spacing: 3) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.pink)
                        Text("\(totalActiveDays)/30 Days")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1), in: Capsule())

                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.orange)
                        Text("\(currentStreak) Streak")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1), in: Capsule())
                }
            }
            
            // Heatmap Bar Row
            HStack(spacing: 6) {
                ForEach(days) { day in
                    let isSelected = selectedDay?.id == day.id
                    let isAnySelected = selectedDay != nil
                    
                    Capsule()
                        .fill(day.barColor)
                        .frame(width: 6, height: isSelected ? 48 : 32)
                        .shadow(color: isSelected ? Color.pink.opacity(0.6) : .clear, radius: 4)
                        .opacity(isAnySelected ? (isSelected ? 1.0 : 0.35) : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedDay?.id)
                        .onTapGesture {
                            if day.durationMinutes == 0 {
                                showRestToast = true
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedDay = nil
                                }
                            } else {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    selectedDay = (selectedDay?.id == day.id) ? nil : day
                                }
                            }
                        }
                        .sensoryFeedback(
                            day.durationMinutes == 0 ? .error : .impact(weight: .medium),
                            trigger: selectedDay?.id
                        )
                }
            }
            .frame(height: 50)
            
            // Rest Toast
            if showRestToast {
                HStack(spacing: 6) {
                    Image(systemName: "moon.stars.fill")
                        .font(.caption)
                        .foregroundStyle(.indigo)
                    Text("Nothing to show here!")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.indigo.opacity(0.1), in: Capsule())
                .overlay(Capsule().stroke(Color.indigo.opacity(0.2), lineWidth: 1))
                .transition(.move(edge: .top).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { showRestToast = false }
                    }
                }
            }

            // Modal Card
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
        }
        .padding(16)
        .fixedSize(horizontal: false, vertical: true)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.windowBackgroundColor)) // Pure cross-platform system fill
                .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

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
            Song(title: "Scott Street", artist: "Phoebe Bridgers"),
            Song(title: "Tennessee Heat", artist: "Katie Tupper"),
            Song(title: "Be About You", artist: "Winston Surfshirt")
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

// MARK: - Vinyl Disc Record View
struct VinylRecordView: View {
    let song: Song
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 56, height: 56)
                    
                    Circle()
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        .frame(width: 46, height: 46)
                    Circle()
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        .frame(width: 36, height: 36)
                    
                    Circle()
                        .fill(LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 24, height: 24)
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 5, height: 5)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(song.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.primary)
                    Text(song.artist)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding(10)
            .background(Color.primary.opacity(0.02))
            
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 6, height: 6)
                Text("Listening now")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.primary.opacity(0.04))
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - Detail Modal (Simplified expression hierarchy)
struct WorkoutDetailModal: View {
    let day: WorkoutDay
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            
            // Header Info Box
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label(day.workoutType ?? "Workout", systemImage: day.typeIcon ?? "figure.run")
                        .font(.system(size: 13, weight: .semibold))
                    Spacer()
                    Text(day.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: 12) {
                    Label("\(day.durationMinutes) mins", systemImage: "clock")
                    Label(day.location ?? "Gym", systemImage: day.location == "Home" ? "house.fill" : "building.2.fill")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            // Music View
            if let song = day.songs.first {
                VinylRecordView(song: song)
            }

            // Close Button
            Button(action: onClose) {
                HStack(spacing: 4) {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 12, weight: .bold))
                    Text("Close")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
            }
        }
        .padding(12)
        .background(modalBackground)
    }
    
    // Extracted view property to simplify type-checking
    private var modalBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.primary.opacity(0.02))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
    }
}

#Preview {
    WorkoutHeatmapView()
}
