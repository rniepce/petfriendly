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
    @StateObject private var particles = ParticleSystem()
    @State private var activity: Activity?
    @State private var showShopConfirm = false
    @State private var petSquish = false

    private let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                RoomBackground()

                if let pet = vm.pet {
                    petArea(pet: pet, geo: geo)
                    hud(pet: pet)
                }

                ParticleField(system: particles)

                if activity != nil {
                    activityOverlay
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(2)
                }
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

    // MARK: - Pet no meio do quarto

    private func petArea(pet: Pet, geo: GeometryProxy) -> some View {
        VStack(spacing: 10) {
            if let hint = pet.needHint {
                SpeechBubble(text: hint)
            } else if pet.mood == .happy {
                Text(["😄", "💖", "🎵"].randomElement() ?? "💖")
                    .font(.system(size: 22))
                    .opacity(0.9)
            }

            PetSpriteView(species: pet.species, size: 150)
                .scaleEffect(petSquish ? 1.12 : 1)
                .onTapGesture {
                    Haptics.tap()
                    particles.burst(["💖", "💕", "✨"], at: CGPoint(x: geo.size.width * 0.5, y: geo.size.height * 0.45), count: 6)
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.4)) { petSquish = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { petSquish = false }
                    }
                }

            Text(pet.name)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color(red: 0.95, green: 0.55, blue: 0.45).opacity(0.9)))
        }
        .position(x: geo.size.width * 0.5, y: geo.size.height * 0.52)
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
                    showShopConfirm = true
                } label: {
                    Text("🏪")
                        .font(.system(size: 20))
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

                // tapete embaixo do pet
                Ellipse()
                    .fill(Color(red: 0.98, green: 0.7, blue: 0.65).opacity(0.6))
                    .frame(width: geo.size.width * 0.34, height: 66)
                    .position(x: geo.size.width * 0.5, y: geo.size.height * 0.74)

                Text("🪴")
                    .font(.system(size: 46))
                    .position(x: geo.size.width * 0.86, y: geo.size.height * 0.6)
                Text("🖼️")
                    .font(.system(size: 40))
                    .position(x: geo.size.width * 0.76, y: geo.size.height * 0.22)
                Text("🧸")
                    .font(.system(size: 34))
                    .position(x: geo.size.width * 0.12, y: geo.size.height * 0.72)
            }
        }
        .ignoresSafeArea()
    }
}
