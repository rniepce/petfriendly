import SwiftUI

/// O bichinho na tela: emoji grande com sombra e balanço suave.
struct PetSpriteView: View {
    let species: PetSpecies
    var size: CGFloat = 140

    @State private var bob = false

    var body: some View {
        ZStack {
            Ellipse()
                .fill(Color.black.opacity(0.14))
                .frame(width: size * 0.85, height: size * 0.16)
                .offset(y: size * 0.55)
            Text(species.emoji)
                .font(.system(size: size))
                .offset(y: bob ? -8 : 4)
                .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: bob)
        }
        .onAppear { bob = true }
    }
}
