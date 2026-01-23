import SwiftUI
import CoreData

struct RitualStrengthInsightsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MoneyRitual.createdAt, ascending: false)],
        predicate: NSPredicate(format: "isArchived == NO"),
        animation: .default
    ) private var rituals: FetchedResults<MoneyRitual>
    
    var body: some View {
        NavigationStack {
            ZStack {
                RitualTheme.warmIvory(colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: RitualTheme.padding) {
                        // Overall consistency chart
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Overall Consistency")
                                .font(RitualTheme.ritualTitleFont)
                                .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme))
                            
                            ConsistencyLineChart(rituals: Array(rituals))
                                .frame(height: 200)
                        }
                        .padding(RitualTheme.padding)
                        .background(RitualTheme.parchment(colorScheme: colorScheme))
                        .cornerRadius(RitualTheme.cornerRadius)
                        .padding(.horizontal, RitualTheme.padding)
                        .padding(.top, 20)
                        
                        // Insights
                        VStack(alignment: .leading, spacing: 24) {
                            if let strongest = strongestRitual {
                                InsightCard(
                                    title: "Strongest Ritual",
                                    value: strongest.name ?? "Unnamed",
                                    icon: "flame.fill"
                                )
                            }
                            
                            if let month = mostConsistentMonth {
                                InsightCard(
                                    title: "Most Consistent Month",
                                    value: month,
                                    icon: "calendar"
                                )
                            }
                        }
                        .padding(.horizontal, RitualTheme.padding)
                        
                        // Progress per ritual
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Ritual Progress")
                                .font(RitualTheme.ritualTitleFont)
                                .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme))
                            
                            ForEach(Array(rituals)) { ritual in
                                RitualProgressBar(ritual: ritual)
                            }
                        }
                        .padding(RitualTheme.padding)
                        .background(RitualTheme.parchment(colorScheme: colorScheme))
                        .cornerRadius(RitualTheme.cornerRadius)
                        .padding(.horizontal, RitualTheme.padding)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var strongestRitual: MoneyRitual? {
        rituals.max { RitualCalculations.calculateConsistency(for: $0) < RitualCalculations.calculateConsistency(for: $1) }
    }
    
    private var mostConsistentMonth: String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        
        var monthStats: [String: Int] = [:]
        
        for ritual in rituals {
            guard let completions = ritual.completions as? Set<RitualCompletion> else { continue }
            for completion in completions where completion.completed {
                guard let date = completion.date else { continue }
                let monthKey = formatter.string(from: date)
                monthStats[monthKey, default: 0] += 1
            }
        }
        
        return monthStats.max(by: { $0.value < $1.value })?.key
    }
}

struct ConsistencyLineChart: View {
    @Environment(\.colorScheme) private var colorScheme
    let rituals: [MoneyRitual]
    
    var monthlyData: [(month: String, value: Int)] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        
        var data: [String: Int] = [:]
        
        for ritual in rituals {
            guard let completions = ritual.completions as? Set<RitualCompletion> else { continue }
            for completion in completions where completion.completed {
                guard let date = completion.date else { continue }
                let monthKey = formatter.string(from: date)
                data[monthKey, default: 0] += 1
            }
        }
        
        let last6Months = (0..<6).compactMap { offset -> (String, Int)? in
            guard let date = calendar.date(byAdding: .month, value: -offset, to: Date()) else { return nil }
            let key = formatter.string(from: date)
            return (key, data[key] ?? 0)
        }
        
        return last6Months.reversed()
    }
    
    var body: some View {
        GeometryReader { geometry in
            let maxValue = monthlyData.map { $0.value }.max() ?? 1
            let step = geometry.size.height / CGFloat(max(maxValue, 1))
            
            ZStack(alignment: .bottomLeading) {
                // Grid lines
                ForEach(0..<5) { i in
                    let y = geometry.size.height * CGFloat(i) / 4
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                    }
                    .stroke(RitualTheme.charcoal(colorScheme: colorScheme).opacity(0.1), lineWidth: 1)
                }
                
                // Line
                Path { path in
                    for (index, data) in monthlyData.enumerated() {
                        let x = geometry.size.width * CGFloat(index) / CGFloat(max(monthlyData.count - 1, 1))
                        let y = geometry.size.height - CGFloat(data.value) * step
                        
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(RitualTheme.deepAmber, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                
                // Points
                ForEach(Array(monthlyData.enumerated()), id: \.offset) { index, data in
                    let x = geometry.size.width * CGFloat(index) / CGFloat(max(monthlyData.count - 1, 1))
                    let y = geometry.size.height - CGFloat(data.value) * step
                    
                    Circle()
                        .fill(RitualTheme.warmGold)
                        .frame(width: 8, height: 8)
                        .position(x: x, y: y)
                }
            }
        }
        .overlay(alignment: .bottom) {
            HStack {
                ForEach(monthlyData, id: \.month) { data in
                    Text(data.month)
                        .font(.system(size: 10))
                        .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme).opacity(0.6))
                        .frame(maxWidth: .infinity)
                }
            }
            .offset(y: 20)
        }
    }
}

struct InsightCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(RitualTheme.deepAmber)
                .frame(width: 60, height: 60)
                .background(RitualTheme.parchment(colorScheme: colorScheme))
                .cornerRadius(16)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(RitualTheme.captionFont)
                    .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme).opacity(0.6))
                
                Text(value)
                    .font(RitualTheme.ritualNameFont)
                    .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme))
            }
            
            Spacer()
        }
        .padding(RitualTheme.padding)
        .background(RitualTheme.parchment(colorScheme: colorScheme))
        .cornerRadius(RitualTheme.cornerRadius)
    }
}

struct RitualProgressBar: View {
    @Environment(\.colorScheme) private var colorScheme
    let ritual: MoneyRitual
    
    var consistency: Int {
        RitualCalculations.calculateConsistency(for: ritual)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(ritual.name ?? "Unnamed")
                    .font(RitualTheme.bodyFont)
                    .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme))
                
                Spacer()
                
                Text("\(consistency)%")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme))
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(RitualTheme.charcoal(colorScheme: colorScheme).opacity(0.1))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(RitualTheme.warmGold)
                        .frame(width: geometry.size.width * CGFloat(consistency) / 100, height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
        }
    }
}

#Preview {
    RitualStrengthInsightsView()
        .environment(\.managedObjectContext, CoreDataStack.shared.viewContext)
}
