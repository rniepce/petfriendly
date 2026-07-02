import SwiftUI

struct PlayView: View {
    @EnvironmentObject var vm: GameViewModel
    let onClose: () -> Void

    private enum PlayPhase {
        case ready      // bola com a criança
        case chasing    // pet correndo atrás
        case returning  // pet trazendo a bola de volta
    }

    @StateObject private var particles = ParticleSystem()
    @State private var phase: PlayPhase = .ready
    @State private var ballPos: CGPoint = .zero
    @State private var petPos: CGPoint = .zero
    @State private var facing: CGFloat = 1
    @State private var pose: PetPose = .sit
    @State private var ready = false
    @State private var catches = 0

    var body: some View {
        GeometryReader { geo in
            let homeSpot = CGPoint(x: geo.size.width * 0.25, y: geo.size.height * 0.60)

            ZStack {
                // céu e grama do quintal
                LinearGradient(
                    colors: [Color(red: 0.55, green: 0.82, blue: 1.0), Color(red: 0.80, green: 0.94, blue: 1.0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                VStack(spacing: 0) {
                    Spacer()
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.55, green: 0.85, blue: 0.45), Color(red: 0.40, green: 0.72, blue: 0.35)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: geo.size.height * 0.55)
                }
                .ignoresSafeArea()

                Text("☀️").font(.system(size: 52))
                    .position(x: geo.size.width * 0.9, y: geo.size.height * 0.13)
                Text("☁️").font(.system(size: 40))
                    .position(x: geo.size.width * 0.3, y: geo.size.height * 0.12)
                Text("🌼").font(.system(size: 30))
                    .position(x: geo.size.width * 0.08, y: geo.size.height * 0.85)
                Text("🌷").font(.system(size: 30))
                    .position(x: geo.size.width * 0.93, y: geo.size.height * 0.8)
                Text("🦋").font(.system(size: 26))
                    .position(x: geo.size.width * 0.14, y: geo.size.height * 0.38)

                if ready, let pet = vm.pet {
                    PetCharacterView(species: pet.species, pose: pose, facing: facing, size: 140)
                        .position(petPos)

                    Text("⚽")
                        .font(.system(size: 52))
                        .shadow(color: .black.opacity(0.2), radius: 4, y: 3)
                        .position(ballPos)
                        .gesture(
                            DragGesture(coordinateSpace: .named("playSpace"))
                                .onChanged { value in
                                    guard phase == .ready else { return }
                                    ballPos = clamp(value.location, in: geo.size)
                                }
                                .onEnded { value in
                                    guard phase == .ready else { return }
                                    throwBall(predicted: value.predictedEndLocation, in: geo.size, homeSpot: homeSpot)
                                }
                        )
                }

                ParticleField(system: particles)

                VStack {
                    ActivityHeader(title: "Hora de brincar! ⚽", onClose: onClose)
                    HStack {
                        Text(statusText)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 0.2, green: 0.4, blue: 0.2))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(.white.opacity(0.8)))
                        Spacer()
                        HStack(spacing: 4) {
                            Text("🎾").font(.system(size: 16))
                            Text("Buscas: \(catches)")
                                .font(.system(size: 16, weight: .heavy, design: .rounded))
                                .foregroundStyle(Color(red: 0.2, green: 0.4, blue: 0.2))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(.white.opacity(0.8)))
                    }
                    .padding(.horizontal, 16)
                    Spacer()
                    HStack {
                        StatBar(icon: "⚽", value: vm.pet?.fun ?? 0, color: .green)
                        Spacer()
                    }
                    .padding(.leading, 16)
                    .padding(.bottom, 12)
                }
            }
            .coordinateSpace(name: "playSpace")
            .onAppear {
                if !ready {
                    petPos = homeSpot
                    ballPos = CGPoint(x: geo.size.width * 0.62, y: geo.size.height * 0.62)
                    ready = true
                }
            }
        }
    }

    private var statusText: String {
        switch phase {
        case .ready: return "Jogue a bola bem longe! 👆"
        case .chasing: return "Corre, \(vm.pet?.name ?? "")! 🏃"
        case .returning: return "Trazendo de volta... ⚽"
        }
    }

    private func clamp(_ point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(
            x: min(max(point.x, 45), size.width - 45),
            y: min(max(point.y, 130), size.height - 60)
        )
    }

    /// A criança soltou a bola: ela voa, o pet corre, pega e traz de volta.
    private func throwBall(predicted: CGPoint, in size: CGSize, homeSpot: CGPoint) {
        phase = .chasing
        Haptics.tap()
        AudioManager.shared.play(.boing)

        let landing = clamp(predicted, in: size)
        withAnimation(.spring(response: 0.55, dampingFraction: 0.55)) {
            ballPos = landing
        }

        // pet corre atrás depois de um instante
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            let side: CGFloat = landing.x >= petPos.x ? -1 : 1
            let chaseSpot = CGPoint(x: landing.x + 60 * side, y: landing.y - 20)
            facing = landing.x >= petPos.x ? 1 : -1
            pose = .run
            let distance = hypot(chaseSpot.x - petPos.x, chaseSpot.y - petPos.y)
            let chaseTime = max(0.45, Double(distance / 280))
            withAnimation(.easeInOut(duration: chaseTime)) { petPos = chaseSpot }

            // pegou!
            DispatchQueue.main.asyncAfter(deadline: .now() + chaseTime) {
                catches += 1
                vm.play()
                Haptics.success()
                AudioManager.shared.play(.chime)
                particles.burst(["⭐", "💛", "🎉"], at: landing, count: 8)
                pose = .happy

                // traz a bola de volta
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    phase = .returning
                    facing = homeSpot.x >= petPos.x ? 1 : -1
                    pose = .run
                    withAnimation(.easeInOut(duration: 1.0)) {
                        petPos = homeSpot
                        ballPos = CGPoint(x: homeSpot.x + 70, y: homeSpot.y + 30)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        facing = 1
                        pose = .sit
                        phase = .ready
                        AudioManager.shared.play(.pop)
                    }
                }
            }
        }
    }
}
