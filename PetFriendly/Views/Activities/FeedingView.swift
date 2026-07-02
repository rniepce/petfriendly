import SwiftUI

struct FeedingView: View {
    @EnvironmentObject var vm: GameViewModel
    let onClose: () -> Void

    private enum FeedPhase {
        case waiting   // esperando a criança arrastar comida
        case running   // pet correndo até a tigela
        case eating    // pet comendo
    }

    @StateObject private var particles = ParticleSystem()
    @State private var phase: FeedPhase = .waiting
    @State private var petPos: CGPoint = .zero
    @State private var facing: CGFloat = 1
    @State private var pose: PetPose = .sit
    @State private var bowlFood: String?
    @State private var ready = false

    private var isFull: Bool {
        (vm.pet?.hunger ?? 0) >= 0.99
    }

    private var foods: [String] {
        guard let pet = vm.pet else { return [] }
        return [pet.species.favoriteFood, "🍎", "🍌", "🍪", "🥛"]
    }

    var body: some View {
        GeometryReader { geo in
            let bowlPos = CGPoint(x: geo.size.width * 0.60, y: geo.size.height * 0.64)

            ZStack {
                LinearGradient(
                    colors: [Color(red: 1.0, green: 0.93, blue: 0.78), Color(red: 1.0, green: 0.80, blue: 0.58)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // toalhinha
                Ellipse()
                    .fill(Color(red: 0.95, green: 0.55, blue: 0.45).opacity(0.35))
                    .frame(width: geo.size.width * 0.42, height: 76)
                    .position(x: bowlPos.x - 40, y: bowlPos.y + 16)

                bowl(at: bowlPos)

                if ready, let pet = vm.pet {
                    PetCharacterView(species: pet.species, pose: pose, facing: facing, size: 150)
                        .position(petPos)
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
                    Text(statusText)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 0.5, green: 0.32, blue: 0.15))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(.white.opacity(0.7)))
                    HStack(spacing: 18) {
                        ForEach(foods, id: \.self) { food in
                            DraggableFood(emoji: food, targetCenter: bowlPos, enabled: phase == .waiting && !isFull) {
                                deliver(food: food, bowlPos: bowlPos)
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
            .onAppear {
                if !ready {
                    petPos = CGPoint(x: geo.size.width * 0.28, y: geo.size.height * 0.52)
                    ready = true
                }
            }
        }
    }

    private var statusText: String {
        if isFull { return "Barriguinha cheia! 😋" }
        switch phase {
        case .waiting: return "Arraste a comida para a tigela! 👇"
        case .running: return "Lá vem \(vm.pet?.name ?? "")! 🏃"
        case .eating: return "Nham nham nham... 😋"
        }
    }

    private func bowl(at pos: CGPoint) -> some View {
        ZStack {
            UnevenRoundedRectangle(
                topLeadingRadius: 8,
                bottomLeadingRadius: 26,
                bottomTrailingRadius: 26,
                topTrailingRadius: 8
            )
            .fill(Color(red: 0.90, green: 0.35, blue: 0.40))
            .frame(width: 86, height: 42)
            .shadow(color: .black.opacity(0.12), radius: 4, y: 3)
            Ellipse()
                .fill(Color(red: 0.70, green: 0.20, blue: 0.28))
                .frame(width: 76, height: 16)
                .offset(y: -20)
            if let food = bowlFood {
                Text(food)
                    .font(.system(size: 28))
                    .offset(y: -16)
                    .transition(.scale)
            }
        }
        .position(pos)
    }

    /// Comida chegou na tigela: o pet corre até lá e come.
    private func deliver(food: String, bowlPos: CGPoint) {
        guard phase == .waiting, !isFull else { return }
        Haptics.tap()
        AudioManager.shared.play(.pop)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { bowlFood = food }

        phase = .running
        let eatSpot = CGPoint(x: bowlPos.x - 95, y: bowlPos.y - 58)
        facing = eatSpot.x >= petPos.x ? 1 : -1
        pose = .run
        let distance = hypot(eatSpot.x - petPos.x, eatSpot.y - petPos.y)
        let runTime = max(0.35, Double(distance / 300))
        withAnimation(.easeInOut(duration: runTime)) { petPos = eatSpot }

        DispatchQueue.main.asyncAfter(deadline: .now() + runTime) {
            facing = 1
            pose = .eat
            phase = .eating
            for i in 0..<3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.55) {
                    AudioManager.shared.play(.nom)
                    particles.burst(["✨"], at: bowlPos, count: 1)
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + runTime + 1.8) {
            vm.feed()
            Haptics.success()
            particles.burst(["💖", "😋", "✨"], at: CGPoint(x: petPos.x, y: petPos.y - 50), count: 6)
            withAnimation { bowlFood = nil }
            pose = .sit
            phase = .waiting
            if isFull {
                AudioManager.shared.play(.chime)
                pose = .happy
            }
        }
    }
}

/// Comida que a criança arrasta com o dedo até a tigela.
private struct DraggableFood: View {
    let emoji: String
    let targetCenter: CGPoint
    let enabled: Bool
    let onDelivered: () -> Void

    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false

    var body: some View {
        Text(emoji)
            .font(.system(size: 44))
            .padding(8)
            .background(
                Circle()
                    .fill(.white.opacity(0.85))
                    .shadow(color: .black.opacity(0.12), radius: 5, y: 3)
            )
            .opacity(enabled ? 1 : 0.45)
            .offset(dragOffset)
            .scaleEffect(isDragging ? 1.25 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragging)
            .gesture(
                DragGesture(coordinateSpace: .named("feedSpace"))
                    .onChanged { value in
                        guard enabled else { return }
                        isDragging = true
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        isDragging = false
                        if enabled {
                            let dx = value.location.x - targetCenter.x
                            let dy = value.location.y - targetCenter.y
                            if (dx * dx + dy * dy).squareRoot() < 110 {
                                onDelivered()
                            }
                        }
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            dragOffset = .zero
                        }
                    }
            )
    }
}
