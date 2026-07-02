import SwiftUI

enum Activity: Identifiable {
    case feed
    case bath
    case play
    case sleep

    var id: Self { self }
}

struct HomeView: View {
    @EnvironmentObject var vm: GameViewModel
    @ObservedObject private var audio = AudioManager.shared
    @StateObject private var particles = ParticleSystem()

    @State private var activity: Activity?
    @State private var showShopConfirm = false

    // estado do pet passeando pelo quarto
    @State private var petPos: CGPoint = .zero
    @State private var facing: CGFloat = 1
    @State private var pose: PetPose = .idle
    @State private var jumpOffset: CGFloat = 0
    @State private var isStroking = false
    @State private var strokeTick = 0

    private let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    private let behaviorTimer = Timer.publish(every: 4, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                RoomBackground()

                if let pet = vm.pet {
                    petArea(pet: pet)
                    hud(pet: pet)
                }

                ParticleField(system: particles)

                if activity != nil {
                    activityOverlay
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(2)
                }
            }
            .onAppear {
                if petPos == .zero {
                    petPos = CGPoint(x: geo.size.width * 0.5, y: geo.size.height * 0.56)
                }
            }
            .onReceive(behaviorTimer) { _ in
                wander(in: geo.size)
            }
        }
        .onReceive(timer) { _ in
            if activity == nil {
                vm.tick()
            }
        }
        .alert("Quer escolher outro pet?", isPresented: $showShopConfirm) {
            Button("Sim, ir ao petshop 🏪", role: .destructive) {
                vm.releasePetAndShop()
            }
            Button("Não, ficar com meu pet 💖", role: .cancel) {}
        } message: {
            Text("Seu pet atual vai voltar para o petshop.")
        }
    }

    // MARK: - Pet passeando pelo quarto

    private func petArea(pet: Pet) -> some View {
        ZStack {
            if let hint = pet.needHint {
                SpeechBubble(text: hint)
                    .position(x: petPos.x, y: petPos.y - 118)
            }

            PetCharacterView(species: pet.species, pose: pose, facing: facing, size: 170)
                .offset(y: jumpOffset)
                .position(petPos)
                .onTapGesture { jump() }
                .gesture(strokeGesture)

            Text(pet.name)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color(red: 0.95, green: 0.55, blue: 0.45).opacity(0.9)))
                .position(x: petPos.x, y: petPos.y + 100)
                .allowsHitTesting(false)
        }
    }

    /// Fazer carinho: arrastar o dedo sobre o pet solta coraçõezinhos.
    private var strokeGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                if !isStroking {
                    isStroking = true
                    pose = .happy
                }
                strokeTick += 1
                if strokeTick.isMultiple(of: 6) {
                    Haptics.tap()
                    particles.burst(["💖", "💕"], at: CGPoint(x: petPos.x + value.translation.width * 0.3, y: petPos.y - 40), count: 2)
                }
            }
            .onEnded { _ in
                isStroking = false
                pose = .idle
            }
    }

    /// Tocar no pet: ele dá um pulinho feliz.
    private func jump() {
        guard !isStroking else { return }
        Haptics.tap()
        AudioManager.shared.play(.boing)
        pose = .happy
        particles.burst(["💖", "✨"], at: CGPoint(x: petPos.x, y: petPos.y - 60), count: 5)
        withAnimation(.easeOut(duration: 0.25)) { jumpOffset = -44 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeIn(duration: 0.3)) { jumpOffset = 0 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            if pose == .happy && !isStroking { pose = .idle }
        }
    }

    /// De vez em quando o pet anda para outro canto, senta ou fica parado.
    private func wander(in size: CGSize) {
        guard activity == nil, vm.pet != nil, !isStroking else { return }
        guard pose == .idle || pose == .sit else { return }

        switch Int.random(in: 0..<4) {
        case 0:
            pose = .sit
        case 1:
            pose = .idle
        default:
            let target = CGPoint(
                x: CGFloat.random(in: size.width * 0.22...size.width * 0.78),
                y: CGFloat.random(in: size.height * 0.48...size.height * 0.66)
            )
            facing = target.x >= petPos.x ? 1 : -1
            pose = .walk
            let distance = hypot(target.x - petPos.x, target.y - petPos.y)
            let duration = max(0.6, Double(distance / 110))
            withAnimation(.easeInOut(duration: duration)) { petPos = target }
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                if pose == .walk { pose = Bool.random() ? .idle : .sit }
            }
        }
    }

    // MARK: - HUD (barras em cima, botões embaixo)

    private func hud(pet: Pet) -> some View {
        VStack {
            HStack(spacing: 8) {
                StatBar(icon: "🍖", value: pet.hunger, color: .orange)
                StatBar(icon: "🫧", value: pet.hygiene, color: .cyan)
                StatBar(icon: "⚽", value: pet.fun, color: .green)
                StatBar(icon: "⚡", value: pet.energy, color: .yellow)

                Spacer()

                HStack(spacing: 4) {
                    Text("⭐").font(.system(size: 16))
                    Text("\(pet.stars)")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(red: 0.5, green: 0.35, blue: 0.1))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(.white.opacity(0.75)))

                Button {
                    Haptics.tap()
                    audio.musicOn.toggle()
                } label: {
                    Text(audio.musicOn ? "🎵" : "🔕")
                        .font(.system(size: 18))
                        .padding(7)
                        .background(Circle().fill(.white.opacity(0.75)))
                }
                .buttonStyle(SquishyButtonStyle())

                Button {
                    Haptics.tap()
                    showShopConfirm = true
                } label: {
                    Text("🏪")
                        .font(.system(size: 18))
                        .padding(7)
                        .background(Circle().fill(.white.opacity(0.75)))
                }
                .buttonStyle(SquishyButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            Spacer()

            HStack(spacing: 22) {
                BigRoundButton(emoji: "🍎", label: "Comer", color: .orange, showAlert: pet.hunger < 0.35) {
                    open(.feed)
                }
                BigRoundButton(emoji: "🛁", label: "Banho", color: .cyan, showAlert: pet.hygiene < 0.35) {
                    open(.bath)
                }
                BigRoundButton(emoji: "⚽", label: "Brincar", color: .green, showAlert: pet.fun < 0.35) {
                    open(.play)
                }
                BigRoundButton(emoji: "🌙", label: "Dormir", color: .indigo, showAlert: pet.energy < 0.3) {
                    open(.sleep)
                }
            }
            .padding(.bottom, 10)
        }
    }

    // MARK: - Atividades

    @ViewBuilder
    private var activityOverlay: some View {
        switch activity {
        case .feed:
            FeedingView(onClose: closeActivity)
        case .bath:
            BathView(onClose: closeActivity)
        case .play:
            PlayView(onClose: closeActivity)
        case .sleep:
            SleepView(onClose: closeActivity)
        case nil:
            EmptyView()
        }
    }

    private func open(_ newActivity: Activity) {
        pose = .idle
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            activity = newActivity
        }
    }

    private func closeActivity() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            activity = nil
        }
    }
}

// MARK: - Quarto da casa

struct RoomBackground: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    colors: [Color(red: 1.0, green: 0.93, blue: 0.82), Color(red: 1.0, green: 0.85, blue: 0.72)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // chão de madeira
                VStack(spacing: 0) {
                    Spacer()
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.85, green: 0.65, blue: 0.45), Color(red: 0.75, green: 0.55, blue: 0.38)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: geo.size.height * 0.3)
                }

                // janela com céu
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.55, green: 0.8, blue: 1.0), Color(red: 0.8, green: 0.92, blue: 1.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 130, height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color(red: 0.7, green: 0.5, blue: 0.35), lineWidth: 6)
                    )
                    .overlay(Text("☀️").font(.system(size: 30)).offset(x: -30, y: -20))
                    .overlay(Text("☁️").font(.system(size: 22)).offset(x: 28, y: 10))
                    .position(x: geo.size.width * 0.17, y: geo.size.height * 0.3)

                // tapete
                Ellipse()
                    .fill(Color(red: 0.98, green: 0.7, blue: 0.65).opacity(0.6))
                    .frame(width: geo.size.width * 0.4, height: 70)
                    .position(x: geo.size.width * 0.5, y: geo.size.height * 0.72)

                Text("🪴")
                    .font(.system(size: 46))
                    .position(x: geo.size.width * 0.86, y: geo.size.height * 0.6)
                Text("🖼️")
                    .font(.system(size: 40))
                    .position(x: geo.size.width * 0.76, y: geo.size.height * 0.22)
                Text("🧸")
                    .font(.system(size: 34))
                    .position(x: geo.size.width * 0.1, y: geo.size.height * 0.72)
            }
        }
        .ignoresSafeArea()
    }
}
