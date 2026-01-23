import SwiftUI
import CoreData

struct ArchivedRitualsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MoneyRitual.updatedAt, ascending: false)],
        predicate: NSPredicate(format: "isArchived == YES"),
        animation: .default
    ) private var archivedRituals: FetchedResults<MoneyRitual>
    
    @State private var showingReviveConfirmation: MoneyRitual?
    
    var body: some View {
        NavigationStack {
            ZStack {
                RitualTheme.warmIvory(colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                if archivedRituals.isEmpty {
                    VStack(spacing: 24) {
                        Image(systemName: "archivebox.fill")
                            .font(.system(size: 60))
                            .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme).opacity(0.3))
                        
                        Text("No Archived Rituals")
                            .font(RitualTheme.ritualNameFont)
                            .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme).opacity(0.6))
                        
                        Text("Rituals you archive will appear here")
                            .font(RitualTheme.bodyFont)
                            .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme).opacity(0.5))
                            .multilineTextAlignment(.center)
                    }
                    .padding(RitualTheme.padding)
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(archivedRituals) { ritual in
                                ArchivedRitualCard(ritual: ritual, onRevive: {
                                    showingReviveConfirmation = ritual
                                }, onMarkLifelong: {
                                    markAsLifelong(ritual)
                                })
                            }
                        }
                        .padding(RitualTheme.padding)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Archived Rituals")
            .navigationBarTitleDisplayMode(.large)
            .alert("Revive Ritual", isPresented: Binding(
                get: { showingReviveConfirmation != nil },
                set: { if !$0 { showingReviveConfirmation = nil } }
            )) {
                Button("Cancel", role: .cancel) {}
                Button("Revive") {
                    if let ritual = showingReviveConfirmation {
                        reviveRitual(ritual)
                    }
                }
            } message: {
                Text("This ritual will be restored to your active rituals.")
            }
        }
    }
    
    private func reviveRitual(_ ritual: MoneyRitual) {
        ritual.isArchived = false
        ritual.isPaused = false
        
        do {
            try CoreDataStack.shared.save()
            RitualCalculations.invalidateCache(for: ritual.id)
            
            // Schedule reminder if enabled
            if ritual.reminderEnabled {
                ReminderManager.shared.scheduleReminder(for: ritual)
            }
        } catch {
            // Revert on error
            ritual.isArchived = true
        }
    }
    
    private func markAsLifelong(_ ritual: MoneyRitual) {
        // Keep it archived (lifelong rituals stay archived)
        ritual.isArchived = true
        
        do {
            try CoreDataStack.shared.save()
        } catch {
            // Silent failure
        }
    }
}

struct ArchivedRitualCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let ritual: MoneyRitual
    let onRevive: () -> Void
    let onMarkLifelong: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            NavigationLink(destination: RitualDetailView(ritual: ritual)) {
                HStack(spacing: 16) {
                    if let iconName = ritual.symbolIcon {
                        Image(systemName: iconName)
                            .font(.system(size: 32))
                            .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme).opacity(0.6))
                            .frame(width: 60, height: 60)
                            .background(RitualTheme.parchment(colorScheme: colorScheme))
                            .cornerRadius(16)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(ritual.name ?? "Unnamed Ritual")
                            .font(RitualTheme.ritualNameFont)
                            .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme).opacity(0.7))
                        
                        if let updatedAt = ritual.updatedAt {
                            Text("Archived: \(updatedAt, format: .dateTime.month().day().year())")
                                .font(RitualTheme.captionFont)
                                .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme).opacity(0.5))
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme).opacity(0.4))
                }
            }
            
            HStack(spacing: 12) {
                Button(action: onRevive) {
                    Text("Revive")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(RitualTheme.deepAmber)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(RitualTheme.parchment(colorScheme: colorScheme))
                        .cornerRadius(16)
                }
                
                Button(action: onMarkLifelong) {
                    Text("Mark as Lifelong")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme).opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(RitualTheme.parchment(colorScheme: colorScheme))
                        .cornerRadius(16)
                }
            }
        }
        .padding(RitualTheme.padding)
        .background(RitualTheme.parchment(colorScheme: colorScheme))
        .cornerRadius(RitualTheme.cornerRadius)
    }
}

#Preview {
    ArchivedRitualsView()
        .environment(\.managedObjectContext, CoreDataStack.shared.viewContext)
}
