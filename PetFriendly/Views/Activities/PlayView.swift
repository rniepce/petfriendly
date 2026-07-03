import SwiftUI

struct PlayView: View {
    @EnvironmentObject var vm: GameViewModel
    let onClose: () -> Void

    private enum PlayPhase {
        case ready      // bola com a criança
        case chasing    // pet correndo atrás
        case returning  // pet trazendo a bola de volta
    }

    private enum GameMode {
        case menu
        case catchBall
        case jumpGame
    }

    @StateObject private var particles = ParticleSystem()
    
    // Configurações de modo
    @State private var mode: GameMode = .menu
    
    // Estado clássico (buscar bola)
    @State private var phase: PlayPhase = .ready
    @State private var ballPos: CGPoint = .zero
    @State private var petPos: CGPoint = .zero
    @State private var facing: CGFloat = 1
    @State private var pose: PetPose = .sit
    @State private var ready = false
    @State private var catches = 0
    
    // Estado do mini-game (corrida de pulos)
    @State private var jumpScore = 0
    @State private var petJumpY: CGFloat = 0
    @State private var isGrounded = true
    @State private var isGameOver = false
    @State private var earnedCoinsThisSession = 0
    @State private var obstacleX: CGFloat = 1000
    
    // Timer para o pulo do pet
    let gameTimer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            let homeSpot = CGPoint(x: geo.size.width * 0.25, y: geo.size.height * 0.60)
            let isNight = vm.pet?.timeOfDay == .night
            let isRainy = vm.pet?.weather == .rainy

            ZStack {
                // 1. Cenário de Fundo (Céu e colinas)
                backgroundScenery(geo: geo, isNight: isNight)
                
                // 2. Efeito de Chuva
                rainOverlay(geo: geo, isRainy: isRainy)

                // 3. Modos de Jogo reais
                switch mode {
                case .menu:
                    menuView(geo: geo, homeSpot: homeSpot, isNight: isNight)
                case .catchBall:
                    catchBallView(geo: geo, homeSpot: homeSpot)
                case .jumpGame:
                    jumpGameView(geo: geo, homeSpot: homeSpot)
                }

                // 4. Efeito de Partículas
                ParticleField(system: particles)
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

    // MARK: - Subviews Extraídas para Otimizar Compilação

    @ViewBuilder
    private func backgroundScenery(geo: GeometryProxy, isNight: Bool) -> some View {
        ZStack {
            LinearGradient(
                colors: isNight ?
                    [Color(red: 0.06, green: 0.06, blue: 0.18), Color(red: 0.12, green: 0.12, blue: 0.28)] :
                    [Color(red: 0.55, green: 0.82, blue: 1.0), Color(red: 0.80, green: 0.94, blue: 1.0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if isNight {
                ZStack {
                    Circle()
                        .fill(Color(red: 1.0, green: 0.92, blue: 0.55))
                        .frame(width: 44, height: 44)
                    Circle()
                        .fill(Color(red: 0.06, green: 0.06, blue: 0.18))
                        .frame(width: 44, height: 44)
                        .offset(x: -12, y: -4)
                }
                .position(x: geo.size.width * 0.88, y: geo.size.height * 0.18)
                
                VectorStar(size: 16, delay: 0)
                    .position(x: geo.size.width * 0.18, y: geo.size.height * 0.15)
                VectorStar(size: 12, delay: 1.5)
                    .position(x: geo.size.width * 0.48, y: geo.size.height * 0.12)
            } else {
                VectorSun()
                    .position(x: geo.size.width * 0.88, y: geo.size.height * 0.18)
                VectorCloud(scale: 0.7, opacity: 0.85)
                    .position(x: geo.size.width * 0.28, y: geo.size.height * 0.15)
                VectorCloud(scale: 0.55, opacity: 0.75)
                    .position(x: geo.size.width * 0.58, y: geo.size.height * 0.12)
            }
            
            Path { path in
                path.move(to: CGPoint(x: 0, y: geo.size.height * 0.52))
                path.addQuadCurve(to: CGPoint(x: geo.size.width, y: geo.size.height * 0.56), control: CGPoint(x: geo.size.width * 0.5, y: geo.size.height * 0.42))
                path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                path.addLine(to: CGPoint(x: 0, y: geo.size.height))
            }
            .fill(
                LinearGradient(
                    colors: isNight ?
                        [Color(red: 0.32, green: 0.54, blue: 0.28), Color(red: 0.22, green: 0.40, blue: 0.18)] :
                        [Color(red: 0.62, green: 0.88, blue: 0.52), Color(red: 0.44, green: 0.76, blue: 0.38)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .ignoresSafeArea()
            
            Path { path in
                path.move(to: CGPoint(x: 0, y: geo.size.height * 0.60))
                path.addQuadCurve(to: CGPoint(x: geo.size.width, y: geo.size.height * 0.55), control: CGPoint(x: geo.size.width * 0.42, y: geo.size.height * 0.64))
                path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                path.addLine(to: CGPoint(x: 0, y: geo.size.height))
            }
            .fill(
                LinearGradient(
                    colors: isNight ?
                        [Color(red: 0.25, green: 0.48, blue: 0.22), Color(red: 0.18, green: 0.35, blue: 0.14)] :
                        [Color(red: 0.55, green: 0.85, blue: 0.45), Color(red: 0.38, green: 0.70, blue: 0.32)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .ignoresSafeArea()

            VectorFlower(size: 26)
                .position(x: geo.size.width * 0.08, y: geo.size.height * 0.83)
            VectorFlower(size: 28)
                .position(x: geo.size.width * 0.92, y: geo.size.height * 0.86)
            VectorFlower(size: 24)
                .position(x: geo.size.width * 0.16, y: geo.size.height * 0.88)
            
            if !isNight {
                Text("🦋").font(.system(size: 26))
                    .position(x: geo.size.width * 0.14, y: geo.size.height * 0.38)
            }
        }
    }

    @ViewBuilder
    private func rainOverlay(geo: GeometryProxy, isRainy: Bool) -> some View {
        if isRainy {
            TimelineView(.animation) { context in
                let t = context.date.timeIntervalSinceReferenceDate
                GeometryReader { rainGeo in
                    ForEach(0..<15) { idx in
                        let speed = 260.0 + Double(idx % 3) * 60.0
                        let yPos = CGFloat((t * speed + Double(idx) * 64).truncatingRemainder(dividingBy: Double(rainGeo.size.height + 40))) - 20
                        let xPos = CGFloat(Double(idx) * (Double(rainGeo.size.width) / 15.0) + (t * 50).truncatingRemainder(dividingBy: 40))
                        Capsule()
                            .fill(Color(red: 0.65, green: 0.85, blue: 1.0).opacity(0.40))
                            .frame(width: 2, height: 18)
                            .rotationEffect(.degrees(12))
                            .position(x: xPos, y: yPos)
                    }
                }
            }
            .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private func menuView(geo: GeometryProxy, homeSpot: CGPoint, isNight: Bool) -> some View {
        VStack(spacing: 24) {
            ActivityHeader(title: "Hora de brincar! ⚽", onClose: onClose)
            Spacer()
            
            Text("Escolha como quer brincar:")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(isNight ? .white : Color(red: 0.2, green: 0.35, blue: 0.15))
            
            HStack(spacing: 36) {
                Button {
                    Haptics.tap()
                    AudioManager.shared.play(.pop)
                    mode = .catchBall
                    petPos = homeSpot
                    ballPos = CGPoint(x: geo.size.width * 0.65, y: geo.size.height * 0.62)
                    pose = .sit
                    phase = .ready
                    facing = 1
                    catches = 0
                } label: {
                    VStack(spacing: 12) {
                        Text("⚽")
                            .font(.system(size: 56))
                            .frame(width: 100, height: 100)
                            .background(Circle().fill(.white))
                            .shadow(color: .black.opacity(0.1), radius: 5)
                        Text("Jogar Bola")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 0.3, green: 0.2, blue: 0.15))
                    }
                    .padding(18)
                    .background(RoundedRectangle(cornerRadius: 22).fill(.white.opacity(0.7)))
                    .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white, lineWidth: 2))
                }
                .buttonStyle(SquishyButtonStyle())

                Button {
                    Haptics.tap()
                    AudioManager.shared.play(.pop)
                    mode = .jumpGame
                    petPos = homeSpot
                    pose = .run
                    jumpScore = 0
                    earnedCoinsThisSession = 0
                    isGameOver = false
                    petJumpY = 0
                    isGrounded = true
                    obstacleX = geo.size.width + 50
                } label: {
                    VStack(spacing: 12) {
                        Text("🏃")
                            .font(.system(size: 56))
                            .frame(width: 100, height: 100)
                            .background(Circle().fill(.white))
                            .shadow(color: .black.opacity(0.1), radius: 5)
                        VStack(spacing: 2) {
                            Text("Pulo do Pet")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(red: 0.3, green: 0.2, blue: 0.15))
                            Text("Ganhe moedas! 🪙")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(.orange)
                        }
                    }
                    .padding(18)
                    .background(RoundedRectangle(cornerRadius: 22).fill(.white.opacity(0.7)))
                    .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white, lineWidth: 2))
                }
                .buttonStyle(SquishyButtonStyle())
            }
            
            Spacer()
        }
    }

    @ViewBuilder
    private func catchBallView(geo: GeometryProxy, homeSpot: CGPoint) -> some View {
        ZStack {
            if ready, let pet = vm.pet {
                PetCharacterView(species: pet.species, pose: pose, facing: facing, size: 140, accessory: pet.equippedAccessory, mood: pet.mood)
                    .position(petPos)

                VectorBall()
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

            VStack {
                HStack {
                    Button {
                        Haptics.tap()
                        AudioManager.shared.play(.pop)
                        mode = .menu
                    } label: {
                        HStack(spacing: 4) {
                            Text("⬅️").font(.system(size: 16))
                            Text("Voltar ao Menu")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(.white.opacity(0.85)))
                        .foregroundStyle(Color(red: 0.3, green: 0.2, blue: 0.15))
                    }
                    .buttonStyle(SquishyButtonStyle())
                    .padding(.leading, 16)
                    .padding(.top, 14)
                    
                    Spacer()
                    
                    Text(statusText)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 0.2, green: 0.4, blue: 0.2))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(.white.opacity(0.8)))
                        .padding(.top, 14)
                    
                    Spacer()

                    HStack(spacing: 4) {
                        Text("🎾").font(.system(size: 16))
                        Text("Buscas: \(catches)")
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color(red: 0.2, green: 0.4, blue: 0.2))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(.white.opacity(0.8)))
                    .padding(.trailing, 16)
                    .padding(.top, 14)
                }
                
                Spacer()
                HStack {
                    StatBar(icon: "⚽", value: vm.pet?.fun ?? 0, color: .green)
                    Spacer()
                    .padding(.leading, 16)
                    .padding(.bottom, 12)
                }
            }
        }
    }

    @ViewBuilder
    private func jumpGameView(geo: GeometryProxy, homeSpot: CGPoint) -> some View {
        ZStack {
            let petX = geo.size.width * 0.25
            let obstacleGroundY = geo.size.height * 0.68
            
            ZStack {
                if let pet = vm.pet {
                    PetCharacterView(species: pet.species, pose: isGameOver ? .sleep : pose, size: 140, accessory: pet.equippedAccessory, mood: pet.mood)
                        .rotationEffect(.degrees(isGameOver ? -90 : 0))
                        .position(x: petX, y: homeSpot.y + petJumpY)
                }

                if !isGameOver {
                    ZStack {
                        Ellipse()
                            .fill(.black.opacity(0.12))
                            .frame(width: 48, height: 6)
                            .offset(y: 16)
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.60, green: 0.38, blue: 0.20), Color(red: 0.45, green: 0.25, blue: 0.12)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 48, height: 30)
                        
                        Rectangle()
                            .fill(Color(red: 0.85, green: 0.60, blue: 0.45).opacity(0.6))
                            .frame(width: 48, height: 3.5)
                            .offset(y: -4)
                    }
                    .position(x: obstacleX, y: obstacleGroundY)
                }
                
                if isGameOver {
                    VStack(spacing: 12) {
                        Text("Fim de Jogo! 💥")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundStyle(.red)
                        
                        Text("Você ganhou 🪙 \(earnedCoinsThisSession) moedas!")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 0.3, green: 0.2, blue: 0.1))
                        
                        Button {
                            Haptics.tap()
                            AudioManager.shared.play(.pop)
                            jumpScore = 0
                            earnedCoinsThisSession = 0
                            isGameOver = false
                            pose = .run
                            obstacleX = geo.size.width + 50
                            petJumpY = 0
                            isGrounded = true
                        } label: {
                            Text("Jogar de novo 🔁")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(.orange))
                        }
                        .buttonStyle(SquishyButtonStyle())
                    }
                    .padding(20)
                    .background(RoundedRectangle(cornerRadius: 22).fill(.white.opacity(0.92)))
                    .shadow(radius: 6)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                triggerJump()
            }
            .onReceive(gameTimer) { _ in
                guard !isGameOver else { return }
                
                let speed = 280.0 + Double(jumpScore) * 15.0
                obstacleX -= CGFloat(speed / 60.0)
                
                if obstacleX < -50 {
                    obstacleX = geo.size.width + 50
                    jumpScore += 1
                    earnedCoinsThisSession += 2
                    vm.play()
                    AudioManager.shared.play(.pop)
                }
                
                let dist = abs(obstacleX - petX)
                if dist < 40 && petJumpY > -40 {
                    isGameOver = true
                    Haptics.error()
                    AudioManager.shared.play(.chime)
                    particles.burst(["💥", "💨", "🍂"], at: CGPoint(x: petX, y: obstacleGroundY), count: 6)
                    
                    if earnedCoinsThisSession > 0, var p = vm.pet {
                        p.coins += earnedCoinsThisSession
                        vm.pet = p
                        vm.save()
                    }
                }
            }
            
            // HUD Overlay para Pulo do Pet
            VStack {
                HStack {
                    Button {
                        Haptics.tap()
                        AudioManager.shared.play(.pop)
                        mode = .menu
                    } label: {
                        HStack(spacing: 4) {
                            Text("⬅️").font(.system(size: 16))
                            Text("Menu")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(.white.opacity(0.85)))
                        .foregroundStyle(Color(red: 0.3, green: 0.2, blue: 0.15))
                    }
                    .buttonStyle(SquishyButtonStyle())
                    .padding(.leading, 16)
                    .padding(.top, 14)
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Text("Score: \(jumpScore)")
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color(red: 0.45, green: 0.25, blue: 0.15))
                        Text("🪙 +\(earnedCoinsThisSession)")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(.orange)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(.white.opacity(0.85)))
                    .padding(.trailing, 16)
                    .padding(.top, 14)
                }
                
                Spacer()
                HStack {
                    StatBar(icon: "⚽", value: vm.pet?.fun ?? 0, color: .green)
                    Spacer()
                }
                .padding(.leading, 16)
                .padding(.bottom, 12)
            }
        }
    }

    // MARK: - Métodos Auxiliares de Controle

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

    private func triggerJump() {
        guard isGrounded && !isGameOver else { return }
        isGrounded = false
        AudioManager.shared.play(.boing)
        pose = .happy
        withAnimation(.easeOut(duration: 0.32)) {
            petJumpY = -110
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            pose = .run
            withAnimation(.easeIn(duration: 0.32)) {
                petJumpY = 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.64) {
            isGrounded = true
        }
    }

    private func throwBall(predicted: CGPoint, in size: CGSize, homeSpot: CGPoint) {
        phase = .chasing
        Haptics.tap()
        AudioManager.shared.play(.boing)

        let landing = clamp(predicted, in: size)
        withAnimation(.spring(response: 0.55, dampingFraction: 0.55)) {
            ballPos = landing
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            let side: CGFloat = landing.x >= petPos.x ? -1 : 1
            let chaseSpot = CGPoint(x: landing.x + 60 * side, y: landing.y - 20)
            facing = landing.x >= petPos.x ? 1 : -1
            pose = .run
            let distance = hypot(chaseSpot.x - petPos.x, chaseSpot.y - petPos.y)
            let chaseTime = max(0.45, Double(distance / 280))
            withAnimation(.easeInOut(duration: chaseTime)) { petPos = chaseSpot }

            DispatchQueue.main.asyncAfter(deadline: .now() + chaseTime) {
                catches += 1
                vm.play()
                Haptics.success()
                AudioManager.shared.play(.chime)
                particles.burst(["⭐", "💛", "🎉"], at: landing, count: 8)
                pose = .happy

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

// MARK: - Bola Vetorial em SwiftUI

struct VectorBall: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(.white)
                .frame(width: 52, height: 52)
                .shadow(color: .black.opacity(0.18), radius: 4, y: 3)
            
            Circle()
                .stroke(Color(red: 0.20, green: 0.20, blue: 0.22), lineWidth: 3.5)
                .frame(width: 52, height: 52)
            
            Group {
                StarShape()
                    .fill(Color(red: 0.18, green: 0.18, blue: 0.20))
                    .frame(width: 14, height: 14)
                
                ForEach(0..<5) { i in
                    Path { path in
                        path.move(to: CGPoint(x: 26, y: 26))
                        let angle = CGFloat(i) * (2 * CGFloat.pi / 5) - CGFloat.pi / 2
                        let x1 = 26 + 14 * cos(angle - 0.2)
                        let y1 = 26 + 14 * sin(angle - 0.2)
                        let x2 = 26 + 26 * cos(angle - 0.3)
                        let y2 = 26 + 26 * sin(angle - 0.3)
                        let x3 = 26 + 26 * cos(angle + 0.3)
                        let y3 = 26 + 26 * sin(angle + 0.3)
                        let x4 = 26 + 14 * cos(angle + 0.2)
                        let y4 = 26 + 14 * sin(angle + 0.2)
                        
                        path.move(to: CGPoint(x: x1, y: y1))
                        path.addLine(to: CGPoint(x: x2, y: y2))
                        path.addLine(to: CGPoint(x: x3, y: y3))
                        path.addLine(to: CGPoint(x: x4, y: y4))
                        path.closeSubpath()
                    }
                    .fill(Color(red: 0.18, green: 0.18, blue: 0.20))
                }
            }
            .clipShape(Circle())
        }
        .frame(width: 52, height: 52)
    }
}
