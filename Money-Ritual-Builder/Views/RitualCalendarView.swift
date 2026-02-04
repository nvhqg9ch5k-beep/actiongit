import SwiftUI
import CoreData

struct RitualCalendarView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MoneyRitual.createdAt, ascending: false)],
        predicate: NSPredicate(format: "isArchived == NO"),
        animation: .default
    ) private var rituals: FetchedResults<MoneyRitual>
    
    @State private var selectedDate: Date = Date()
    @State private var currentMonth: Date = Date()
    
    var body: some View {
        NavigationStack {
            ZStack {
                RitualTheme.warmIvory(colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Month selector
                    HStack {
                        Button(action: {
                            withAnimation {
                                currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme))
                        }
                        
                        Spacer()
                        
                        Text(currentMonth, format: .dateTime.month(.wide).year())
                            .font(RitualTheme.ritualNameFont)
                            .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme))
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation {
                                currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                            }
                        }) {
                            Image(systemName: "chevron.right")
                                .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme))
                        }
                    }
                    .padding(RitualTheme.padding)
                    
                    // Calendar grid
                    CalendarGridView(
                        month: currentMonth,
                        rituals: Array(rituals),
                        selectedDate: $selectedDate
                    )
                    .padding(.horizontal, RitualTheme.padding)
                    
                    // Selected date info
                    if let completions = getCompletions(for: selectedDate), !completions.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(selectedDate, format: .dateTime.month(.wide).day().year())
                                .font(RitualTheme.ritualNameFont)
                                .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme))
                            
                            ForEach(completions, id: \.id) { completion in
                                if let ritual = completion.ritual {
                                    HStack(spacing: 12) {
                                        Circle()
                                            .fill(RitualTheme.warmGold)
                                            .frame(width: 12, height: 12)
                                        
                                        Text(ritual.name ?? "Unnamed Ritual")
                                            .font(RitualTheme.bodyFont)
                                            .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme))
                                        
                                        Spacer()
                                    }
                                }
                            }
                        }
                        .padding(RitualTheme.padding)
                        .background(RitualTheme.parchment(colorScheme: colorScheme))
                        .cornerRadius(RitualTheme.cornerRadius)
                        .padding(.horizontal, RitualTheme.padding)
                        .padding(.top, 20)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Ritual Calendar")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func getCompletions(for date: Date) -> [RitualCompletion]? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        
        var allCompletions: [RitualCompletion] = []
        for ritual in rituals {
            if let completions = ritual.completions as? Set<RitualCompletion> {
                let dayCompletions = completions.filter { completion in
                    guard let completionDate = completion.date else { return false }
                    return completionDate >= startOfDay && completionDate < endOfDay && completion.completed
                }
                allCompletions.append(contentsOf: dayCompletions)
            }
        }
        return allCompletions.isEmpty ? nil : allCompletions
    }
}

struct CalendarGridView: View {
    @Environment(\.colorScheme) private var colorScheme
    let month: Date
    let rituals: [MoneyRitual]
    @Binding var selectedDate: Date
    
    private let calendar = Calendar.current
    private let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    var daysInMonth: [Date?] {
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) ?? month
        let range = calendar.range(of: .day, in: .month, for: startOfMonth) ?? 1..<32
        let firstWeekday = calendar.component(.weekday, from: startOfMonth) - 1
        
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }
        return days
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Weekday headers
            HStack(spacing: 0) {
                ForEach(weekdays, id: \.self) { weekday in
                    Text(weekday)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(RitualTheme.charcoal(colorScheme: colorScheme).opacity(0.6))
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar grid
            let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(0..<daysInMonth.count, id: \.self) { index in
                    if let date = daysInMonth[index] {
                        CalendarDayView(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isCompleted: hasCompletion(for: date),
                            onTap: {
                                selectedDate = date
                            }
                        )
                    } else {
                        Color.clear
                            .frame(height: 44)
                    }
                }
            }
        }
    }
    
    private func hasCompletion(for date: Date) -> Bool {
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        
        return rituals.contains { ritual in
            guard let completions = ritual.completions as? Set<RitualCompletion> else { return false }
            return completions.contains { completion in
                guard let completionDate = completion.date else { return false }
                return completionDate >= startOfDay && completionDate < endOfDay && completion.completed
            }
        }
    }
}

struct CalendarDayView: View {
    @Environment(\.colorScheme) private var colorScheme
    let date: Date
    let isSelected: Bool
    let isCompleted: Bool
    let onTap: () -> Void
    
    private var dayNumber: Int {
        Calendar.current.component(.day, from: date)
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(isSelected ? RitualTheme.deepAmber : (isCompleted ? RitualTheme.warmGold.opacity(0.3) : Color.clear))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(isCompleted ? RitualTheme.warmGold : Color.clear, lineWidth: 2)
                    )
                    .shadow(color: isCompleted ? RitualTheme.warmGold.opacity(0.4) : Color.clear, radius: 4)
                
                Text("\(dayNumber)")
                    .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? RitualTheme.warmIvory(colorScheme: colorScheme) : RitualTheme.charcoal(colorScheme: colorScheme))
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    RitualCalendarView()
        .environment(\.managedObjectContext, CoreDataStack.shared.viewContext)
}
