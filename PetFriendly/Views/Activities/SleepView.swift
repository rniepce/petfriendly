import SwiftUI

struct SleepView: View {
    @EnvironmentObject var vm: GameViewModel
    let onClose: () -> Void

    @StateObject private var particles = ParticleSystem()
    @State private var breathe = false
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

                // estrelinhas piscando
                ForEach(0..<10, id: \.self) { index in
                    TwinklingStar(delay: Double(index) * 0.25)
                        .position(
                            x: geo.size.width * (0.08 + 0.09 * Double(index)),
                            y: geo.size.height * (index.isMultiple(of: 2) ? 0.12 : 0.24)
                        )
                }

                // caminha
                Ellipse()
                    .fill(Color(red: 0.55, green: 0.40, blue: 0.60).opacity(0.8))
                    .frame(width: geo.size.width * 0.4, height: 80)
                    .position(x: petCenter.x, y: petCenter.y + 70)

                if let pet = vm.pet {
                    PetSpriteView(species: pet.species, size: 120)
                        .scaleEffect(breathe ? 1.05 : 0.98)
                        .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: breathe)
                        .position(petCenter)

                    Text("😴")
                        .font(.system(size: 30))
                        .position(x: petCenter.x + 70, y: petCenter.y - 55)
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
            .onAppear { breathe = true }
            .onReceive(timer) { _ in
                guard !energyFull else { return }
                vm.rest(0.05)
                zTick += 1
                if zTick.isMultiple(of: 3) {
                    particles.burst(["💤"], at: CGPoint(x: petCenter.x + 60, y: petCenter.y - 40), count: 1)
                }
                if energyFull {
                    Haptics.success()
                    particles.burst(["✨", "💛"], at: petCenter, count: 10)
                }
            }
        }
    }
}

private struct TwinklingStar: View {
    let delay: Double
    @State private var twinkle = false

    var body: some View {
        Text("⭐")
            .font(.system(size: 16))
            .opacity(twinkle ? 1 : 0.25)
            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true).delay(delay), value: twinkle)
            .onAppear { twinkle = true }
    }
}
