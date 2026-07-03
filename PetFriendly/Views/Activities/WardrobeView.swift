import SwiftUI

struct WardrobeView: View {
    @EnvironmentObject var vm: GameViewModel
    let onClose: () -> Void

    private struct AccessoryItem {
        let emoji: String
        let name: String
        let price: Int
    }

    private let items = [
        AccessoryItem(emoji: "🎩", name: "Cartola Estilosa", price: 30),
        AccessoryItem(emoji: "🕶️", name: "Óculos Modernos", price: 25),
        AccessoryItem(emoji: "🎀", name: "Laço Charmoso", price: 20),
        AccessoryItem(emoji: "👑", name: "Coroa Imperial", price: 50)
    ]

    @State private var previewAccessory: String?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Fundo degradê lilás/roxo pastel para guardar-roupa
                LinearGradient(
                    colors: [Color(red: 0.90, green: 0.85, blue: 0.98), Color(red: 0.78, green: 0.70, blue: 0.92)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 8) {
                    ActivityHeader(title: "Guarda-Roupa 👑", onClose: onClose)

                    if let pet = vm.pet {
                        // Preview do Pet
                        ZStack {
                            // Glow/Luz de fundo
                            Circle()
                                .fill(Color.white.opacity(0.35))
                                .frame(width: 220, height: 220)
                                .blur(radius: 10)

                            PetCharacterView(
                                species: pet.species,
                                pose: .idle,
                                size: 190,
                                accessory: previewAccessory ?? pet.equippedAccessory,
                                mood: vm.pet?.mood ?? .happy
                            )
                            .offset(y: -10)
                        }
                        .frame(height: 200)

                        // Saldo de Moedas
                        HStack {
                            Text("🪙 Moedas:")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(red: 0.35, green: 0.25, blue: 0.15))
                            Text("\(pet.coins)")
                                .font(.system(size: 20, weight: .black, design: .rounded))
                                .foregroundStyle(Color(red: 0.95, green: 0.65, blue: 0.15))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(.white.opacity(0.8)))
                        .shadow(color: .black.opacity(0.06), radius: 3)

                        // Lista de itens do guarda-roupa
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                // Botão para remover acessório
                                Button {
                                    Haptics.tap()
                                    AudioManager.shared.play(.pop)
                                    previewAccessory = nil
                                    vm.equipAccessory(nil)
                                } label: {
                                    VStack(spacing: 6) {
                                        Text("❌")
                                            .font(.system(size: 32))
                                            .frame(width: 80, height: 80)
                                            .background(Circle().fill(.white.opacity(0.8)))
                                            .overlay(Circle().stroke(previewAccessory == nil ? Color.purple : Color.clear, lineWidth: 3))
                                        Text("Nenhum")
                                            .font(.system(size: 13, weight: .bold, design: .rounded))
                                            .foregroundStyle(Color(red: 0.35, green: 0.25, blue: 0.15))
                                    }
                                    .padding(10)
                                    .background(RoundedRectangle(cornerRadius: 18).fill(.white.opacity(0.4)))
                                }
                                .buttonStyle(SquishyButtonStyle())

                                // Lista de acessórios reais
                                ForEach(items, id: \.emoji) { item in
                                    let hasBought = pet.purchasedAccessories.contains(item.emoji)
                                    let isEquipped = pet.equippedAccessory == item.emoji

                                    Button {
                                        Haptics.tap()
                                        AudioManager.shared.play(.pop)
                                        previewAccessory = item.emoji
                                        
                                        if hasBought {
                                            vm.equipAccessory(item.emoji)
                                        } else if pet.coins >= item.price {
                                            vm.buyAccessory(item.emoji, price: item.price)
                                        }
                                    } label: {
                                        VStack(spacing: 6) {
                                            Text(item.emoji)
                                                .font(.system(size: 36))
                                                .frame(width: 80, height: 80)
                                                .background(Circle().fill(.white.opacity(0.85)))
                                                .overlay(
                                                    Circle().stroke(previewAccessory == item.emoji ? Color.purple : Color.clear, lineWidth: 3)
                                                )

                                            if isEquipped {
                                                Text("Equipado")
                                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                                    .foregroundStyle(.purple)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 3)
                                                    .background(Capsule().fill(.purple.opacity(0.12)))
                                            } else if hasBought {
                                                Text("Equipar")
                                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                                    .foregroundStyle(Color(red: 0.35, green: 0.25, blue: 0.15))
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 3)
                                                    .background(Capsule().fill(.white.opacity(0.7)))
                                            } else {
                                                // Botão de compra
                                                HStack(spacing: 3) {
                                                    Text("🪙")
                                                        .font(.system(size: 11))
                                                    Text("\(item.price)")
                                                        .font(.system(size: 12, weight: .black, design: .rounded))
                                                }
                                                .foregroundStyle(.white)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(
                                                    Capsule().fill(pet.coins >= item.price ? Color.orange : Color.gray)
                                                )
                                            }
                                        }
                                        .padding(10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 18)
                                                .fill(.white.opacity(previewAccessory == item.emoji ? 0.6 : 0.4))
                                        )
                                    }
                                    .buttonStyle(SquishyButtonStyle())
                                    .disabled(!hasBought && pet.coins < item.price)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                        }
                    }
                    Spacer()
                }
            }
            .onAppear {
                previewAccessory = vm.pet?.equippedAccessory
            }
        }
    }
}
