import SwiftUI
import CoreData
import UIKit

struct RitualDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @ObservedObject var ritual: MoneyRitual
    @State private var showingArchiveConfirmation = false
    @State private var completedSteps: Set<Int> = []
    
    var completions: [RitualCompletion] {
        (ritual.completions as? Set<RitualCompletion> ?? [])
            .sorted { ($0.date ?? Date.distantPast) > ($1.date ?? Date.distantPast) }
    }
    
    var streak: Int {
        RitualCalculations.calculateStreak(for: ritual)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                RitualTheme.warmIvory(colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: RitualTheme.padding) {
                        // Header with icon
                        VStack(spacing: 20) {
                            if let photoData = ritual.symbolPhotoData,
                               let image = UIImage(data: photoData) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .cornerRadius(RitualTheme.cornerRadius)
                            } else if let iconName = ritual.symbolIcon {
                                Image(systemName: iconName)
                                    .font(.system(size: 60))
                                    .foregroundColor(RitualTheme.deepAmber)
                                    .frame(width: 120, height: 120)
                                    .background(RitualTheme.parchment(colorScheme: colorScheme))
                                    .cornerRadius(RitualTheme.cornerRadius)
                            }
                            
                            Text(ritual.name ?? "Unnamed Ritual")
                                .font(RitualTheme.ritualTitleFont)
                                .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme))
                                .multilineTextAlignment(.center)
                            
                            HStack(spacing: 16) {
                                // Frequency badge
                                Text(ritual.frequency ?? "Daily")
                                    .font(RitualTheme.captionFont)
                                    .foregroundColor(RitualTheme.deepAmber)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(RitualTheme.parchment(colorScheme: colorScheme))
                                    .cornerRadius(16)
                                
                                // Streak
                                if streak > 0 {
                                    HStack(spacing: 6) {
                                        CandleFlameView(size: 20, isAnimated: true)
                                        Text("\(streak) day streak")
                                            .font(RitualTheme.captionFont)
                                            .foregroundColor(RitualTheme.deepAmber)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(RitualTheme.parchment(colorScheme: colorScheme))
                                    .cornerRadius(16)
                                }
                            }
                        }
                        .padding(.top, 20)
                        .padding(.horizontal, RitualTheme.padding)
                        
                        // Next due
                        if let nextDue = nextDueDate() {
                            VStack(spacing: 8) {
                                Text("Next due")
                                    .font(RitualTheme.captionFont)
                                    .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme).opacity(0.6))
                                Text(nextDue, style: .relative)
                                    .font(RitualTheme.bodyFont)
                                    .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme))
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(RitualTheme.parchment(colorScheme: colorScheme))
                            .cornerRadius(RitualTheme.cornerRadius)
                            .padding(.horizontal, RitualTheme.padding)
                        }
                        
                        // Steps checklist
                        let steps = ritual.stepsArray
                        if !steps.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Ritual Steps")
                                    .font(RitualTheme.ritualNameFont)
                                    .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme))
                                
                                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                                    if !step.isEmpty {
                                        StepCheckboxView(
                                            step: step,
                                            isCompleted: completedSteps.contains(index),
                                            onToggle: {
                                                if completedSteps.contains(index) {
                                                    completedSteps.remove(index)
                                                } else {
                                                    completedSteps.insert(index)
                                                }
                                            }
                                        )
                                    }
                                }
                            }
                            .padding(RitualTheme.padding)
                            .background(RitualTheme.parchment(colorScheme: colorScheme))
                            .cornerRadius(RitualTheme.cornerRadius)
                            .padding(.horizontal, RitualTheme.padding)
                        }
                        
                        // Intention
                        if let intention = ritual.intention, !intention.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Intention")
                                    .font(RitualTheme.ritualNameFont)
                                    .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme))
                                Text(intention)
                                    .font(RitualTheme.bodyFont)
                                    .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme).opacity(0.8))
                            }
                            .padding(RitualTheme.padding)
                            .background(RitualTheme.parchment(colorScheme: colorScheme))
                            .cornerRadius(RitualTheme.cornerRadius)
                            .padding(.horizontal, RitualTheme.padding)
                        }
                        
                        // Action buttons
                        VStack(spacing: 12) {
                            NavigationLink(destination: QuickCompletionLogView(ritual: ritual)) {
                                Text("Mark as Completed Today")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(RitualTheme.warmIvory(colorScheme: colorScheme))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)
                                    .background(RitualTheme.deepAmber)
                                    .cornerRadius(RitualTheme.cornerRadius)
                            }
                            
                            HStack(spacing: 12) {
                                NavigationLink(destination: RitualFormView(ritual: ritual)) {
                                    Text("Edit")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(RitualTheme.deepAmber)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(RitualTheme.parchment(colorScheme: colorScheme))
                                        .cornerRadius(RitualTheme.cornerRadius)
                                }
                                
                                Button(action: {
                                    togglePause()
                                }) {
                                    Text(ritual.isPaused ? "Resume" : "Pause")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(RitualTheme.deepAmber)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(RitualTheme.parchment(colorScheme: colorScheme))
                                        .cornerRadius(RitualTheme.cornerRadius)
                                }
                                
                                Button(action: {
                                    showingArchiveConfirmation = true
                                }) {
                                    Text("Archive")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme).opacity(0.7))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(RitualTheme.parchment(colorScheme: colorScheme))
                                        .cornerRadius(RitualTheme.cornerRadius)
                                }
                            }
                        }
                        .padding(.horizontal, RitualTheme.padding)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme))
                }
            }
            .alert("Archive Ritual", isPresented: $showingArchiveConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Archive", role: .destructive) {
                    archiveRitual()
                }
            } message: {
                Text("This ritual will be moved to your archive. You can restore it later.")
            }
        }
    }
    
    private func nextDueDate() -> Date? {
        guard let frequency = ritual.frequency else { return nil }
        let calendar = Calendar.current
        
        switch frequency {
        case "Daily":
            return calendar.date(byAdding: .day, value: 1, to: Date())
        case "Weekly":
            return calendar.date(byAdding: .weekOfYear, value: 1, to: Date())
        case "Monthly":
            return calendar.date(byAdding: .month, value: 1, to: Date())
        default:
            return nil
        }
    }
    
    private func togglePause() {
        ritual.isPaused.toggle()
        do {
            try CoreDataStack.shared.save()
            RitualCalculations.invalidateCache(for: ritual.id)
            
            // Update reminders
            if ritual.isPaused {
                ReminderManager.shared.cancelReminder(for: ritual)
            } else if ritual.reminderEnabled {
                ReminderManager.shared.scheduleReminder(for: ritual)
            }
        } catch {
            // Silent failure - user can retry
            ritual.isPaused.toggle() // Revert on error
        }
    }
    
    private func archiveRitual() {
        ritual.isArchived = true
        ritual.isPaused = false
        
        do {
            try CoreDataStack.shared.save()
            RitualCalculations.invalidateCache(for: ritual.id)
            ReminderManager.shared.cancelReminder(for: ritual)
            dismiss()
        } catch {
            // Revert on error
            ritual.isArchived = false
        }
    }
}

struct StepCheckboxView: View {
    @Environment(\.colorScheme) private var colorScheme
    let step: String
    let isCompleted: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isCompleted ? RitualTheme.deepAmber : Color.clear)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(RitualTheme.deepAmber, lineWidth: 2)
                        )
                    
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(RitualTheme.warmIvory(colorScheme: colorScheme))
                    }
                }
                
                Text(step)
                    .font(RitualTheme.bodyFont)
                    .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme))
                    .strikethrough(isCompleted)
                    .opacity(isCompleted ? 0.6 : 1.0)
                
                Spacer()
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    let context = CoreDataStack.shared.viewContext
    let ritual = MoneyRitual(context: context)
    ritual.id = UUID()
    ritual.name = "Sunday Money Gratitude"
    ritual.frequency = "Weekly"
    ritual.stepsArray = ["Write 3 things I'm grateful for", "Reflect on abundance", "Set intention for the week"]
    ritual.createdAt = Date()
    ritual.updatedAt = Date()
    
    return RitualDetailView(ritual: ritual)
        .environment(\.managedObjectContext, context)
}
