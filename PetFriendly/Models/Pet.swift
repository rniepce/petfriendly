import SwiftUI

/// As espécies disponíveis no petshop.
enum PetSpecies: String, CaseIterable, Codable, Identifiable {
    case dog
    case cat
    case rabbit
    case hamster
    case parrot
    case unicorn

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .dog: return "🐶"
        case .cat: return "🐱"
        case .rabbit: return "🐰"
        case .hamster: return "🐹"
        case .parrot: return "🦜"
        case .unicorn: return "🦄"
        }
    }

    var displayName: String {
        switch self {
        case .dog: return "Cachorrinho"
        case .cat: return "Gatinho"
        case .rabbit: return "Coelhinho"
        case .hamster: return "Hamster"
        case .parrot: return "Papagaio"
        case .unicorn: return "Unicórnio"
        }
    }

    /// Comida preferida, usada na atividade de alimentação.
    var favoriteFood: String {
        switch self {
        case .dog: return "🦴"
        case .cat: return "🐟"
        case .rabbit: return "🥕"
        case .hamster: return "🌻"
        case .parrot: return "🥭"
        case .unicorn: return "🧁"
        }
    }

    /// Cores do cartão no petshop.
    var themeColors: [Color] {
        switch self {
        case .dog: return [Color(red: 1.0, green: 0.80, blue: 0.45), Color(red: 1.0, green: 0.62, blue: 0.30)]
        case .cat: return [Color(red: 0.75, green: 0.85, blue: 1.0), Color(red: 0.55, green: 0.70, blue: 1.0)]
        case .rabbit: return [Color(red: 1.0, green: 0.80, blue: 0.90), Color(red: 1.0, green: 0.60, blue: 0.78)]
        case .hamster: return [Color(red: 1.0, green: 0.90, blue: 0.60), Color(red: 0.98, green: 0.75, blue: 0.35)]
        case .parrot: return [Color(red: 0.65, green: 0.92, blue: 0.70), Color(red: 0.35, green: 0.78, blue: 0.50)]
        case .unicorn: return [Color(red: 0.90, green: 0.80, blue: 1.0), Color(red: 0.75, green: 0.58, blue: 0.98)]
        }
    }

    var suggestedNames: [String] {
        switch self {
        case .dog: return ["Bolinha", "Pipoca", "Totó", "Mel"]
        case .cat: return ["Mimi", "Luna", "Nina", "Frajola"]
        case .rabbit: return ["Fofinho", "Algodão", "Pulinho", "Cenoura"]
        case .hamster: return ["Biscoito", "Nozes", "Pituco", "Tico"]
        case .parrot: return ["Loro", "Azulão", "Piu-Piu", "Curió"]
        case .unicorn: return ["Estrela", "Arco-Íris", "Brilho", "Nuvem"]
        }
    }
}

/// Cores usadas para desenhar o corpo de cada espécie.
struct PetPalette {
    let body: Color
    let bodyDark: Color
    let belly: Color
    let earInner: Color
}

extension PetSpecies {
    var palette: PetPalette {
        switch self {
        case .dog:
            return PetPalette(
                body: Color(red: 0.87, green: 0.65, blue: 0.42),
                bodyDark: Color(red: 0.62, green: 0.42, blue: 0.26),
                belly: Color(red: 0.98, green: 0.90, blue: 0.76),
                earInner: Color(red: 0.98, green: 0.75, blue: 0.70)
            )
        case .cat:
            return PetPalette(
                body: Color(red: 0.95, green: 0.62, blue: 0.32),
                bodyDark: Color(red: 0.78, green: 0.45, blue: 0.20),
                belly: Color(red: 1.0, green: 0.92, blue: 0.80),
                earInner: Color(red: 1.0, green: 0.72, blue: 0.70)
            )
        case .rabbit:
            return PetPalette(
                body: Color(red: 0.93, green: 0.90, blue: 0.92),
                bodyDark: Color(red: 0.78, green: 0.72, blue: 0.76),
                belly: Color(red: 1.0, green: 0.97, blue: 0.97),
                earInner: Color(red: 1.0, green: 0.70, blue: 0.78)
            )
        case .hamster:
            return PetPalette(
                body: Color(red: 0.96, green: 0.74, blue: 0.38),
                bodyDark: Color(red: 0.80, green: 0.56, blue: 0.24),
                belly: Color(red: 1.0, green: 0.94, blue: 0.80),
                earInner: Color(red: 1.0, green: 0.78, blue: 0.72)
            )
        case .parrot:
            return PetPalette(
                body: Color(red: 0.30, green: 0.72, blue: 0.35),
                bodyDark: Color(red: 0.20, green: 0.55, blue: 0.28),
                belly: Color(red: 0.75, green: 0.90, blue: 0.55),
                earInner: Color(red: 1.0, green: 0.78, blue: 0.72)
            )
        case .unicorn:
            return PetPalette(
                body: Color(red: 0.97, green: 0.94, blue: 1.0),
                bodyDark: Color(red: 0.82, green: 0.75, blue: 0.95),
                belly: Color(red: 1.0, green: 0.90, blue: 0.96),
                earInner: Color(red: 1.0, green: 0.72, blue: 0.85)
            )
        }
    }
}

enum Mood {
    case happy
    case ok
    case sad
    case verySad
}

enum TimeOfDay: String, Codable, CaseIterable {
    case day
    case night
}

enum Weather: String, Codable, CaseIterable {
    case sunny
    case rainy
}

/// O bichinho adotado e seus medidores (0 = precisando de cuidado, 1 = ótimo).
struct Pet: Codable {
    var name: String
    var species: PetSpecies
    var hunger: Double = 0.7
    var hygiene: Double = 0.7
    var fun: Double = 0.7
    var energy: Double = 0.8
    var stars: Int = 0
    
    // Clima e Hora do Dia
    var timeOfDay: TimeOfDay = .day
    var weather: Weather = .sunny
    
    // Moedas e Customização
    var coins: Int = 100
    var purchasedAccessories: [String] = []
    var equippedAccessory: String? = nil
    
    // Progressão e Decaimento
    var level: Int = 1
    var xp: Int = 0
    var lastAccessDate: Date = Date()
}

extension Pet {
    var average: Double { (hunger + hygiene + fun + energy) / 4 }

    var mood: Mood {
        if average > 0.6 && hunger > 0.3 { return .happy }
        if average > 0.35 && hunger > 0.15 { return .ok }
        if average > 0.15 && hunger > 0.05 { return .sad }
        return .verySad
    }

    /// Dica falada pelo pet quando algum medidor está baixo.
    var needHint: String? {
        if hunger < 0.35 { return "Estou com fominha! 🍽️" }
        if hygiene < 0.35 { return "Quero um banho! 🛁" }
        if energy < 0.3 { return "Estou com soninho... 😴" }
        if fun < 0.35 { return "Vamos brincar? ⚽" }
        return nil
    }
}
