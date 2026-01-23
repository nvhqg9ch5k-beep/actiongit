import SwiftUI

struct CandleFlameView: View {
    @State private var flicker: CGFloat = 0
    @State private var glow: CGFloat = 1.0
    let size: CGFloat
    let isAnimated: Bool
    
    init(size: CGFloat = 60, isAnimated: Bool = true) {
        self.size = size
        self.isAnimated = isAnimated
    }
    
    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            RitualTheme.warmGold.opacity(0.4 * glow),
                            RitualTheme.warmGold.opacity(0.1 * glow),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: size * 0.3,
                        endRadius: size * 0.8
                    )
                )
                .frame(width: size * 1.6, height: size * 1.6)
                .blur(radius: 8)
            
            // Flame shape
            FlameShape(flicker: flicker)
                .fill(
                    LinearGradient(
                        colors: [
                            RitualTheme.warmGold,
                            RitualTheme.deepAmber.opacity(0.8),
                            RitualTheme.deepAmber.opacity(0.4)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.6, height: size)
                .shadow(color: RitualTheme.warmGold.opacity(0.5), radius: 4, x: 0, y: 0)
        }
        .onAppear {
            if isAnimated {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    flicker = 1.0
                }
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    glow = 1.3
                }
            }
        }
    }
}

struct FlameShape: Shape {
    var flicker: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        let flickerOffset = sin(flicker * .pi * 2) * width * 0.05
        
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addCurve(
            to: CGPoint(x: rect.midX - width * 0.3 + flickerOffset, y: height * 0.3),
            control1: CGPoint(x: rect.midX - width * 0.2, y: height * 0.7),
            control2: CGPoint(x: rect.midX - width * 0.25, y: height * 0.5)
        )
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.minY),
            control1: CGPoint(x: rect.midX - width * 0.15, y: height * 0.1),
            control2: CGPoint(x: rect.midX - width * 0.05, y: height * 0.05)
        )
        path.addCurve(
            to: CGPoint(x: rect.midX + width * 0.3 - flickerOffset, y: height * 0.3),
            control1: CGPoint(x: rect.midX + width * 0.05, y: height * 0.05),
            control2: CGPoint(x: rect.midX + width * 0.15, y: height * 0.1)
        )
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY),
            control1: CGPoint(x: rect.midX + width * 0.25, y: height * 0.5),
            control2: CGPoint(x: rect.midX + width * 0.2, y: height * 0.7)
        )
        path.closeSubpath()
        
        return path
    }
}

#Preview {
    ZStack {
        RitualTheme.warmIvoryLight
            .ignoresSafeArea()
        CandleFlameView(size: 80)
    }
}
