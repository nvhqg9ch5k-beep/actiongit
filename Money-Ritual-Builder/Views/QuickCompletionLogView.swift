import SwiftUI
import CoreData

struct QuickCompletionLogView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @ObservedObject var ritual: MoneyRitual
    @State private var reflection: String = ""
    @State private var showReward = false
    
    var body: some View {
        ZStack {
            RitualTheme.warmIvory(colorScheme: colorScheme)
                .ignoresSafeArea()
            
            VStack(spacing: RitualTheme.padding) {
                Spacer()
                
                if showReward {
                    VStack(spacing: 40) {
                        LightExpandingView()
                        ParticleEffectView(count: 30, color: RitualTheme.warmGold)
                        
                        Text("Ritual Completed")
                            .font(RitualTheme.ritualTitleFont)
                            .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme))
                        
                        CandleFlameView(size: 80, isAnimated: true)
                    }
                    .transition(.opacity)
                } else {
                    VStack(spacing: 32) {
                        Text("Complete Ritual")
                            .font(RitualTheme.ritualTitleFont)
                            .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme))
                        
                        if let iconName = ritual.symbolIcon {
                            Image(systemName: iconName)
                                .font(.system(size: 60))
                                .foregroundColor(RitualTheme.deepAmber)
                        }
                        
                        Text(ritual.name ?? "Unnamed Ritual")
                            .font(RitualTheme.ritualNameFont)
                            .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme))
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Reflection (optional)")
                                .font(RitualTheme.bodyFont)
                                .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme))
                            
                            TextField("How did this ritual feel today?", text: $reflection, axis: .vertical)
                                .font(RitualTheme.bodyFont)
                                .padding()
                                .background(RitualTheme.parchment(colorScheme: colorScheme))
                                .cornerRadius(RitualTheme.cornerRadius)
                                .lineLimit(3...6)
                        }
                        .padding(.horizontal, RitualTheme.padding)
                        
                        Button(action: {
                            markCompleted()
                        }) {
                            Text("Mark as Completed")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(RitualTheme.warmIvory(colorScheme: colorScheme))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(RitualTheme.deepAmber)
                                .cornerRadius(RitualTheme.cornerRadius)
                        }
                        .padding(.horizontal, RitualTheme.padding)
                    }
                }
                
                Spacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme))
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    @State private var showingError = false
    @State private var errorMessage = ""
    
    private func markCompleted() {
        let completionDate = Date()
        
        // Validate completion
        let validation = RitualValidation.validateCompletion(ritual: ritual, date: completionDate)
        guard validation.isValid else {
            errorMessage = validation.errorMessage ?? "Cannot complete ritual"
            showingError = true
            return
        }
        
        let completion = RitualCompletion(context: viewContext)
        completion.id = UUID()
        completion.ritual = ritual
        completion.date = completionDate
        completion.reflection = reflection.isEmpty ? nil : reflection.trimmingCharacters(in: .whitespacesAndNewlines)
        completion.completed = true
        
        do {
            try CoreDataStack.shared.save()
            
            // Invalidate cache for updated ritual
            RitualCalculations.invalidateCache(for: ritual.id)
            
            withAnimation {
                showReward = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                dismiss()
            }
        } catch {
            errorMessage = "Failed to save completion: \(error.localizedDescription)"
            showingError = true
        }
    }
}

#Preview {
    let context = CoreDataStack.shared.viewContext
    let ritual = MoneyRitual(context: context)
    ritual.id = UUID()
    ritual.name = "Sunday Money Gratitude"
    ritual.frequency = "Weekly"
    ritual.symbolIcon = "sparkles"
    ritual.createdAt = Date()
    ritual.updatedAt = Date()
    
    return NavigationStack {
        QuickCompletionLogView(ritual: ritual)
    }
    .environment(\.managedObjectContext, context)
}
