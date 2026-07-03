import SwiftUI

private struct DirtSpot: Identifiable {
    let id = UUID()
    var offset: CGSize
    var amount: Double
}

private struct FoamBlob: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
}

struct MudSplatShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX * 0.8, y: rect.maxY * 0.4), control: CGPoint(x: rect.maxX, y: rect.minY * 0.3))
        p.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY), control: CGPoint(x: rect.maxX * 0.9, y: rect.maxY * 0.9))
        p.addQuadCurve(to: CGPoint(x: rect.minX * 0.2, y: rect.maxY * 0.5), control: CGPoint(x: rect.minX * 0.1, y: rect.maxY * 0.8))
        p.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY), control: CGPoint(x: rect.minX * 0.2, y: rect.minY * 0.2))
        p.closeSubpath()
        return p
    }
}

struct BathView: View {
    @EnvironmentObject var vm: GameViewModel
    let onClose: () -> Void

    private enum BathPhase {
        case dirty     // esfregando
        case rinsing   // chuveirinho enxaguando
        case clean     // terminou!
    }

    @StateObject private var particles = ParticleSystem()
    @State private var phase: BathPhase = .dirty
    @State private var spots: [DirtSpot] = [
        DirtSpot(offset: CGSize(width: -42, height: -6), amount: 1),
        DirtSpot(offset: CGSize(width: 34, height: -48), amount: 1),
        DirtSpot(offset: CGSize(width: -4, height: 24), amount: 1),
        DirtSpot(offset: CGSize(width: 46, height: 10), amount: 1),
        DirtSpot(offset: CGSize(width: -26, height: 42), amount: 1),
    ]
    @State private var foam: [FoamBlob] = []
    @State private var spongePos: CGPoint?
    @State private var scrubTick = 0
    @State private var shakeAngle: Double = 0
    @State private var petPose: PetPose = .sit

    private var allClean: Bool {
        spots.allSatisfy { $0.amount <= 0.05 }
    }

    var body: some View {
        GeometryReader { geo in
            let petCenter = CGPoint(x: geo.size.width * 0.5, y: geo.size.height * 0.47)

            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.72, green: 0.90, blue: 1.0), Color(red: 0.50, green: 0.78, blue: 0.95)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // Banheira de Cerâmica com Pés Dourados/Cinzas
                ZStack {
                    // Pés da banheira (claw-feet)
                    Capsule()
                        .fill(Color(red: 0.75, green: 0.75, blue: 0.78))
                        .frame(width: 14, height: 26)
                        .position(x: petCenter.x - geo.size.width * 0.21, y: geo.size.height * 0.82)
                    Capsule()
                        .fill(Color(red: 0.75, green: 0.75, blue: 0.78))
                        .frame(width: 14, height: 26)
                        .position(x: petCenter.x + geo.size.width * 0.21, y: geo.size.height * 0.82)

                    // Corpo externo da banheira
                    RoundedRectangle(cornerRadius: 40)
                        .fill(
                            LinearGradient(
                                colors: [.white, Color(red: 0.93, green: 0.95, blue: 0.98)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: geo.size.width * 0.56, height: 110)
                        .shadow(color: .black.opacity(0.15), radius: 8, y: 5)
                        .position(x: petCenter.x, y: geo.size.height * 0.755)
                    
                    // Borda superior da banheira (Highlight)
                    RoundedRectangle(cornerRadius: 40)
                        .stroke(Color(red: 0.88, green: 0.90, blue: 0.94), lineWidth: 4)
                        .frame(width: geo.size.width * 0.56, height: 110)
                        .position(x: petCenter.x, y: geo.size.height * 0.755)

                    // Água interna da banheira com transparência e gradiente
                    RoundedRectangle(cornerRadius: 32)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.55, green: 0.85, blue: 1.0).opacity(0.75), Color(red: 0.35, green: 0.68, blue: 0.90).opacity(0.85)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: geo.size.width * 0.51, height: 80)
                        .position(x: petCenter.x, y: geo.size.height * 0.76)

                    // Torneira de metal brilhante
                    ZStack {
                        // Cano curvado
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: 35))
                            path.addLine(to: CGPoint(x: 0, y: 10))
                            path.addQuadCurve(to: CGPoint(x: -20, y: 0), control: CGPoint(x: 0, y: 0))
                        }
                        .stroke(
                            LinearGradient(colors: [Color(red: 0.8, green: 0.8, blue: 0.82), Color(red: 0.6, green: 0.6, blue: 0.63)], startPoint: .top, endPoint: .bottom),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 30, height: 35)
                        
                        // Manípulos de água quente/fria
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8)
                            .offset(x: -8, y: 22)
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8)
                            .offset(x: 8, y: 22)
                    }
                    .position(x: petCenter.x + geo.size.width * 0.25, y: geo.size.height * 0.68)
                }
                
                Text("🫧")
                    .font(.system(size: 30))
                    .position(x: petCenter.x - geo.size.width * 0.2, y: geo.size.height * 0.71)
                Text("🦆")
                    .font(.system(size: 34))
                    .position(x: petCenter.x + geo.size.width * 0.17, y: geo.size.height * 0.70)

                if let pet = vm.pet {
                    PetCharacterView(species: pet.species, pose: petPose, size: 150, mood: pet.mood)
                        .rotationEffect(.degrees(shakeAngle))
                        .position(petCenter)
                }

                // sujeirinhas orgânicas
                ForEach(spots) { spot in
                    MudSplatShape()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.45, green: 0.30, blue: 0.15), Color(red: 0.35, green: 0.22, blue: 0.12)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .opacity(0.8 * spot.amount)
                        .frame(width: 32, height: 26)
                        .blur(radius: 1.5)
                        .position(
                            x: petCenter.x + spot.offset.width,
                            y: petCenter.y + spot.offset.height
                        )
                }

                // espuma acumulando (bolhas brilhantes)
                ForEach(foam) { blob in
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [.white, Color(red: 0.88, green: 0.95, blue: 1.0).opacity(0.85)],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: blob.size / 2
                                )
                            )
                        Circle()
                            .stroke(Color.white.opacity(0.55), lineWidth: 1)
                        // Brilho da bolha
                        Circle()
                            .fill(.white.opacity(0.6))
                            .frame(width: blob.size * 0.22, height: blob.size * 0.22)
                            .offset(x: -blob.size * 0.22, y: -blob.size * 0.22)
                    }
                    .frame(width: blob.size, height: blob.size)
                    .position(blob.position)
                }
                .opacity(phase == .dirty ? 1 : 0)
                .animation(.easeOut(duration: 0.8), value: phase == .dirty)

                // camada que captura o dedo esfregando
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                guard phase == .dirty else { return }
                                spongePos = value.location
                                scrub(at: value.location, petCenter: petCenter)
                            }
                            .onEnded { _ in
                                spongePos = nil
                            }
                    )

                if let pos = spongePos, phase == .dirty {
                    Text("🧽")
                        .font(.system(size: 48))
                        .position(pos)
                        .allowsHitTesting(false)
                }

                if phase == .rinsing {
                    RainView()
                    Text("🚿")
                        .font(.system(size: 52))
                        .position(x: petCenter.x, y: geo.size.height * 0.12)
                }

                ParticleField(system: particles)

                VStack {
                    ActivityHeader(title: "Hora do banho! 🛁", onClose: onClose)
                    Text(statusText)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 0.15, green: 0.35, blue: 0.55))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(.white.opacity(0.8)))
                    Spacer()
                }
            }
        }
    }

    private var statusText: String {
        switch phase {
        case .dirty: return "Esfregue as sujeirinhas com o dedo! 🧽"
        case .rinsing: return "Enxaguando... 🚿"
        case .clean: return "Todo limpinho! ✨"
        }
    }

    private func scrub(at point: CGPoint, petCenter: CGPoint) {
        var cleanedAny = false
        for index in spots.indices {
            let spotPoint = CGPoint(
                x: petCenter.x + spots[index].offset.width,
                y: petCenter.y + spots[index].offset.height
            )
            let dx = point.x - spotPoint.x
            let dy = point.y - spotPoint.y
            if (dx * dx + dy * dy).squareRoot() < 46 && spots[index].amount > 0 {
                spots[index].amount = max(0, spots[index].amount - 0.04)
                cleanedAny = true
            }
        }

        scrubTick += 1
        if cleanedAny && scrubTick.isMultiple(of: 3) && foam.count < 36 {
            foam.append(
                FoamBlob(
                    position: CGPoint(
                        x: point.x + CGFloat.random(in: -16...16),
                        y: point.y + CGFloat.random(in: -14...14)
                    ),
                    size: CGFloat.random(in: 13...24)
                )
            )
        }
        if cleanedAny && scrubTick.isMultiple(of: 8) {
            AudioManager.shared.play(.splash)
            particles.burst(["🫧"], at: point, count: 2)
        }

        if allClean && phase == .dirty {
            startRinse(petCenter: petCenter)
        }
    }

    /// Sujeira acabou: chuveirinho, sacodida e brilhos.
    private func startRinse(petCenter: CGPoint) {
        phase = .rinsing
        Haptics.success()
        AudioManager.shared.play(.splash)
        vm.bathe()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
            phase = .clean
            foam.removeAll()

            // pet se sacode como cachorrinho molhado
            withAnimation(.linear(duration: 0.07).repeatCount(8, autoreverses: true)) {
                shakeAngle = 9
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.linear(duration: 0.1)) { shakeAngle = 0 }
                petPose = .happy
                AudioManager.shared.play(.chime)
                particles.burst(["✨", "🫧", "💖"], at: petCenter, count: 14)
            }
        }
    }
}

/// Gotinhas de chuveiro caindo.
private struct RainView: View {
    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            GeometryReader { geo in
                ForEach(0..<14, id: \.self) { index in
                    let seed = Double(index) * 0.37
                    let x = geo.size.width * (0.2 + 0.6 * seed.truncatingRemainder(dividingBy: 1))
                    let fall = (t * 1.6 + seed * 3).truncatingRemainder(dividingBy: 1)
                    Capsule()
                        .fill(Color(red: 0.55, green: 0.8, blue: 1.0).opacity(0.8))
                        .frame(width: 5, height: 16)
                        .position(x: x, y: geo.size.height * (0.15 + 0.65 * fall))
                }
            }
        }
        .allowsHitTesting(false)
    }
}
