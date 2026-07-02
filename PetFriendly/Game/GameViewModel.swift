import SwiftUI

enum Screen {
    case title
    case shop
    case home
}

@MainActor
final class GameViewModel: ObservableObject {
    @Published var pet: Pet?
    @Published var screen: Screen = .title

    private static let saveKey = "petfriendly.pet"
    private var ticksSinceSave = 0

    init() {
        load()
    }

    // MARK: - Navegação

    func goToShop() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { screen = .shop }
    }

    func goHome() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { screen = .home }
    }

    func adopt(species: PetSpecies, name: String) {
        pet = Pet(name: name, species: species)
        save()
        goHome()
    }

    /// Volta ao petshop para adotar outro bichinho.
    func releasePetAndShop() {
        pet = nil
        save()
        goToShop()
    }

    // MARK: - Passagem do tempo

    /// Chamado a cada 2 segundos enquanto o pet está em casa.
    func tick() {
        guard var p = pet else { return }
        p.hunger = max(0, p.hunger - 0.008)
        p.hygiene = max(0, p.hygiene - 0.005)
        p.fun = max(0, p.fun - 0.009)
        p.energy = max(0, p.energy - 0.004)
        pet = p

        ticksSinceSave += 1
        if ticksSinceSave >= 10 {
            ticksSinceSave = 0
            save()
        }
    }

    // MARK: - Cuidados

    func feed() {
        boost(\.hunger, by: 0.22)
    }

    func play() {
        boost(\.fun, by: 0.2)
    }

    func rest(_ amount: Double) {
        boost(\.energy, by: amount)
    }

    func bathe() {
        guard var p = pet else { return }
        if p.hygiene < 0.99 { p.stars += 1 }
        p.hygiene = 1
        pet = p
        save()
    }

    /// Aumenta um medidor; ganha uma estrela quando ele fica cheio.
    private func boost(_ keyPath: WritableKeyPath<Pet, Double>, by amount: Double) {
        guard var p = pet else { return }
        let old = p[keyPath: keyPath]
        let new = min(1, old + amount)
        p[keyPath: keyPath] = new
        if old < 0.99 && new >= 0.99 {
            p.stars += 1
        }
        pet = p
        save()
    }

    // MARK: - Persistência

    func save() {
        if let pet, let data = try? JSONEncoder().encode(pet) {
            UserDefaults.standard.set(data, forKey: Self.saveKey)
        } else {
            UserDefaults.standard.removeObject(forKey: Self.saveKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.saveKey),
              let saved = try? JSONDecoder().decode(Pet.self, from: data) else { return }
        pet = saved
    }
}
