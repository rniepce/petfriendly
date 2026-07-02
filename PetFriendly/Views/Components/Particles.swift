import SwiftUI

struct Particle: Identifiable {
    let id = UUID()
    var emoji: String
    var x: CGFloat
    var y: CGFloat
    var drift: CGFloat
    var scale: CGFloat
}

/// Emissor simples de partículas de emoji (corações, bolhas, estrelas...).
@MainActor
final class ParticleSystem: ObservableObject {
    @Published var particles: [Particle] = []

    func burst(_ emojis: [String], at point: CGPoint, count: Int = 6) {
        var newOnes: [Particle] = []
        for _ in 0..<count {
            let particle = Particle(
                emoji: emojis.randomElement() ?? "✨",
                x: point.x + CGFloat.random(in: -34...34),
                y: point.y + CGFloat.random(in: -24...24),
                drift: CGFloat.random(in: -44...44),
                scale: CGFloat.random(in: 0.7...1.3)
            )
            newOnes.append(particle)
        }
        particles.append(contentsOf: newOnes)

        let ids = Set(newOnes.map(\.id))
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.particles.removeAll { ids.contains($0.id) }
        }
    }
}

struct ParticleView: View {
    let particle: Particle
    @State private var animate = false

    var body: some View {
        Text(particle.emoji)
            .font(.system(size: 28 * particle.scale))
            .position(
                x: particle.x + (animate ? particle.drift : 0),
                y: particle.y - (animate ? 90 : 0)
            )
            .opacity(animate ? 0 : 1)
            .onAppear {
                withAnimation(.easeOut(duration: 1.2)) { animate = true }
            }
    }
}

/// Camada transparente que desenha as partículas por cima da cena.
struct ParticleField: View {
    @ObservedObject var system: ParticleSystem

    var body: some View {
        ZStack {
            ForEach(system.particles) { particle in
                ParticleView(particle: particle)
            }
        }
        .allowsHitTesting(false)
    }
}
