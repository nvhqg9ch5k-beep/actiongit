import SwiftUI
import CoreData

struct MainDashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MoneyRitual.createdAt, ascending: false)],
        predicate: NSPredicate(format: "isArchived == NO"),
        animation: .default
    ) private var rituals: FetchedResults<MoneyRitual>
    
    var activeRituals: [MoneyRitual] {
        rituals.filter { !$0.isPaused }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                RitualTheme.warmIvory(colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: RitualTheme.padding) {
                        // Header
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Money Rituals")
                                .font(RitualTheme.ritualTitleFont)
                                .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme))
                            
                            Text("\(activeRituals.count) money rituals active")
                                .font(RitualTheme.bodyFont)
                                .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme).opacity(0.7))
                            
                            Text("This is a private personal habit and ritual journal. Not financial advice or spiritual guidance.")
                                .font(.system(size: 11))
                                .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme).opacity(0.5))
                                .padding(.top, 4)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, RitualTheme.padding)
                        .padding(.top, 20)
                        
                        // Current streak calendar preview
                        StreakCalendarPreview(rituals: Array(activeRituals))
                            .padding(.horizontal, RitualTheme.padding)
                        
                        // Ritual strength overview
                        RitualStrengthOverview(rituals: Array(activeRituals))
                            .padding(.horizontal, RitualTheme.padding)
                        
                        // Recent rituals
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Your Rituals")
                                .font(RitualTheme.ritualNameFont)
                                .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme))
                                .padding(.horizontal, RitualTheme.padding)
                            
                            ForEach(activeRituals.prefix(5)) { ritual in
                                NavigationLink(destination: RitualDetailView(ritual: ritual)) {
                                    RitualCardPreview(ritual: ritual)
                                }
                                .padding(.horizontal, RitualTheme.padding)
                            }
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 100)
                    }
                }
                
                // Floating create button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        NavigationLink(destination: RitualFormView(ritual: nil)) {
                            HStack(spacing: 12) {
                                Image(systemName: "plus")
                                    .font(.system(size: 20, weight: .semibold))
                                Text("Create New Ritual")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(RitualTheme.warmIvory(colorScheme: colorScheme))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                            .background(RitualTheme.deepAmber)
                            .cornerRadius(RitualTheme.cornerRadius)
                            .shadow(color: RitualTheme.deepAmber.opacity(0.3), radius: 12, x: 0, y: 6)
                        }
                        .padding(.trailing, RitualTheme.padding)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme))
                    }
                }
            }
        }
    }
}

struct StreakCalendarPreview: View {
    @Environment(\.colorScheme) private var colorScheme
    let rituals: [MoneyRitual]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Current Streak")
                .font(RitualTheme.ritualNameFont)
                .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme))
            
            HStack(spacing: 8) {
                ForEach(0..<7) { dayOffset in
                    let date = Calendar.current.date(byAdding: .day, value: -6 + dayOffset, to: Date()) ?? Date()
                    let isCompleted = hasCompletion(for: date)
                    
                    VStack(spacing: 8) {
                        Circle()
                            .fill(isCompleted ? RitualTheme.warmGold : RitualTheme.charcoal(colorScheme: colorScheme).opacity(0.2))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle()
                                    .stroke(RitualTheme.warmGold.opacity(isCompleted ? 0.5 : 0), lineWidth: 2)
                            )
                            .shadow(color: isCompleted ? RitualTheme.warmGold.opacity(0.4) : Color.clear, radius: 4)
                        
                        Text(dayName(for: date))
                            .font(.system(size: 10))
                            .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme).opacity(0.6))
                    }
                }
            }
        }
        .padding(RitualTheme.padding)
        .background(RitualTheme.parchment(colorScheme: colorScheme))
        .cornerRadius(RitualTheme.cornerRadius)
    }
    
    private func hasCompletion(for date: Date) -> Bool {
        let calendar = Calendar.current
        return rituals.contains { ritual in
            ritual.completions?.contains { completion in
                guard let completion = completion as? RitualCompletion,
                      let completionDate = completion.date else { return false }
                return calendar.isDate(completionDate, inSameDayAs: date) && completion.completed
            } ?? false
        }
    }
    
    private func dayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}

struct RitualStrengthOverview: View {
    @Environment(\.colorScheme) private var colorScheme
    let rituals: [MoneyRitual]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ritual Strength")
                .font(RitualTheme.ritualNameFont)
                .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme))
            
            HStack(spacing: 12) {
                ForEach(rituals.prefix(5)) { ritual in
                    let consistency = RitualCalculations.calculateConsistency(for: ritual)
                    VStack(spacing: 8) {
                        Circle()
                            .fill(RitualTheme.warmGold.opacity(0.3 + Double(consistency) / 100 * 0.7))
                            .frame(width: CGFloat(30 + consistency / 2), height: CGFloat(30 + consistency / 2))
                            .overlay(
                                Circle()
                                    .stroke(RitualTheme.warmGold, lineWidth: 2)
                            )
                            .shadow(color: RitualTheme.warmGold.opacity(0.3), radius: 4)
                        
                        Text("\(Int(consistency))%")
                            .font(.system(size: 10))
                            .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme).opacity(0.7))
                    }
                }
            }
        }
        .padding(RitualTheme.padding)
        .background(RitualTheme.parchment(colorScheme: colorScheme))
        .cornerRadius(RitualTheme.cornerRadius)
    }
}

struct RitualCardPreview: View {
    @Environment(\.colorScheme) private var colorScheme
    let ritual: MoneyRitual
    
    var body: some View {
        HStack(spacing: 16) {
            if let iconName = ritual.symbolIcon {
                Image(systemName: iconName)
                    .font(.system(size: 32))
                    .foregroundColor(RitualTheme.deepAmber)
                    .frame(width: 60, height: 60)
                    .background(RitualTheme.parchment(colorScheme: colorScheme))
                    .cornerRadius(16)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(ritual.name ?? "Unnamed Ritual")
                    .font(RitualTheme.ritualNameFont)
                    .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme))
                
                Text(ritual.frequency ?? "Daily")
                    .font(RitualTheme.captionFont)
                    .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme).opacity(0.6))
                
                let streak = RitualCalculations.calculateStreak(for: ritual)
                if streak > 0 {
                    HStack(spacing: 4) {
                        CandleFlameView(size: 16, isAnimated: true)
                        Text("\(streak) day streak")
                            .font(.system(size: 12))
                            .foregroundColor(RitualTheme.deepAmber)
                    }
                }
            }
            
            Spacer()
            
                Image(systemName: "chevron.right")
                    .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme).opacity(0.4))
            }
            .padding(RitualTheme.padding)
            .background(RitualTheme.parchment(colorScheme: colorScheme))
            .cornerRadius(RitualTheme.cornerRadius)
    }
}

#Preview {
    MainDashboardView()
        .environment(\.managedObjectContext, CoreDataStack.shared.viewContext)
}
