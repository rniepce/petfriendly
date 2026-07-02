import SwiftUI

struct ContentView: View {
    @StateObject private var vm = GameViewModel()

    var body: some View {
        ZStack {
            switch vm.screen {
            case .title:
                TitleView()
                    .transition(.opacity)
            case .shop:
                PetShopView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .home:
                HomeView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .environmentObject(vm)
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .onAppear {
            AudioManager.shared.start()
        }
    }
}

#Preview(traits: .landscapeLeft) {
    ContentView()
}
