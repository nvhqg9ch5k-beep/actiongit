import SwiftUI

struct ParticleEffectView: View {
    @State private var particles: [Particle] = []
    let count: Int
    let color: Color
    
    init(count: Int = 20, color: Color = RitualTheme.warmGold) {
        self.count = count
        self.color = color
    }
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(color.opacity(particle.opacity))
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
            }
        }
        .onAppear {
            generateParticles()
            animateParticles()
        }
    }
    
    private func generateParticles() {
        particles = (0..<count).map { _ in
            Particle(
                position: CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2),
                size: CGFloat.random(in: 4...8),
                opacity: Double.random(in: 0.6...1.0)
            )
        }
    }
    
    private func animateParticles() {
        withAnimation(.easeOut(duration: 2.0)) {
            for index in particles.indices {
                let angle = Double.random(in: 0...(2 * .pi))
                let distance = CGFloat.random(in: 50...150)
                particles[index].position = CGPoint(
                    x: UIScreen.main.bounds.width / 2 + cos(angle) * distance,
                    y: UIScreen.main.bounds.height / 2 + sin(angle) * distance
                )
                particles[index].opacity = 0
            }
        }
    }
}

struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    var opacity: Double
}
