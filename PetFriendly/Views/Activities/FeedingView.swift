import SwiftUI

struct FeedingView: View {
    @EnvironmentObject var vm: GameViewModel
    let onClose: () -> Void

    @StateObject private var particles = ParticleSystem()
    @State private var petScale: CGFloat = 1

    private var isFull: Bool {
        (vm.pet?.hunger ?? 0) >= 0.99
    }

    private var foods: [String] {
        guard let pet = vm.pet else { return [] }
        return [pet.species.favoriteFood, "🍎", "🍌", "🍪", "🥛"]
    }

    var body: some View {
        GeometryReader { geo in
            let petCenter = CGPoint(x: geo.size.width * 0.5, y: geo.size.height * 0.45)

            ZStack {
                LinearGradient(
                    colors: [Color(red: 1.0, green: 0.93, blue: 0.78), Color(red: 1.0, green: 0.80, blue: 0.58)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // toalha de piquenique
                Ellipse()
                    .fill(Color(red: 0.95, green: 0.55, blue: 0.45).opacity(0.35))
                    .frame(width: geo.size.width * 0.45, height: 80)
                    .position(x: petCenter.x, y: petCenter.y + 85)

                if let pet = vm.pet {
                    PetSpriteView(species: pet.species, size: 125)
                        .scaleEffect(petScale)
                        .position(petCenter)

                    Text("🍽️")
                        .font(.system(size: 40))
                        .position(x: petCenter.x, y: petCenter.y + 95)
                }

                // barra de fome
                VStack {
                    Spacer()
                    HStack {
                        StatBar(icon: "🍖", value: vm.pet?.hunger ?? 0, color: .orange)
                        Spacer()
                    }
                    .padding(.leading, 16)
                    .padding(.bottom, 12)
                }

                // prateleira de comidas
                VStack {
                    Spacer()
                    Text(isFull ? "Barriguinha cheia! 😋" : "Arraste a comida até \(vm.pet?.name ?? "seu pet")! 👇")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 0.5, green: 0.32, blue: 0.15))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(.white.opacity(0.7)))
                    HStack(spacing: 18) {
                        ForEach(foods, id: \.self) { food in
                            DraggableFood(emoji: food, petCenter: petCenter) {
                                eat(at: petCenter)
                            }
                        }
                    }
                    .padding(.bottom, 14)
                }

                ParticleField(system: particles)

                VStack {
                    ActivityHeader(title: "Hora de comer! 🍎", onClose: onClose)
                    Spacer()
                }
            }
            .coordinateSpace(name: "feedSpace")
        }
    }

    private func eat(at petCenter: CGPoint) {
        guard !isFull else {
            particles.burst(["😋"], at: petCenter, count: 2)
            return
        }
        Haptics.success()
        vm.feed()
        particles.burst(["💖", "😋", "✨"], at: petCenter, count: 6)
        withAnimation(.spring(response: 0.25, dampingFraction: 0.4)) { petScale = 1.15 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { petScale = 1 }
        }
    }
}

/// Comida que a criança arrasta com o dedo até o pet.
private struct DraggableFood: View {
    let emoji: String
    let petCenter: CGPoint
    let onEaten: () -> Void

    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false

    var body: some View {
        Text(emoji)
            .font(.system(size: 46))
            .padding(8)
            .background(
                Circle()
                    .fill(.white.opacity(0.85))
                    .shadow(color: .black.opacity(0.12), radius: 5, y: 3)
            )
            .offset(dragOffset)
            .scaleEffect(isDragging ? 1.25 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragging)
            .gesture(
                DragGesture(coordinateSpace: .named("feedSpace"))
                    .onChanged { value in
                        isDragging = true
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        isDragging = false
                        let dx = value.location.x - petCenter.x
                        let dy = value.location.y - petCenter.y
                        if (dx * dx + dy * dy).squareRoot() < 130 {
                            onEaten()
                        }
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            dragOffset = .zero
                        }
                    }
            )
    }
}
