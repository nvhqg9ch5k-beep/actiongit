import Foundation
import CoreData

struct RitualCalculations {
    // Cache for consistency calculations
    private static var consistencyCache: [UUID: (value: Int, timestamp: Date)] = [:]
    private static let cacheTimeout: TimeInterval = 60 // 1 minute
    
    // Cache for streak calculations
    private static var streakCache: [UUID: (value: Int, timestamp: Date)] = [:]
    
    static func calculateConsistency(for ritual: MoneyRitual) -> Int {
        guard let ritualId = ritual.id else { return 0 }
        
        // Check cache
        if let cached = consistencyCache[ritualId],
           Date().timeIntervalSince(cached.timestamp) < cacheTimeout {
            return cached.value
        }
        
        guard let completions = ritual.completions as? Set<RitualCompletion> else {
            consistencyCache[ritualId] = (0, Date())
            return 0
        }
        
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        let last30Days = completions.filter { completion in
            guard let date = completion.date,
                  completion.completed,
                  date >= thirtyDaysAgo else { return false }
            return true
        }
        
        let consistency = min(100, Int((Double(last30Days.count) / 30.0) * 100))
        consistencyCache[ritualId] = (consistency, Date())
        return consistency
    }
    
    static func calculateStreak(for ritual: MoneyRitual) -> Int {
        guard let ritualId = ritual.id else { return 0 }
        
        // Check cache
        if let cached = streakCache[ritualId],
           Date().timeIntervalSince(cached.timestamp) < cacheTimeout {
            return cached.value
        }
        
        guard let completions = ritual.completions as? Set<RitualCompletion> else {
            streakCache[ritualId] = (0, Date())
            return 0
        }
        
        let calendar = Calendar.current
        let sortedCompletions = completions
            .filter { $0.completed }
            .compactMap { $0.date }
            .sorted(by: >)
        
        guard !sortedCompletions.isEmpty else {
            streakCache[ritualId] = (0, Date())
            return 0
        }
        
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        for completionDate in sortedCompletions {
            let completionDay = calendar.startOfDay(for: completionDate)
            let daysDifference = calendar.dateComponents([.day], from: completionDay, to: currentDate).day ?? 0
            
            if daysDifference == 0 || daysDifference == 1 {
                streak += 1
                if daysDifference == 1 {
                    currentDate = completionDay
                }
            } else {
                break
            }
        }
        
        streakCache[ritualId] = (streak, Date())
        return streak
    }
    
    static func invalidateCache(for ritualId: UUID?) {
        guard let ritualId = ritualId else { return }
        consistencyCache.removeValue(forKey: ritualId)
        streakCache.removeValue(forKey: ritualId)
    }
    
    static func clearAllCache() {
        consistencyCache.removeAll()
        streakCache.removeAll()
    }
}
