import SwiftUI
import CoreData

@main
struct Money_Ritual_BuilderApp: App {
    @StateObject private var coreDataStack = CoreDataStack.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("theme") private var theme: String = "system"

    var colorScheme: ColorScheme? {
        switch theme {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil
        }
    }
    
    init() {
        // Preload Core Data stack
        _ = CoreDataStack.shared.persistentContainer
        
        // Request notification authorization
        Task {
            _ = await ReminderManager.shared.requestAuthorization()
        }
    }
    
    var body: some Scene {
        return WindowGroup {
            ContentRouterView(
                hasCompletedOnboarding: $hasCompletedOnboarding
            )
            .preferredColorScheme(colorScheme)
            .animation(.easeInOut, value: hasCompletedOnboarding)
            .environment(\.managedObjectContext, coreDataStack.viewContext)
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            MainDashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
                .tag(0)
            
            RitualCalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
                .tag(1)
            
            RitualsGalleryView()
                .tabItem {
                    Label("Gallery", systemImage: "square.grid.2x2.fill")
                }
                .tag(2)
            
            RitualStrengthInsightsView()
                .tabItem {
                    Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(3)
            
            ReflectionEvolutionView()
                .tabItem {
                    Label("Reflection", systemImage: "book.fill")
                }
                .tag(4)
        }
        .tint(RitualTheme.deepAmber)
    }
}

