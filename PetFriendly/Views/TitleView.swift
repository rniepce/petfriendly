import SwiftUI

struct TitleView: View {
    @EnvironmentObject var vm: GameViewModel
    @State private var bounce = false

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
                    .position(x: geo.size.width * 0.08, y: geo.size.height * 0.75)
            }
            .allowsHitTesting(false)

            VStack(spacing: 14) {
                Text("🐾 PetFriendly 🐾")
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(red: 0.45, green: 0.30, blue: 0.20))
                    .shadow(color: .white.opacity(0.8), radius: 2, y: 2)

                Text("Cuide do seu bichinho de estimação!")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(red: 0.45, green: 0.35, blue: 0.28))

                HStack(spacing: 16) {
                    ForEach(Array(PetSpecies.allCases.enumerated()), id: \.element) { index, species in
                        Text(species.emoji)
                            .font(.system(size: 44))
                            .offset(y: bounce ? -10 : 6)
                            .animation(
                                .easeInOut(duration: 0.7)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.12),
                                value: bounce
                            )
                    }
                }
                .padding(.vertical, 6)

                if let pet = vm.pet {
                    BigPillButton(title: "Continuar com \(pet.name) 🏠") {
                        vm.goHome()
                    }
                    Button {
                        Haptics.tap()
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
        }
        .onAppear { bounce = true }
    }
}
