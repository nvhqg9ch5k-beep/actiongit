import SwiftUI

struct RitualTheme {
    // Color Palette - адаптивные цвета
    static let deepAmber = Color(hex: "8B4513")
    static let sageGreen = Color(hex: "8A9A5B")
    static let warmGold = Color(hex: "D4A017")
    
    // Адаптивные цвета для светлой/темной темы
    static func charcoal(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "E5E5E5") : Color(hex: "2F2F2F")
    }
    
    static func warmIvory(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "1C1C1C") : Color(hex: "FDF6E3")
    }
    
    static func parchment(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "2A2A2A") : Color(hex: "F5E6D3")
    }
    
    // Для обратной совместимости (используют светлую тему по умолчанию)
    static let charcoalLight = Color(hex: "2F2F2F")
    static let warmIvoryLight = Color(hex: "FDF6E3")
    static let parchmentLight = Color(hex: "F5E6D3")
    
    // Typography
    static let ritualTitleFont = Font.custom("Georgia", size: 28).weight(.medium)
    static let ritualNameFont = Font.custom("Georgia", size: 22).weight(.regular)
    static let bodyFont = Font.system(.body, design: .default)
    static let captionFont = Font.system(.caption, design: .default)
    
    // Spacing
    static let cornerRadius: CGFloat = 32
    static let largeCornerRadius: CGFloat = 44
    static let padding: CGFloat = 24
    static let largePadding: CGFloat = 40
    
    // Shadows
    static let softShadow = Shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    static let glowShadow = Shadow(color: warmGold.opacity(0.3), radius: 16, x: 0, y: 0)
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}
