import Foundation
import CoreData

extension MoneyRitual {
    var stepsArray: [String] {
        get {
            guard let stepsString = steps,
                  let data = stepsString.data(using: .utf8),
                  let array = try? JSONDecoder().decode([String].self, from: data) else {
                return []
            }
            return array
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let string = String(data: data, encoding: .utf8) {
                steps = string
            } else {
                steps = "[]"
            }
        }
    }
}
