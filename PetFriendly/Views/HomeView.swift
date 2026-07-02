import SwiftUI

enum Activity: Identifiable {
    case feed
    case bath
    case play
    case sleep
    case wardrobe

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

            PetCharacterView(species: pet.species, pose: pose, facing: facing, size: 170, accessory: pet.equippedAccessory)
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
        if let pet = vm.pet {
            AudioManager.shared.playVoice(for: pet.species)
        } else {
            AudioManager.shared.play(.boing)
        }
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

                // Controles de clima e tempo
                HStack(spacing: 8) {
                    // Botão Dia/Noite
                    Button {
                        Haptics.tap()
                        AudioManager.shared.play(.pop)
                        var p = pet
                        p.timeOfDay = p.timeOfDay == .day ? .night : .day
                        vm.pet = p
                        vm.save()
                    } label: {
                        Text(pet.timeOfDay == .day ? "☀️" : "🌙")
                            .font(.system(size: 16))
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(.white.opacity(0.85)))
                    }
                    .buttonStyle(SquishyButtonStyle())

                    // Botão Clima
                    Button {
                        Haptics.tap()
                        AudioManager.shared.play(.pop)
                        var p = pet
                        p.weather = p.weather == .sunny ? .rainy : .sunny
                        vm.pet = p
                        vm.save()
                    } label: {
                        Text(pet.weather == .sunny ? "🌈" : "🌧️")
                            .font(.system(size: 16))
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(.white.opacity(0.85)))
                    }
                    .buttonStyle(SquishyButtonStyle())
                }
                .padding(4)
                .background(Capsule().fill(.white.opacity(0.45)))

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
                    open(.wardrobe)
                } label: {
                    Text("👑")
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
        case .wardrobe:
            WardrobeView(onClose: closeActivity)
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
    @EnvironmentObject var vm: GameViewModel

    var body: some View {
        GeometryReader { geo in
            let isNight = vm.pet?.timeOfDay == .night
            let isRainy = vm.pet?.weather == .rainy

            ZStack {
                LinearGradient(
                    colors: isNight ?
                        [Color(red: 0.16, green: 0.14, blue: 0.28), Color(red: 0.28, green: 0.20, blue: 0.36)] :
                        [Color(red: 1.0, green: 0.93, blue: 0.82), Color(red: 1.0, green: 0.85, blue: 0.72)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // chão de madeira com textura de tábuas
                VStack(spacing: 0) {
                    Spacer()
                    ZStack {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: isNight ?
                                        [Color(red: 0.48, green: 0.32, blue: 0.20), Color(red: 0.32, green: 0.20, blue: 0.12)] :
                                        [Color(red: 0.85, green: 0.65, blue: 0.45), Color(red: 0.75, green: 0.55, blue: 0.38)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        // Linhas horizontais das tábuas
                        VStack(spacing: 24) {
                            ForEach(0..<4) { _ in
                                Divider()
                                    .background(Color(red: 0.60, green: 0.42, blue: 0.28).opacity(isNight ? 0.22 : 0.35))
                            }
                        }
                        .padding(.vertical, 12)
                    }
                    .frame(height: geo.size.height * 0.3)
                }

                // Janela com céu e nuvens
                ZStack {
                    // Fundo da janela (Céu)
                    RoundedRectangle(cornerRadius: 18)
                        .fill(
                            LinearGradient(
                                colors: isNight ?
                                    [Color(red: 0.06, green: 0.06, blue: 0.18), Color(red: 0.12, green: 0.12, blue: 0.28)] :
                                    (isRainy ?
                                        [Color(red: 0.48, green: 0.52, blue: 0.62), Color(red: 0.65, green: 0.68, blue: 0.74)] :
                                        [Color(red: 0.55, green: 0.80, blue: 1.0), Color(red: 0.82, green: 0.94, blue: 1.0)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 140, height: 110)
                        .overlay(
                            ZStack {
                                if isNight {
                                    // Lua crescente amarela brilhante
                                    ZStack {
                                        Circle()
                                            .fill(Color(red: 1.0, green: 0.92, blue: 0.55))
                                            .frame(width: 24, height: 24)
                                        Circle()
                                            .fill(Color(red: 0.06, green: 0.06, blue: 0.18))
                                            .frame(width: 24, height: 24)
                                            .offset(x: -8, y: -2)
                                    }
                                    .position(x: 35, y: 30)

                                    VectorStar(size: 8, delay: 0)
                                        .position(x: 105, y: 30)
                                    VectorStar(size: 6, delay: 1.0)
                                        .position(x: 80, y: 55)
                                } else {
                                    // Sol pequeno
                                    Circle()
                                        .fill(RadialGradient(colors: [Color(red: 1.0, green: 0.88, blue: 0.45), Color(red: 1.0, green: 0.60, blue: 0.20)], center: .center, startRadius: 0, endRadius: 22))
                                        .frame(width: 28, height: 28)
                                        .position(x: 35, y: 30)

                                    VectorCloud(scale: 0.45, opacity: isRainy ? 0.55 : 0.8)
                                        .offset(x: 10, y: -5)
                                }

                                if isRainy {
                                    // Gotas caindo fora da janela
                                    TimelineView(.animation) { context in
                                        let t = context.date.timeIntervalSinceReferenceDate
                                        GeometryReader { windowGeo in
                                            ForEach(0..<4) { index in
                                                let yOffset = CGFloat((t * 85 + Double(index) * 32).truncatingRemainder(dividingBy: 110)) - 10
                                                let xPos = CGFloat(20 + index * 30)
                                                Capsule()
                                                    .fill(Color(red: 0.55, green: 0.78, blue: 0.95).opacity(0.45))
                                                    .frame(width: 2, height: 14)
                                                    .position(x: xPos, y: yOffset)
                                            }
                                        }
                                    }
                                    .allowsHitTesting(false)
                                }
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    
                    // Grade e moldura da janela
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color(red: 0.70, green: 0.50, blue: 0.35), lineWidth: 8)
                        .frame(width: 140, height: 110)
                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 3)
                    
                    // Divisórias de vidro (cruzeta)
                    Rectangle()
                        .fill(Color(red: 0.70, green: 0.50, blue: 0.35))
                        .frame(width: 6, height: 110)
                    Rectangle()
                        .fill(Color(red: 0.70, green: 0.50, blue: 0.35))
                        .frame(width: 140, height: 6)
                }
                .position(x: geo.size.width * 0.17, y: geo.size.height * 0.3)

                // Tapete com detalhes circulares
                ZStack {
                    Ellipse()
                        .fill(Color(red: 0.98, green: 0.70, blue: 0.65).opacity(0.75))
                        .frame(width: geo.size.width * 0.42, height: 74)
                    Ellipse()
                        .fill(Color(red: 1.0, green: 0.82, blue: 0.78).opacity(0.85))
                        .frame(width: geo.size.width * 0.36, height: 58)
                    Ellipse()
                        .stroke(Color(red: 0.95, green: 0.55, blue: 0.50).opacity(0.5), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round, dash: [6, 6]))
                        .frame(width: geo.size.width * 0.38, height: 64)
                }
                .position(x: geo.size.width * 0.5, y: geo.size.height * 0.72)

                // Planta no Vaso Vetorial
                ZStack(alignment: .bottom) {
                    // Folhas da planta
                    ZStack {
                        // Folha esquerda
                        Capsule()
                            .fill(LinearGradient(colors: [Color(red: 0.28, green: 0.66, blue: 0.34), Color(red: 0.20, green: 0.50, blue: 0.25)], startPoint: .top, endPoint: .bottom))
                            .frame(width: 12, height: 42)
                            .rotationEffect(.degrees(-24), anchor: .bottom)
                        // Folha direita
                        Capsule()
                            .fill(LinearGradient(colors: [Color(red: 0.32, green: 0.72, blue: 0.38), Color(red: 0.22, green: 0.55, blue: 0.28)], startPoint: .top, endPoint: .bottom))
                            .frame(width: 14, height: 48)
                            .rotationEffect(.degrees(20), anchor: .bottom)
                        // Folha central
                        Capsule()
                            .fill(LinearGradient(colors: [Color(red: 0.35, green: 0.78, blue: 0.42), Color(red: 0.25, green: 0.58, blue: 0.30)], startPoint: .top, endPoint: .bottom))
                            .frame(width: 15, height: 56)
                            .offset(y: -4)
                    }
                    .offset(y: -14)
                    
                    // Vaso de cerâmica
                    UnevenRoundedRectangle(topLeadingRadius: 2, bottomLeadingRadius: 8, bottomTrailingRadius: 8, topTrailingRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.88, green: 0.52, blue: 0.35), Color(red: 0.74, green: 0.38, blue: 0.22)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 38, height: 32)
                        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
                }
                .position(x: geo.size.width * 0.86, y: geo.size.height * 0.58)

                // Quadro Decorativo de Pôr-do-Sol
                ZStack {
                    // Moldura do quadro
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(red: 0.60, green: 0.42, blue: 0.28))
                        .frame(width: 70, height: 60)
                        .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
                    
                    // Tela de pintura
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 1.0, green: 0.55, blue: 0.50), Color(red: 1.0, green: 0.82, blue: 0.45)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 58, height: 48)
                        .overlay(
                            // Sol se pondo na pintura
                            Circle()
                                .fill(Color(red: 1.0, green: 0.92, blue: 0.60))
                                .frame(width: 16, height: 16)
                                .offset(y: 8)
                        )
                        .overlay(
                            // Colina na pintura
                            Path { path in
                                path.move(to: CGPoint(x: 0, y: 48))
                                path.addQuadCurve(to: CGPoint(x: 58, y: 48), control: CGPoint(x: 29, y: 34))
                            }
                            .fill(Color(red: 0.40, green: 0.28, blue: 0.48))
                        )
                        .clipShape(Rectangle())
                }
                .position(x: geo.size.width * 0.76, y: geo.size.height * 0.22)

                // Ursinho de Pelúcia Vetorial
                ZStack {
                    let bearColor = Color(red: 0.72, green: 0.52, blue: 0.35)
                    let darkBearColor = Color(red: 0.58, green: 0.38, blue: 0.22)
                    let creamColor = Color(red: 0.95, green: 0.86, blue: 0.76)
                    
                    // Orelhas
                    Circle()
                        .fill(bearColor)
                        .frame(width: 14)
                        .offset(x: -15, y: -14)
                    Circle()
                        .fill(bearColor)
                        .frame(width: 14)
                        .offset(x: 15, y: -14)
                    Circle()
                        .fill(creamColor)
                        .frame(width: 6)
                        .offset(x: -15, y: -14)
                    Circle()
                        .fill(creamColor)
                        .frame(width: 6)
                        .offset(x: 15, y: -14)
                    
                    // Patas de trás
                    Circle()
                        .fill(darkBearColor)
                        .frame(width: 16)
                        .offset(x: -14, y: 15)
                    Circle()
                        .fill(darkBearColor)
                        .frame(width: 16)
                        .offset(x: 14, y: 15)
                    
                    // Corpo
                    Circle()
                        .fill(bearColor)
                        .frame(width: 38)
                        .offset(y: 6)
                    Circle()
                        .fill(creamColor)
                        .frame(width: 18)
                        .offset(y: 6)
                    
                    // Cabeça
                    Circle()
                        .fill(bearColor)
                        .frame(width: 32)
                    
                    // Olhos
                    Circle()
                        .fill(.black)
                        .frame(width: 4)
                        .offset(x: -6, y: -2)
                    Circle()
                        .fill(.black)
                        .frame(width: 4)
                        .offset(x: 6, y: -2)
                    
                    // Muzzle (Focinho)
                    Ellipse()
                        .fill(creamColor)
                        .frame(width: 12, height: 10)
                        .offset(y: 4)
                    Circle()
                        .fill(Color(red: 0.3, green: 0.2, blue: 0.15))
                        .frame(width: 3.5)
                        .offset(y: 2)
                }
                .position(x: geo.size.width * 0.1, y: geo.size.height * 0.72)
            }
        }
        .ignoresSafeArea()
    }
}
