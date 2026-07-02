import SwiftUI

struct TitleView: View {
    @EnvironmentObject var vm: GameViewModel
    @ObservedObject private var audio = AudioManager.shared

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.55, green: 0.80, blue: 1.0), Color(red: 0.88, green: 0.96, blue: 1.0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            GeometryReader { geo in
                Text("☀️")
                    .font(.system(size: 60))
                    .position(x: geo.size.width * 0.9, y: geo.size.height * 0.15)
                Text("☁️")
                    .font(.system(size: 50))
                    .position(x: geo.size.width * 0.15, y: geo.size.height * 0.18)
                Text("☁️")
                    .font(.system(size: 36))
                    .position(x: geo.size.width * 0.35, y: geo.size.height * 0.1)
                Text("🌈")
                    .font(.system(size: 54))
                    .position(x: geo.size.width * 0.08, y: geo.size.height * 0.55)

                // graminha
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.60, green: 0.87, blue: 0.50), Color(red: 0.45, green: 0.76, blue: 0.40)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: geo.size.height * 0.16)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.95)
            }
            .allowsHitTesting(false)
            .ignoresSafeArea()

            // desfile de pets andando na graminha
            TimelineView(.animation) { context in
                let t = context.date.timeIntervalSinceReferenceDate
                GeometryReader { geo in
                    let span = Double(geo.size.width) + 520
                    ForEach(Array(PetSpecies.allCases.enumerated()), id: \.element) { index, species in
                        let x = CGFloat((t * 55 + Double(index) * 95).truncatingRemainder(dividingBy: span)) - 260
                        PetCharacterView(species: species, pose: .walk, facing: 1, size: 92)
                            .position(x: x, y: geo.size.height * 0.83)
                    }
                }
            }
            .allowsHitTesting(false)
            .ignoresSafeArea()

            VStack(spacing: 14) {
                Text("🐾 PetFriendly 🐾")
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(red: 0.45, green: 0.30, blue: 0.20))
                    .shadow(color: .white.opacity(0.8), radius: 2, y: 2)

                Text("Cuide do seu bichinho de estimação!")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(red: 0.45, green: 0.35, blue: 0.28))

                if let pet = vm.pet {
                    BigPillButton(title: "Continuar com \(pet.name) 🏠") {
                        vm.goHome()
                    }
                    Button {
                        Haptics.tap()
                        AudioManager.shared.play(.pop)
                        vm.releasePetAndShop()
                    } label: {
                        Text("Adotar outro pet 🏪")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 0.35, green: 0.45, blue: 0.65))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(.white.opacity(0.7)))
                    }
                    .buttonStyle(SquishyButtonStyle())
                } else {
                    BigPillButton(title: "Começar! 🏪") {
                        vm.goToShop()
                    }
                }
            }
            .offset(y: -20)

            // botão de música no cantinho
            VStack {
                HStack {
                    Spacer()
                    Button {
                        Haptics.tap()
                        audio.musicOn.toggle()
                    } label: {
                        Text(audio.musicOn ? "🎵" : "🔕")
                            .font(.system(size: 20))
                            .padding(9)
                            .background(Circle().fill(.white.opacity(0.75)))
                    }
                    .buttonStyle(SquishyButtonStyle())
                }
                .padding(.trailing, 16)
                .padding(.top, 10)
                Spacer()
            }
        }
    }
}
