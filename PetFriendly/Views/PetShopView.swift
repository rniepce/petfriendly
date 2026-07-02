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

    /// Toldo listrado do petshop.
    private var awning: some View {
        HStack(spacing: 0) {
            ForEach(0..<10, id: \.self) { index in
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 14,
                    bottomTrailingRadius: 14,
                    topTrailingRadius: 0
                )
                .fill(index.isMultiple(of: 2) ? Color(red: 0.95, green: 0.35, blue: 0.4) : .white)
                .frame(height: 30)
            }
        }
        .ignoresSafeArea(edges: .top)
        .shadow(color: .black.opacity(0.1), radius: 4, y: 3)
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
                        .fill(LinearGradient(colors: species.themeColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 82, height: 82)
                    Text(species.emoji)
                        .font(.system(size: 50))
                }
                Text(species.displayName)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.45, green: 0.3, blue: 0.2))
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(.white.opacity(isSelected ? 1 : 0.65))
                    .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(isSelected ? Color(red: 0.95, green: 0.4, blue: 0.5) : .clear, lineWidth: 3)
            )
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Text("💖")
                        .font(.system(size: 22))
                        .offset(x: 7, y: -7)
                }
            }
            .scaleEffect(isSelected ? 1.06 : 1)
        }
        .buttonStyle(SquishyButtonStyle())
    }
}
