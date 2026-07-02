import SwiftUI

struct PetShopView: View {
    @EnvironmentObject var vm: GameViewModel
    @State private var selected: PetSpecies?
    @State private var name: String = ""

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 1.0, green: 0.95, blue: 0.85), Color(red: 1.0, green: 0.87, blue: 0.72)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Elementos flutuantes decorativos de fundo
            GeometryReader { geo in
                ZStack {
                    VectorStar(size: 20, delay: 0)
                        .position(x: geo.size.width * 0.12, y: geo.size.height * 0.35)
                        .opacity(0.35)
                    VectorStar(size: 16, delay: 1.5)
                        .position(x: geo.size.width * 0.88, y: geo.size.height * 0.45)
                        .opacity(0.3)
                    VectorStar(size: 24, delay: 3.0)
                        .position(x: geo.size.width * 0.78, y: geo.size.height * 0.18)
                        .opacity(0.35)
                    
                    // Bolinhas decorativas pastel
                    Circle()
                        .fill(Color(red: 0.95, green: 0.55, blue: 0.6).opacity(0.12))
                        .frame(width: 80)
                        .position(x: geo.size.width * 0.08, y: geo.size.height * 0.78)
                    Circle()
                        .fill(Color(red: 0.55, green: 0.75, blue: 0.95).opacity(0.1))
                        .frame(width: 120)
                        .position(x: geo.size.width * 0.92, y: geo.size.height * 0.82)
                }
            }
            .allowsHitTesting(false)

            VStack(spacing: 8) {
                awning

                Text("🏪 Bem-vindo ao Petshop!")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(red: 0.5, green: 0.3, blue: 0.15))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(PetSpecies.allCases) { species in
                            PetCard(species: species, isSelected: selected == species) {
                                Haptics.tap()
                                AudioManager.shared.play(.boing)
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                    selected = species
                                    name = species.suggestedNames.first ?? ""
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 6)
                }

                if let species = selected {
                    namePanel(for: species)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    Text("Toque em um bichinho para conhecer! 👆")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(red: 0.6, green: 0.45, blue: 0.3))
                        .padding(.bottom, 10)
                }

                Spacer(minLength: 0)
            }
        }
    }

    /// Toldo listrado 3D do petshop com sombras cilíndricas.
    private var awning: some View {
        VStack(spacing: 0) {
            // Barra suporte de madeira
            Rectangle()
                .fill(Color(red: 0.60, green: 0.42, blue: 0.28))
                .frame(height: 8)
            
            HStack(spacing: 0) {
                ForEach(0..<12, id: \.self) { index in
                    ZStack {
                        UnevenRoundedRectangle(
                            topLeadingRadius: 0,
                            bottomLeadingRadius: 16,
                            bottomTrailingRadius: 16,
                            topTrailingRadius: 0
                        )
                        .fill(index.isMultiple(of: 2) ? Color(red: 0.95, green: 0.35, blue: 0.4) : .white)
                        
                        // Sombra lateral interna para criar efeito 3D de dobras de tecido
                        LinearGradient(
                            colors: [.black.opacity(0.14), .clear, .black.opacity(0.14)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .clipShape(
                            UnevenRoundedRectangle(
                                topLeadingRadius: 0,
                                bottomLeadingRadius: 16,
                                bottomTrailingRadius: 16,
                                topTrailingRadius: 0
                            )
                        )
                    }
                    .frame(height: 40)
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .shadow(color: .black.opacity(0.16), radius: 5, y: 4)
    }

    private func namePanel(for species: PetSpecies) -> some View {
        VStack(spacing: 8) {
            Text("Qual será o nome do seu \(species.displayName.lowercased())? \(species.emoji)")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.5, green: 0.3, blue: 0.15))

            HStack(spacing: 8) {
                ForEach(species.suggestedNames, id: \.self) { suggestion in
                    Button {
                        Haptics.tap()
                        AudioManager.shared.play(.pop)
                        name = suggestion
                    } label: {
                        Text(suggestion)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(name == suggestion ? .white : Color(red: 0.5, green: 0.3, blue: 0.15))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                Capsule().fill(name == suggestion ? Color(red: 0.95, green: 0.4, blue: 0.5) : .white.opacity(0.9))
                            )
                    }
                    .buttonStyle(SquishyButtonStyle())
                }

                TextField("Outro nome...", text: $name)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .frame(width: 140)
                    .background(Capsule().fill(.white))
            }

            BigPillButton(title: "Levar \(trimmedName.isEmpty ? species.displayName : trimmedName) para casa! 🏡") {
                guard !trimmedName.isEmpty else { return }
                Haptics.success()
                AudioManager.shared.play(.chime)
                vm.adopt(species: species, name: trimmedName)
            }
            .opacity(trimmedName.isEmpty ? 0.5 : 1)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(.white.opacity(0.75))
                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        )
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
    }
}

private struct PetCard: View {
    let species: PetSpecies
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: species.themeColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 96, height: 96)
                        .shadow(color: species.themeColors[1].opacity(0.4), radius: 6, x: 0, y: 4)
                    
                    // o bichinho animado
                    PetCharacterView(species: species, pose: isSelected ? .happy : .idle, size: 88)
                        .offset(y: -3)
                }
                
                Text(species.displayName)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(red: 0.42, green: 0.26, blue: 0.12))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.white.opacity(isSelected ? 1.0 : 0.60))
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(.ultraThinMaterial)
                    )
                    .shadow(color: .black.opacity(isSelected ? 0.12 : 0.06), radius: isSelected ? 10 : 5, y: 4)
            )
            .overlay(
                // Borda degradê dupla quando selecionado
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: isSelected ? [Color(red: 0.95, green: 0.4, blue: 0.5), Color(red: 1.0, green: 0.65, blue: 0.75)] : [.white.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isSelected ? 3.5 : 1.5
                    )
            )
            .overlay(
                // Brilho vítreo (sheen)
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.white.opacity(0.22), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                }
                .allowsHitTesting(false)
            )
            .scaleEffect(isSelected ? 1.06 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: isSelected)
        }
        .buttonStyle(SquishyButtonStyle())
    }
}
