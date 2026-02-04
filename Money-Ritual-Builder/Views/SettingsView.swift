import SwiftUI
import CoreData

struct SettingsView: View {
    @AppStorage("theme") private var theme: String = "system"
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var systemColorScheme
    @State private var showingResetConfirmation = false
    @State private var resetConfirmationCount = 0
    
    var preferredColorScheme: ColorScheme? {
        switch theme {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                RitualTheme.warmIvory(colorScheme: systemColorScheme)
                    .ignoresSafeArea()
                
                Form {
                    Section {
                        Picker("Theme", selection: $theme) {
                            Text("Light").tag("light")
                            Text("Dark").tag("dark")
                            Text("System").tag("system")
                        }
                    } header: {
                        Text("Appearance")
                    }
                    
                    Section {
                        NavigationLink(destination: ArchivedRitualsView()) {
                            HStack {
                                Image(systemName: "archivebox.fill")
                                Text("Archived Rituals")
                            }
                        }
                        
                        NavigationLink(destination: ExportRitualBookView()) {
                            HStack {
                                Image(systemName: "square.and.arrow.up.fill")
                                Text("Export & Backup")
                            }
                        }
                        
                        Button(action: {
                            importBackup()
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.down.fill")
                                Text("Restore from Backup")
                            }
                            .foregroundColor(RitualTheme.charcoal(colorScheme: systemColorScheme))
                        }
                    } header: {
                        Text("Data")
                    }
                    
                    Section {
                        Button(role: .destructive, action: {
                            resetConfirmationCount += 1
                            if resetConfirmationCount >= 3 {
                                showingResetConfirmation = true
                            }
                        }) {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("Reset All Data")
                            }
                        }
                    } header: {
                        Text("Danger Zone")
                    } footer: {
                        Text("Tap 3 times to confirm. This cannot be undone.")
                    }
                    
                    Section {
                        Text("This is a private personal habit and ritual journal. Not financial advice or spiritual guidance.")
                            .font(.system(size: 11))
                            .foregroundColor(RitualTheme.charcoal(colorScheme: systemColorScheme).opacity(0.5))
                        
                        Text("Version 1.0")
                            .font(.system(size: 11))
                            .foregroundColor(RitualTheme.charcoal(colorScheme: systemColorScheme).opacity(0.5))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .preferredColorScheme(preferredColorScheme)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Reset All Data", isPresented: $showingResetConfirmation) {
                Button("Cancel", role: .cancel) {
                    resetConfirmationCount = 0
                }
                Button("Reset", role: .destructive) {
                    resetAllData()
                    resetConfirmationCount = 0
                }
            } message: {
                Text("This will permanently delete all your rituals and completions. This action cannot be undone.")
            }
        }
    }
    
    private func importBackup() {
        // Would open document picker to import backup
        // For now, just a placeholder
    }
    
    private func resetAllData() {
        let fetchRequest1: NSFetchRequest<NSFetchRequestResult> = MoneyRitual.fetchRequest()
        let deleteRequest1 = NSBatchDeleteRequest(fetchRequest: fetchRequest1)
        
        let fetchRequest2: NSFetchRequest<NSFetchRequestResult> = RitualCompletion.fetchRequest()
        let deleteRequest2 = NSBatchDeleteRequest(fetchRequest: fetchRequest2)
        
        do {
            try viewContext.execute(deleteRequest1)
            try viewContext.execute(deleteRequest2)
            try viewContext.save()
        } catch {
            // Silent failure - user can retry
        }
    }
}

#Preview {
    SettingsView()
        .environment(\.managedObjectContext, CoreDataStack.shared.viewContext)
}
