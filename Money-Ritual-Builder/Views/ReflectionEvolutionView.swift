import SwiftUI
import CoreData

struct ReflectionEvolutionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MoneyRitual.createdAt, ascending: false)],
        animation: .default
    ) private var rituals: FetchedResults<MoneyRitual>
    
    @State private var reflectionText: String = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                RitualTheme.warmIvory(colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: RitualTheme.padding) {
                        // Monthly reflection prompt
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Monthly Reflection")
                                .font(RitualTheme.ritualTitleFont)
                                .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme))
                            
                            Text("How did these rituals change your money relationship?")
                                .font(RitualTheme.bodyFont)
                                .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme).opacity(0.8))
                            
                            Text("This is a private personal habit and ritual journal. Not financial advice or spiritual guidance.")
                                .font(.system(size: 11))
                                .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme).opacity(0.5))
                                .padding(.top, 8)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(RitualTheme.padding)
                        .background(RitualTheme.parchment(colorScheme: colorScheme))
                        .cornerRadius(RitualTheme.cornerRadius)
                        .padding(.horizontal, RitualTheme.padding)
                        .padding(.top, 20)
                        
                        // Rituals with history
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Ritual History")
                                .font(RitualTheme.ritualTitleFont)
                                .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme))
                            
                            ForEach(Array(rituals)) { ritual in
                                RitualHistoryCard(ritual: ritual)
                            }
                        }
                        .padding(.horizontal, RitualTheme.padding)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Reflection & Evolution")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct RitualHistoryCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let ritual: MoneyRitual
    
    var completions: [RitualCompletion] {
        (ritual.completions as? Set<RitualCompletion> ?? [])
            .sorted { ($0.date ?? Date.distantPast) > ($1.date ?? Date.distantPast) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                if let iconName = ritual.symbolIcon {
                    Image(systemName: iconName)
                        .font(.system(size: 24))
                        .foregroundColor(RitualTheme.deepAmber)
                }
                
                Text(ritual.name ?? "Unnamed Ritual")
                    .font(RitualTheme.ritualNameFont)
                    .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme))
                
                Spacer()
            }
            
            // Creation date
            if let createdAt = ritual.createdAt {
                Text("Created: \(createdAt, format: .dateTime.month().day().year())")
                    .font(RitualTheme.captionFont)
                    .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme).opacity(0.6))
            }
            
            // Last updated
            if let updatedAt = ritual.updatedAt, updatedAt != ritual.createdAt {
                Text("Last modified: \(updatedAt, format: .dateTime.month().day().year())")
                    .font(RitualTheme.captionFont)
                    .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme).opacity(0.6))
            }
            
            // Completions with reflections
            if !completions.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Reflections")
                        .font(RitualTheme.bodyFont)
                        .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme))
                    
                    ForEach(completions.prefix(3)) { completion in
                        if let reflection = completion.reflection, !reflection.isEmpty,
                           let date = completion.date {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(date, format: .dateTime.month().day().year())
                                    .font(.system(size: 11))
                                    .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme).opacity(0.5))
                                
                                Text(reflection)
                                    .font(RitualTheme.bodyFont)
                                    .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme).opacity(0.8))
                            }
                            .padding(12)
                            .background(RitualTheme.warmIvory(colorScheme: colorScheme))
                            .cornerRadius(12)
                        }
                    }
                }
            }
            
            NavigationLink(destination: AddReflectionView(ritual: ritual)) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Reflection")
                }
                .font(RitualTheme.bodyFont)
                .foregroundColor(RitualTheme.deepAmber)
            }
        }
        .padding(RitualTheme.padding)
        .background(RitualTheme.parchment(colorScheme: colorScheme))
        .cornerRadius(RitualTheme.cornerRadius)
    }
}

struct AddReflectionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @ObservedObject var ritual: MoneyRitual
    @State private var reflection: String = ""
    @State private var selectedDate: Date = Date()
    
    var body: some View {
        NavigationStack {
            ZStack {
                RitualTheme.warmIvory(colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: RitualTheme.padding) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Add Reflection")
                            .font(RitualTheme.ritualTitleFont)
                            .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme))
                        
                        DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                            .font(RitualTheme.bodyFont)
                        
                        TextField("Your reflection...", text: $reflection, axis: .vertical)
                            .font(RitualTheme.bodyFont)
                            .padding()
                            .background(RitualTheme.parchment(colorScheme: colorScheme))
                            .cornerRadius(RitualTheme.cornerRadius)
                            .lineLimit(5...10)
                    }
                    .padding(RitualTheme.padding)
                    
                    Spacer()
                    
                    Button(action: {
                        saveReflection()
                    }) {
                        Text("Save Reflection")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(RitualTheme.warmIvory(colorScheme: colorScheme))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(RitualTheme.deepAmber)
                            .cornerRadius(RitualTheme.cornerRadius)
                    }
                    .padding(.horizontal, RitualTheme.padding)
                    .padding(.bottom, 40)
                    .disabled(reflection.isEmpty)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
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
    }
    
    @State private var showingError = false
    @State private var errorMessage = ""
    
    private func saveReflection() {
        // Validate reflection
        let trimmedReflection = reflection.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedReflection.isEmpty else {
            errorMessage = "Reflection cannot be empty"
            showingError = true
            return
        }
        
        // Validate date
        let validation = RitualValidation.validateCompletion(ritual: ritual, date: selectedDate)
        guard validation.isValid else {
            errorMessage = validation.errorMessage ?? "Invalid date"
            showingError = true
            return
        }
        
        // Find or create completion for this date
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        
        let existingCompletion = (ritual.completions as? Set<RitualCompletion>)?.first { completion in
            guard let date = completion.date else { return false }
            return date >= startOfDay && date < endOfDay
        }
        
        let completion = existingCompletion ?? RitualCompletion(context: viewContext)
        if existingCompletion == nil {
            completion.id = UUID()
            completion.ritual = ritual
            completion.date = selectedDate
            completion.completed = false
        }
        completion.reflection = trimmedReflection
        
        do {
            try CoreDataStack.shared.save()
            RitualCalculations.invalidateCache(for: ritual.id)
            dismiss()
        } catch {
            errorMessage = "Failed to save reflection: \(error.localizedDescription)"
            showingError = true
        }
    }
}

#Preview {
    ReflectionEvolutionView()
        .environment(\.managedObjectContext, CoreDataStack.shared.viewContext)
}
