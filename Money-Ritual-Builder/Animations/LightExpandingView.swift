import SwiftUI

struct LightExpandingView: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.8
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            RitualTheme.warmGold.opacity(opacity),
                            RitualTheme.warmGold.opacity(opacity * 0.5),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .scaleEffect(scale)
                .blur(radius: 20)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.5)) {
                scale = 2.0
                opacity = 0
            }
        }
    }
}

#Preview {
    ZStack {
        RitualTheme.warmIvoryLight
            .ignoresSafeArea()
        LightExpandingView()
    }
}
