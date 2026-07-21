import SwiftUI

struct SleepView: View {
    @EnvironmentObject var vm: GameViewModel
    let onClose: () -> Void

    @StateObject private var particles = ParticleSystem()
    @State private var zTick = 0

    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    private var energyFull: Bool {
        (vm.pet?.energy ?? 0) >= 0.99
    }

    var body: some View {
        GeometryReader { geo in
            let petCenter = CGPoint(x: geo.size.width * 0.5, y: geo.size.height * 0.5)

            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.10, green: 0.12, blue: 0.30), Color(red: 0.22, green: 0.22, blue: 0.45)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                Text("🌙")
                    .font(.system(size: 56))
                    .position(x: geo.size.width * 0.88, y: geo.size.height * 0.16)

                // Estrelas Vetoriais Cintilantes
                ForEach(0..<10, id: \.self) { index in
                    VectorStar(size: index.isMultiple(of: 3) ? 22 : 16, delay: Double(index) * 0.3)
                        .position(
                            x: geo.size.width * (0.08 + 0.09 * Double(index)),
                            y: geo.size.height * (index.isMultiple(of: 2) ? 0.12 : 0.24)
                        )
                }

                // Caminha aconchegante detalhada
                ZStack {
                    // Estrutura de madeira externa da caminha
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.58, green: 0.38, blue: 0.22), Color(red: 0.48, green: 0.28, blue: 0.15)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: geo.size.width * 0.46, height: 80)
                        .shadow(color: .black.opacity(0.2), radius: 5, y: 3)
                        .position(x: petCenter.x, y: petCenter.y + 64)
                    
                    // Colchão estofado interno
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.45, green: 0.30, blue: 0.58), Color(red: 0.32, green: 0.18, blue: 0.45)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: geo.size.width * 0.42, height: 64)
                        .position(x: petCenter.x, y: petCenter.y + 60)
                    
                    // Travesseiro super fofo
                    ZStack {
                        Ellipse()
                            .fill(Color(red: 0.98, green: 0.95, blue: 0.92))
                            .frame(width: 90, height: 38)
                            .shadow(color: .black.opacity(0.12), radius: 3, y: 2)
                        // Dobrinha/Linha do travesseiro
                        Capsule()
                            .fill(Color(red: 0.88, green: 0.85, blue: 0.80))
                            .frame(width: 50, height: 3)
                            .offset(y: 4)
                    }
                    .position(x: petCenter.x - geo.size.width * 0.12, y: petCenter.y + 44)
                }

                if let pet = vm.pet {
                    PetCharacterView(species: pet.species, pose: .sleep, size: 150, mood: pet.mood)
                        .position(petCenter)
                }

                ParticleField(system: particles)

                VStack {
                    ActivityHeader(title: "Hora de dormir! 🌙", onClose: onClose)
                    Spacer()

                    HStack(spacing: 12) {
                        StatBar(icon: "⚡", value: vm.pet?.energy ?? 0, color: .yellow)
                        if energyFull {
                            BigPillButton(
                                title: "Acordar! ☀️",
                                colors: [Color(red: 1.0, green: 0.75, blue: 0.25), Color(red: 0.95, green: 0.60, blue: 0.15)]
                            ) {
                                AudioManager.shared.play(.chime)
                                onClose()
                            }
                        } else {
                            Text("Shhh... \(vm.pet?.name ?? "seu pet") está dormindo 💤")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.9))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(.white.opacity(0.15)))
                        }
                    }
                    .padding(.bottom, 16)
                }
            }
            .onAppear {
                vm.setTimeOfDay(.night)
            }
            .onDisappear {
                vm.setTimeOfDay(.day)
            }
            .onReceive(timer) { _ in
                guard !energyFull else { return }
                vm.rest(0.05)
                zTick += 1
                if zTick.isMultiple(of: 3) {
                    particles.burst(["💤"], at: CGPoint(x: petCenter.x + 65, y: petCenter.y - 40), count: 1)
                }
                if energyFull {
                    Haptics.success()
                    AudioManager.shared.play(.chime)
                    particles.burst(["✨", "💛"], at: petCenter, count: 10)
                }
            }
        }
    }
}


