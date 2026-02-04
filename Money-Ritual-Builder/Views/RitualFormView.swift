import SwiftUI
import CoreData
import PhotosUI
import UIKit

struct RitualFormView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    let ritual: MoneyRitual?
    
    @State private var name: String = ""
    @State private var frequency: String = "Daily"
    @State private var trigger: String = ""
    @State private var steps: [String] = [""]
    @State private var symbolIcon: String = "sparkles"
    @State private var symbolPhoto: UIImage?
    @State private var intention: String = ""
    @State private var reminderEnabled: Bool = false
    @State private var selectedPhoto: PhotosPickerItem?
    
    let frequencies = ["Daily", "Weekly", "Monthly", "Custom"]
    let availableIcons = ["sparkles", "leaf.fill", "heart.fill", "star.fill", "moon.fill", "sun.max.fill", "flame.fill", "drop.fill", "circle.fill", "diamond.fill"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                RitualTheme.warmIvory(colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                Form {
                    Section {
                        TextField("Ritual name", text: $name)
                            .font(RitualTheme.bodyFont)
                    } header: {
                        Text("Ritual Name")
                    }
                    
                    Section {
                        Picker("Frequency", selection: $frequency) {
                            ForEach(frequencies, id: \.self) { freq in
                                Text(freq).tag(freq)
                            }
                        }
                        .font(RitualTheme.bodyFont)
                    } header: {
                        Text("Frequency")
                    }
                    
                    Section {
                        TextField("Trigger time or situation", text: $trigger)
                            .font(RitualTheme.bodyFont)
                    } header: {
                        Text("Trigger")
                    } footer: {
                        Text("When or where does this ritual happen?")
                    }
                    
                    Section {
                        ForEach(steps.indices, id: \.self) { index in
                            TextField("Step \(index + 1)", text: Binding(
                                get: { steps[index] },
                                set: { steps[index] = $0 }
                            ))
                            .font(RitualTheme.bodyFont)
                        }
                        .onDelete { indices in
                            steps.remove(atOffsets: indices)
                        }
                        
                        Button(action: {
                            if steps.count < 7 {
                                steps.append("")
                            }
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Step")
                            }
                            .foregroundColor(RitualTheme.deepAmber)
                        }
                        .disabled(steps.count >= 7)
                    } header: {
                        Text("Core Action Steps")
                    } footer: {
                        Text("3-7 steps that define your ritual")
                    }
                    
                    Section {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Symbolic Element")
                                .font(RitualTheme.bodyFont)
                            
                            // Icon picker
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(availableIcons, id: \.self) { icon in
                                        Button(action: {
                                            symbolIcon = icon
                                            symbolPhoto = nil
                                        }) {
                                            Image(systemName: icon)
                                                .font(.system(size: 32))
                                                .foregroundColor(symbolIcon == icon ? RitualTheme.warmIvory(colorScheme: colorScheme) : RitualTheme.charcoal(colorScheme: colorScheme))
                                                .frame(width: 60, height: 60)
                                                .background(symbolIcon == icon ? RitualTheme.deepAmber : RitualTheme.parchment(colorScheme: colorScheme))
                                                .cornerRadius(16)
                                        }
                                    }
                                }
                            }
                            
                            // Photo picker
                            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                HStack {
                                    Image(systemName: "photo.fill")
                                    Text("Choose Photo")
                                }
                                .font(RitualTheme.bodyFont)
                                .foregroundColor(RitualTheme.deepAmber)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(RitualTheme.parchment(colorScheme: colorScheme))
                                .cornerRadius(16)
                            }
                            
                            if let photo = symbolPhoto {
                                Image(uiImage: photo)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .cornerRadius(16)
                            }
                        }
                    } header: {
                        Text("Symbol")
                    }
                    
                    Section {
                        TextField("Intention or purpose", text: $intention, axis: .vertical)
                            .font(RitualTheme.bodyFont)
                            .lineLimit(3...6)
                    } header: {
                        Text("Intention")
                    }
                    
                    Section {
                        Toggle("Enable Reminder", isOn: $reminderEnabled)
                            .font(RitualTheme.bodyFont)
                    } header: {
                        Text("Reminders")
                    }
                    
                    Section {
                        Text("This is a private personal habit and ritual journal. Not financial advice or spiritual guidance.")
                            .font(.system(size: 11))
                            .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme).opacity(0.5))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(ritual == nil ? "New Ritual" : "Edit Ritual")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveRitual()
                    }
                    .foregroundColor(RitualTheme.deepAmber)
                    .disabled(name.isEmpty || steps.filter { !$0.isEmpty }.count < 3)
                }
            }
            .onAppear {
                if let ritual = ritual {
                    loadRitual(ritual)
                }
            }
            .onChange(of: selectedPhoto) { newValue in
                Task {
                    if let newValue = newValue {
                        if let data = try? await newValue.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            symbolPhoto = image
                            symbolIcon = ""
                        }
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func loadRitual(_ ritual: MoneyRitual) {
        name = ritual.name ?? ""
        frequency = ritual.frequency ?? "Daily"
        trigger = ritual.trigger ?? ""
        steps = ritual.stepsArray.isEmpty ? [""] : ritual.stepsArray
        symbolIcon = ritual.symbolIcon ?? "sparkles"
        intention = ritual.intention ?? ""
        reminderEnabled = ritual.reminderEnabled
        
        if let photoData = ritual.symbolPhotoData,
           let image = UIImage(data: photoData) {
            symbolPhoto = image
        }
    }
    
    @State private var showingError = false
    @State private var errorMessage = ""
    
    private func saveRitual() {
        // Validate ritual data
        let validation = RitualValidation.validateRitual(name: name, steps: steps)
        guard validation.isValid else {
            errorMessage = validation.errorMessage ?? "Invalid ritual data"
            showingError = true
            return
        }
        
        let ritualToSave: MoneyRitual
        if let existingRitual = ritual {
            ritualToSave = existingRitual
            // Invalidate cache for updated ritual
            RitualCalculations.invalidateCache(for: existingRitual.id)
        } else {
            ritualToSave = MoneyRitual(context: viewContext)
            ritualToSave.id = UUID()
            ritualToSave.createdAt = Date()
        }
        
        ritualToSave.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        ritualToSave.frequency = frequency
        ritualToSave.trigger = trigger.isEmpty ? nil : trigger.trimmingCharacters(in: .whitespacesAndNewlines)
        ritualToSave.stepsArray = steps.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        ritualToSave.symbolIcon = symbolPhoto == nil ? symbolIcon : nil
        ritualToSave.symbolPhotoData = symbolPhoto?.jpegData(compressionQuality: 0.8)
        ritualToSave.intention = intention.isEmpty ? nil : intention.trimmingCharacters(in: .whitespacesAndNewlines)
        ritualToSave.reminderEnabled = reminderEnabled
        ritualToSave.updatedAt = Date()
        ritualToSave.isArchived = false
        ritualToSave.isPaused = false
        
        do {
            try CoreDataStack.shared.save()
            
            // Schedule reminder if enabled
            if reminderEnabled {
                ReminderManager.shared.scheduleReminder(for: ritualToSave)
            } else {
                ReminderManager.shared.cancelReminder(for: ritualToSave)
            }
            
            dismiss()
        } catch {
            errorMessage = "Failed to save ritual: \(error.localizedDescription)"
            showingError = true
        }
    }
}

#Preview {
    RitualFormView(ritual: nil)
        .environment(\.managedObjectContext, CoreDataStack.shared.viewContext)
}
