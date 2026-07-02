import SwiftUI

struct PlayView: View {
    @EnvironmentObject var vm: GameViewModel
    let onClose: () -> Void

    @StateObject private var particles = ParticleSystem()
    @State private var ballPos: CGPoint = .zero
    @State private var petPos: CGPoint = .zero
    @State private var ready = false
    @State private var chasing = false
    @State private var catches = 0

    var body: some View {
        GeometryReader { geo in
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
                    .position(x: geo.size.width * 0.25, y: geo.size.height * 0.12)
                Text("🌼").font(.system(size: 30))
                    .position(x: geo.size.width * 0.1, y: geo.size.height * 0.85)
                Text("🌷").font(.system(size: 30))
                    .position(x: geo.size.width * 0.92, y: geo.size.height * 0.8)
                Text("🦋").font(.system(size: 26))
                    .position(x: geo.size.width * 0.15, y: geo.size.height * 0.4)

                if ready, let pet = vm.pet {
                    PetSpriteView(species: pet.species, size: 110)
                        .position(petPos)

                    Text("⚽")
                        .font(.system(size: 54))
                        .shadow(color: .black.opacity(0.2), radius: 4, y: 3)
                        .position(ballPos)
                        .gesture(
                            DragGesture(coordinateSpace: .named("playSpace"))
                                .onChanged { value in
                                    guard !chasing else { return }
                                    ballPos = clamp(value.location, in: geo.size)
                                }
                                .onEnded { _ in
                                    throwBall()
                                }
                        )
                }

                ParticleField(system: particles)

                VStack {
                    ActivityHeader(title: "Hora de brincar! ⚽", onClose: onClose)
                    HStack {
                        Text(chasing ? "Lá vai \(vm.pet?.name ?? "")! 🏃" : "Arraste a bola e solte! 👆")
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
                    petPos = CGPoint(x: geo.size.width * 0.28, y: geo.size.height * 0.62)
                    ballPos = CGPoint(x: geo.size.width * 0.68, y: geo.size.height * 0.62)
                    ready = true
                }
            }
        }
    }

    private func clamp(_ point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(
            x: min(max(point.x, 40), size.width - 40),
            y: min(max(point.y, 120), size.height - 50)
        )
    }

    private func throwBall() {
        guard !chasing else { return }
        chasing = true
        Haptics.tap()

        withAnimation(.spring(response: 0.9, dampingFraction: 0.7)) {
            petPos = CGPoint(x: ballPos.x - 45, y: ballPos.y)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
            catches += 1
            vm.play()
            Haptics.success()
            particles.burst(["⭐", "💛", "🎉"], at: ballPos, count: 8)
            chasing = false
        }
    }
}
