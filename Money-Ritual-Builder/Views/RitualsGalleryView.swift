import SwiftUI
import CoreData
import UIKit

struct RitualsGalleryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MoneyRitual.createdAt, ascending: false)],
        predicate: NSPredicate(format: "isArchived == NO"),
        animation: .default
    ) private var rituals: FetchedResults<MoneyRitual>
    
    @State private var sortOption: SortOption = .strength
    
    enum SortOption: String, CaseIterable {
        case strength = "Strength"
        case frequency = "Frequency"
        case date = "Creation Date"
    }
    
    var sortedRituals: [MoneyRitual] {
        let array = Array(rituals)
        switch sortOption {
        case .strength:
            return array.sorted { RitualCalculations.calculateConsistency(for: $0) > RitualCalculations.calculateConsistency(for: $1) }
        case .frequency:
            return array.sorted { ($0.frequency ?? "") < ($1.frequency ?? "") }
        case .date:
            return array.sorted { ($0.createdAt ?? Date()) > ($1.createdAt ?? Date()) }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                RitualTheme.warmIvory(colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Sort picker
                    Picker("Sort by", selection: $sortOption) {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(RitualTheme.padding)
                    
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 16) {
                            ForEach(sortedRituals) { ritual in
                                NavigationLink(destination: RitualDetailView(ritual: ritual)) {
                                    RitualGalleryCard(ritual: ritual)
                                }
                            }
                        }
                        .padding(RitualTheme.padding)
                    }
                }
            }
            .navigationTitle("Rituals Gallery")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct RitualGalleryCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let ritual: MoneyRitual
    
    var consistency: Int {
        RitualCalculations.calculateConsistency(for: ritual)
    }
    
    var streak: Int {
        RitualCalculations.calculateStreak(for: ritual)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Icon
            if let photoData = ritual.symbolPhotoData,
               let image = UIImage(data: photoData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .cornerRadius(20)
            } else if let iconName = ritual.symbolIcon {
                Image(systemName: iconName)
                    .font(.system(size: 40))
                    .foregroundColor(RitualTheme.deepAmber)
                    .frame(width: 80, height: 80)
                    .background(RitualTheme.parchment(colorScheme: colorScheme))
                    .cornerRadius(20)
            }
            
            // Name
            Text(ritual.name ?? "Unnamed")
                .font(RitualTheme.ritualNameFont)
                .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme))
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // Streak
            if streak > 0 {
                HStack(spacing: 4) {
                    CandleFlameView(size: 14, isAnimated: true)
                    Text("\(streak)")
                        .font(.system(size: 12))
                        .foregroundColor(RitualTheme.deepAmber)
                }
            }
            
            // Consistency
            VStack(spacing: 4) {
                Text("\(consistency)%")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme))
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(RitualTheme.charcoal(colorScheme: colorScheme).opacity(0.1))
                            .frame(height: 4)
                            .cornerRadius(2)
                        
                        Rectangle()
                            .fill(RitualTheme.warmGold)
                            .frame(width: geometry.size.width * CGFloat(consistency) / 100, height: 4)
                            .cornerRadius(2)
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(RitualTheme.padding)
        .frame(maxWidth: .infinity)
        .background(RitualTheme.parchment(colorScheme: colorScheme))
        .cornerRadius(RitualTheme.cornerRadius)
    }
}

#Preview {
    RitualsGalleryView()
        .environment(\.managedObjectContext, CoreDataStack.shared.viewContext)
}
