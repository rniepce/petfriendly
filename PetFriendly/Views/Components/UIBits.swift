import SwiftUI
import UIKit

// MARK: - Vibrações de toque

enum Haptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}

// MARK: - Estilo de botão que "amassa" ao apertar

struct SquishyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.5), value: configuration.isPressed)
    }
}

// MARK: - Botão grande em formato de pílula

struct BigPillButton: View {
    let title: String
    var colors: [Color] = [Color(red: 1.0, green: 0.45, blue: 0.60), Color(red: 0.95, green: 0.30, blue: 0.45)]
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            AudioManager.shared.play(.pop)
            action()
        } label: {
            Text(title)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom))
                        .shadow(color: colors[0].opacity(0.5), radius: 8, y: 4)
                )
        }
        .buttonStyle(SquishyButtonStyle())
    }
}

// MARK: - Botão redondo de atividade (comida, banho, brincar, dormir)

struct BigRoundButton: View {
    let emoji: String
    let label: String
    let color: Color
    var showAlert: Bool = false
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            AudioManager.shared.play(.pop)
            action()
        } label: {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Circle()
                        .fill(LinearGradient(colors: [color.opacity(0.9), color], startPoint: .top, endPoint: .bottom))
                        .frame(width: 62, height: 62)
                        .overlay(
                            Circle().stroke(.white.opacity(0.7), lineWidth: 3)
                        )
                        .overlay(
                            Text(emoji).font(.system(size: 32))
                        )
                        .shadow(color: color.opacity(0.5), radius: 6, y: 3)
                    if showAlert {
                        Text("❗")
                            .font(.system(size: 18))
                            .offset(x: 5, y: -5)
                    }
                }
                Text(label)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.4, green: 0.28, blue: 0.2))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(.white.opacity(0.7)))
            }
        }
        .buttonStyle(SquishyButtonStyle())
    }
}

// MARK: - Barra de status (fome, higiene, diversão, energia)

struct StatBar: View {
    let icon: String
    let value: Double
    let color: Color

    private let trackWidth: CGFloat = 62

    var body: some View {
        HStack(spacing: 6) {
            Text(icon)
                .font(.system(size: 16))
                .shadow(color: .black.opacity(0.1), radius: 1, y: 1)
            
            Capsule()
                .fill(.white.opacity(0.45))
                .frame(width: trackWidth, height: 12)
                .overlay(
                    Capsule()
                        .stroke(.black.opacity(0.08), lineWidth: 1)
                )
                .overlay(alignment: .leading) {
                    let fillColor = value < 0.3 ? Color.red : color
                    ZStack(alignment: .top) {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [fillColor.opacity(0.85), fillColor],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        
                        // Brilho do preenchimento da barra (Gloss)
                        Capsule()
                            .fill(.white.opacity(0.28))
                            .frame(height: 4)
                            .padding(.horizontal, 2)
                    }
                    .frame(width: max(8, trackWidth * value))
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: value)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.white.opacity(0.40))
                .background(Capsule().fill(.ultraThinMaterial))
        )
        .overlay(
            Capsule()
                .stroke(.white.opacity(0.55), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1.5)
    }
}

// MARK: - Balão de fala do pet

struct SpeechBubble: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(Color(red: 0.4, green: 0.3, blue: 0.25))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(.white)
                    .shadow(color: .black.opacity(0.12), radius: 5, y: 2)
            )
            .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - Cabeçalho das atividades, com botão de voltar

struct ActivityHeader: View {
    let title: String
    let onClose: () -> Void

    var body: some View {
        HStack {
            Button {
                Haptics.tap()
                AudioManager.shared.play(.pop)
                onClose()
            } label: {
                HStack(spacing: 4) {
                    Text("🏠").font(.system(size: 20))
                    Text("Voltar")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 0.4, green: 0.28, blue: 0.2))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(.white.opacity(0.9)).shadow(color: .black.opacity(0.15), radius: 4, y: 2))
            }
            .buttonStyle(SquishyButtonStyle())

            Spacer()

            Text(title)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.25), radius: 3, y: 1)

            Spacer()

            // espaço para equilibrar o botão da esquerda
            Color.clear.frame(width: 100, height: 1)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }
}
