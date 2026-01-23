import SwiftUI

struct SplashScreenView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var candleScale: CGFloat = 0.3
    @State private var candleOpacity: Double = 0
    @State private var objectsOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var showObjects: Bool = false
    @Binding var isComplete: Bool
    
    // Use a timer to force update
    @State private var animationComplete = false
    
    var body: some View {
        ZStack {
            RitualTheme.deepAmber
                .ignoresSafeArea()
            
            VStack(spacing: 60) {
                Spacer()
                
                // Candle flame
                CandleFlameView(size: 100, isAnimated: true)
                    .scaleEffect(candleScale)
                    .opacity(candleOpacity)
                
                // Ritual objects circle
                if showObjects {
                    ZStack {
                        ForEach(0..<8) { index in
                            Circle()
                                .fill(RitualTheme.warmGold.opacity(0.6))
                                .frame(width: 12, height: 12)
                                .offset(
                                    x: cos(Double(index) * 2 * .pi / 8) * 80,
                                    y: sin(Double(index) * 2 * .pi / 8) * 80
                                )
                        }
                    }
                    .opacity(objectsOpacity)
                }
                
                // App name
                Text("Money Ritual Builder")
                    .font(RitualTheme.ritualTitleFont)
                    .foregroundColor(RitualTheme.warmIvory(colorScheme: colorScheme))
                    .opacity(titleOpacity)
                
                Spacer()
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Candle appears
        withAnimation(.easeOut(duration: 1.0)) {
            candleOpacity = 1.0
            candleScale = 1.0
        }
        
        // Objects light up
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showObjects = true
            withAnimation(.easeOut(duration: 1.5)) {
                objectsOpacity = 1.0
            }
        }
        
        // Title appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation(.easeIn(duration: 1.0)) {
                titleOpacity = 1.0
            }
        }
        
        // Complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.5) {
            self.animationComplete = true
            DispatchQueue.main.async {
                self.isComplete = true
            }
        }
    }
}

#Preview {
    SplashScreenView(isComplete: .constant(false))
}
