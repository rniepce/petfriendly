import SwiftUI

private struct DirtSpot: Identifiable {
    let id = UUID()
    var offset: CGSize
    var amount: Double
}

struct BathView: View {
    @EnvironmentObject var vm: GameViewModel
    let onClose: () -> Void

    @StateObject private var particles = ParticleSystem()
    @State private var spots: [DirtSpot] = [
        DirtSpot(offset: CGSize(width: -45, height: -20), amount: 1),
        DirtSpot(offset: CGSize(width: 40, height: -35), amount: 1),
        DirtSpot(offset: CGSize(width: 0, height: 22), amount: 1),
        DirtSpot(offset: CGSize(width: 55, height: 12), amount: 1),
        DirtSpot(offset: CGSize(width: -28, height: 38), amount: 1),
    ]
    @State private var spongePos: CGPoint?
    @State private var celebrated = false
    @State private var scrubTick = 0

    private var allClean: Bool {
        spots.allSatisfy { $0.amount <= 0.05 }
    }

    var body: some View {
        GeometryReader { geo in
            let petCenter = CGPoint(x: geo.size.width * 0.5, y: geo.size.height * 0.45)

            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.72, green: 0.90, blue: 1.0), Color(red: 0.50, green: 0.78, blue: 0.95)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // banheira
                RoundedRectangle(cornerRadius: 44)
                    .fill(.white)
                    .frame(width: geo.size.width * 0.55, height: 120)
                    .shadow(color: .black.opacity(0.12), radius: 8, y: 5)
                    .position(x: petCenter.x, y: geo.size.height * 0.75)
                RoundedRectangle(cornerRadius: 36)
                    .fill(Color(red: 0.55, green: 0.82, blue: 1.0).opacity(0.7))
                    .frame(width: geo.size.width * 0.5, height: 85)
                    .position(x: petCenter.x, y: geo.size.height * 0.74)
                Text("🫧")
                    .font(.system(size: 30))
                    .position(x: petCenter.x - geo.size.width * 0.2, y: geo.size.height * 0.7)
                Text("🫧")
                    .font(.system(size: 22))
                    .position(x: petCenter.x + geo.size.width * 0.19, y: geo.size.height * 0.72)
                Text("🦆")
                    .font(.system(size: 34))
                    .position(x: petCenter.x + geo.size.width * 0.14, y: geo.size.height * 0.68)

                if let pet = vm.pet {
                    PetSpriteView(species: pet.species, size: 125)
                        .position(petCenter)
                }

                // sujeirinhas
                ForEach(spots) { spot in
                    Circle()
                        .fill(Color(red: 0.45, green: 0.30, blue: 0.15).opacity(0.65 * spot.amount))
                        .frame(width: 26, height: 26)
                        .blur(radius: 3)
                        .position(
                            x: petCenter.x + spot.offset.width,
                            y: petCenter.y + spot.offset.height
                        )
                }

                // camada que captura o dedo esfregando
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                spongePos = value.location
                                scrub(at: value.location, petCenter: petCenter)
                            }
                            .onEnded { _ in
                                spongePos = nil
                            }
                    )

                if let pos = spongePos {
                    Text("🧽")
                        .font(.system(size: 48))
                        .position(pos)
                        .allowsHitTesting(false)
                }

                ParticleField(system: particles)

                VStack {
                    ActivityHeader(title: "Hora do banho! 🛁", onClose: onClose)
                    Text(celebrated ? "Todo limpinho! ✨" : "Esfregue as sujeirinhas com o dedo! 🧽")
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

    private func scrub(at point: CGPoint, petCenter: CGPoint) {
        guard !celebrated else { return }

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
        if cleanedAny && scrubTick.isMultiple(of: 4) {
            particles.burst(["🫧"], at: point, count: 2)
        }

        if allClean {
            celebrated = true
            Haptics.success()
            vm.bathe()
            particles.burst(["✨", "🫧", "💖"], at: petCenter, count: 14)
        }
    }
}
