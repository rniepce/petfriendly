import SwiftUI

/// O que o pet está fazendo — controla a animação do corpo.
enum PetPose: Equatable {
    case idle
    case walk
    case run
    case sit
    case eat
    case sleep
    case happy
}

/// Parâmetros de animação calculados a cada quadro a partir do tempo e da pose.
struct PetMotion {
    var bob: CGFloat = 0          // sobe-desce do corpo (fração do tamanho)
    var breath: CGFloat = 1       // respiração (escala vertical)
    var lean: CGFloat = 0         // inclinação ao correr (graus)
    var sit: CGFloat = 0          // 0-1 sentado
    var lie: CGFloat = 0          // 0-1 deitado
    var headPitch: CGFloat = 0    // cabeça abaixada (graus)
    var legSwing: CGFloat = 0     // balanço das patas (graus)
    var tailWag: CGFloat = 0      // abanar do rabo (graus)
    var earWiggle: CGFloat = 0    // tremida das orelhas (graus)
    var mouthOpen: CGFloat = 0    // 0-1 boca aberta
    var eyeOpen: CGFloat = 1      // 0-1 olhos abertos (piscada)
    var squashX: CGFloat = 1.0    // escala horizontal (física de squash)
    var squashY: CGFloat = 1.0    // escala vertical (física de stretch)
    var headSway: CGFloat = 0     // oscilação lateral da cabeça (graus)

    static func compute(t: Double, pose: PetPose) -> PetMotion {
        var m = PetMotion()

        // Piscada dupla mais fluida a cada 4 segundos
        let blinkCycle = t.truncatingRemainder(dividingBy: 4.0)
        if blinkCycle > 3.65 && blinkCycle < 3.78 {
            m.eyeOpen = 0.1
        } else if blinkCycle >= 3.78 && blinkCycle < 3.84 {
            m.eyeOpen = 1.0
        } else if blinkCycle >= 3.84 && blinkCycle < 3.96 {
            m.eyeOpen = 0.1
        } else {
            m.eyeOpen = 1.0
        }

        switch pose {
        case .idle:
            m.bob = CGFloat(sin(t * 2.2)) * 0.008
            m.breath = 1 + CGFloat(sin(t * 2.2)) * 0.012
            m.tailWag = CGFloat(sin(t * 3.0)) * 12
            m.earWiggle = sin(t * 0.8) > 0.97 ? CGFloat(sin(t * 30)) * 8 : 0
            m.headSway = CGFloat(sin(t * 1.1)) * 1.8
        case .walk:
            m.legSwing = CGFloat(sin(t * 7)) * 16
            m.bob = abs(CGFloat(sin(t * 7))) * 0.012
            m.tailWag = CGFloat(sin(t * 7)) * 10
            m.squashX = 1 + CGFloat(sin(t * 7)) * 0.018
            m.squashY = 1 - CGFloat(sin(t * 7)) * 0.018
        case .run:
            m.legSwing = CGFloat(sin(t * 13)) * 27
            m.bob = abs(CGFloat(sin(t * 13))) * 0.02
            m.lean = 7
            m.tailWag = 14 + CGFloat(sin(t * 13)) * 14
            m.earWiggle = CGFloat(sin(t * 13 + 1)) * 10
            m.mouthOpen = 0.35
            m.squashX = 1 + CGFloat(sin(t * 13)) * 0.05
            m.squashY = 1 - CGFloat(sin(t * 13)) * 0.05
            m.headPitch = 4 + CGFloat(sin(t * 13 + 0.5)) * 3
        case .sit:
            m.sit = 1
            m.breath = 1 + CGFloat(sin(t * 2.0)) * 0.012
            m.tailWag = CGFloat(sin(t * 4.5)) * 16
            m.headSway = CGFloat(sin(t * 0.9)) * 1.2
        case .eat:
            m.headPitch = 26 + CGFloat(sin(t * 9)) * 5
            m.mouthOpen = (CGFloat(sin(t * 9)) + 1) / 2
            m.tailWag = CGFloat(sin(t * 6)) * 18
            m.squashX = 1 + CGFloat(sin(t * 9)) * 0.02
            m.squashY = 1 - CGFloat(sin(t * 9)) * 0.02
        case .sleep:
            m.lie = 1
            m.eyeOpen = 0
            m.breath = 1 + CGFloat(sin(t * 1.5)) * 0.03
            m.squashX = 1.0 - CGFloat(sin(t * 1.5)) * 0.012
            m.squashY = m.breath
            m.headPitch = 10
        case .happy:
            // Salto elástico (Squash & Stretch ao pular)
            let bounceVal = sin(t * 6.0)
            m.bob = -abs(CGFloat(bounceVal)) * 0.06
            m.tailWag = CGFloat(sin(t * 12)) * 22
            m.mouthOpen = 0.5
            m.earWiggle = CGFloat(sin(t * 12)) * 8
            m.squashY = 1.0 + CGFloat(bounceVal) * 0.08
            m.squashX = 1.0 - CGFloat(bounceVal) * 0.08
        }
        return m
    }
}

/// Pet de corpo inteiro, desenhado em vetor e animado continuamente.
struct PetCharacterView: View {
    let species: PetSpecies
    var pose: PetPose = .idle
    var facing: CGFloat = 1   // 1 = olhando para a direita, -1 = esquerda
    var size: CGFloat = 150
    var accessory: String? = nil
    var mood: Mood = .happy

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let m = PetMotion.compute(t: t, pose: pose)

            Group {
                if species == .parrot {
                    BirdFigure(motion: m, size: size, accessory: accessory, mood: mood)
                } else {
                    QuadrupedFigure(species: species, motion: m, size: size, accessory: accessory, mood: mood)
                }
            }
            .rotationEffect(.degrees(Double(m.lean)))
            .offset(y: m.bob * size)
            .scaleEffect(x: facing * m.squashX, y: m.squashY * m.breath, anchor: .bottom)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Formas auxiliares

struct TriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

struct SmileShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.midX, y: rect.maxY)
        )
        return p
    }
}

// MARK: - Quadrúpedes (cachorro, gato, coelho, hamster, unicórnio)

private struct QuadrupedFigure: View {
    let species: PetSpecies
    let motion: PetMotion
    let size: CGFloat
    let accessory: String?
    let mood: Mood

    private var m: PetMotion { motion }
    private var S: CGFloat { size }
    private var pal: PetPalette { species.palette }

    var body: some View {
        ZStack {
            // sombra no chão
            Ellipse()
                .fill(.black.opacity(0.12))
                .frame(width: S * 0.55, height: S * 0.075)
                .position(x: S * 0.48, y: S * 0.90)

            tail

            // patas de trás (escondidas quando sentado/deitado)
            if m.sit < 0.5 && m.lie < 0.5 {
                leg(x: 0.345, phase: -1.0, front: false)
                leg(x: 0.425, phase: 0.7, front: false)
            }

            bodyGroup

            // patas da frente
            if m.lie < 0.5 {
                leg(x: 0.545, phase: 1.0, front: true)
                leg(x: 0.625, phase: -0.7, front: true)
            }

            headGroup
        }
        .frame(width: S, height: S)
    }

    private func leg(x: CGFloat, phase: CGFloat, front: Bool) -> some View {
        let h = S * (front && m.sit > 0.5 ? 0.19 : 0.165)
        let swing = m.sit > 0.5 ? 0 : m.legSwing * phase
        return ZStack(alignment: .bottom) {
            Capsule()
                .fill(front ? pal.body : pal.bodyDark)
            
            // Meias ou cascos coloridos
            if species == .unicorn {
                // Cascos dourados brilhantes
                UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 4, bottomTrailingRadius: 4, topTrailingRadius: 0)
                    .fill(Color(red: 1.0, green: 0.85, blue: 0.25))
                    .frame(height: h * 0.22)
            } else if species == .cat {
                // Meias brancas
                Capsule()
                    .fill(Color.white)
                    .frame(height: h * 0.26)
            } else if species == .dog {
                // Patinhas brancas
                Capsule()
                    .fill(Color(red: 0.98, green: 0.95, blue: 0.92))
                    .frame(height: h * 0.20)
            }
        }
        .frame(width: S * 0.085, height: h)
        .clipShape(Capsule())
        .rotationEffect(.degrees(Double(swing)), anchor: .top)
        .position(x: S * x, y: S * 0.715 + h / 2)
    }

    private var bodyGroup: some View {
        ZStack {
            Ellipse()
                .fill(pal.body)
                .frame(width: S * 0.54, height: S * 0.36)
                .position(x: S * 0.46, y: S * (0.635 + 0.02 * m.lie))
            Ellipse()
                .fill(pal.belly)
                .frame(width: S * 0.32, height: S * 0.19)
                .position(x: S * 0.48, y: S * 0.70)

            if species == .cat {
                stripe(x: 0.36, rot: -14)
                stripe(x: 0.45, rot: -6)
                stripe(x: 0.54, rot: 2) // listra extra
            }
            if species == .dog {
                // Mancha no corpo
                Ellipse()
                    .fill(pal.bodyDark.opacity(0.8))
                    .frame(width: S * 0.16, height: S * 0.11)
                    .position(x: S * 0.36, y: S * 0.56)
                // Outra mancha menor
                Circle()
                    .fill(pal.bodyDark.opacity(0.75))
                    .frame(width: S * 0.07)
                    .position(x: S * 0.52, y: S * 0.55)
            }
            
            if species == .unicorn {
                // Estrelinha mágica no flanco (Cutie Mark)
                StarShape()
                    .fill(Color(red: 1.0, green: 0.55, blue: 0.85))
                    .frame(width: S * 0.055, height: S * 0.055)
                    .position(x: S * 0.35, y: S * 0.62)
            }

            // "coxinha" quando sentado
            if m.sit > 0.5 {
                Circle()
                    .fill(pal.body)
                    .frame(width: S * 0.26)
                    .position(x: S * 0.375, y: S * 0.72)
            }

            // patinhas dobradas quando deitado
            if m.lie > 0.5 {
                Circle().fill(pal.body).frame(width: S * 0.11)
                    .position(x: S * 0.56, y: S * 0.80)
                Circle().fill(pal.body).frame(width: S * 0.11)
                    .position(x: S * 0.66, y: S * 0.80)
            }
        }
        .frame(width: S, height: S)
        .rotationEffect(.degrees(Double(m.sit) * -14), anchor: UnitPoint(x: 0.62, y: 0.82))
        .scaleEffect(x: 1 + m.lie * 0.12, y: 1 - m.lie * 0.18, anchor: .bottom)
    }

    private func stripe(x: CGFloat, rot: Double) -> some View {
        Capsule()
            .fill(pal.bodyDark.opacity(0.7))
            .frame(width: S * 0.045, height: S * 0.13)
            .rotationEffect(.degrees(rot))
            .position(x: S * x, y: S * 0.53)
    }

    // MARK: Rabo

    @ViewBuilder
    private var tail: some View {
        switch species {
        case .rabbit:
            Circle()
                .fill(.white)
                .frame(width: S * 0.11)
                .position(x: S * 0.21, y: S * 0.62)
        case .hamster:
            Circle()
                .fill(pal.bodyDark)
                .frame(width: S * 0.055)
                .position(x: S * 0.20, y: S * 0.63)
        case .unicorn:
            ZStack {
                tailStrand(color: Color(red: 1.0, green: 0.55, blue: 0.75), angle: -18)
                tailStrand(color: Color(red: 0.65, green: 0.55, blue: 0.95), angle: -34)
                tailStrand(color: Color(red: 0.45, green: 0.80, blue: 0.95), angle: -50)
                tailStrand(color: Color(red: 1.0, green: 0.88, blue: 0.45), angle: -62)
            }
            .frame(width: S, height: S)
        default:
            Capsule()
                .fill(pal.bodyDark)
                .frame(width: S * (species == .cat ? 0.055 : 0.075), height: S * 0.24)
                .rotationEffect(.degrees(-30 + Double(m.tailWag)), anchor: .bottom)
                .position(x: S * 0.20, y: S * 0.505)
        }
    }

    private func tailStrand(color: Color, angle: Double) -> some View {
        Capsule()
            .fill(color)
            .frame(width: S * 0.05, height: S * 0.20)
            .rotationEffect(.degrees(angle + Double(m.tailWag) * 0.5), anchor: .bottom)
            .position(x: S * 0.20, y: S * 0.525)
    }

    // MARK: Cabeça

    private var headGroup: some View {
        ZStack {
            ears
            Circle()
                .fill(pal.body)
                .frame(width: S * 0.44)
                .position(x: S * 0.63, y: S * 0.35)

            // Coleira
            if species == .dog {
                Capsule()
                    .fill(Color(red: 0.9, green: 0.25, blue: 0.25))
                    .frame(width: S * 0.20, height: S * 0.044)
                    .rotationEffect(.degrees(22))
                    .position(x: S * 0.52, y: S * 0.51)
                Circle()
                    .fill(Color(red: 1.0, green: 0.82, blue: 0.2))
                    .frame(width: S * 0.045)
                    .position(x: S * 0.565, y: S * 0.54)
            } else if species == .cat {
                Capsule()
                    .fill(Color(red: 0.25, green: 0.45, blue: 0.85))
                    .frame(width: S * 0.18, height: S * 0.038)
                    .rotationEffect(.degrees(22))
                    .position(x: S * 0.53, y: S * 0.51)
                Circle()
                    .fill(Color(red: 1.0, green: 0.82, blue: 0.2))
                    .frame(width: S * 0.04)
                    .position(x: S * 0.57, y: S * 0.535)
            }

            face
            
            if let acc = accessory {
                accessoryView(acc)
            }
        }
        .frame(width: S, height: S)
        .rotationEffect(.degrees(Double(m.headPitch + m.headSway)), anchor: UnitPoint(x: 0.52, y: 0.55))
        .offset(
            x: m.sit * -0.02 * S + m.lie * -0.04 * S,
            y: m.sit * -0.03 * S + m.lie * 0.10 * S
        )
    }

    @ViewBuilder
    private var ears: some View {
        switch species {
        case .dog:
            earFloppy(x: 0.505, side: -1)
            earFloppy(x: 0.755, side: 1)
        case .cat, .unicorn:
            earTriangle(x: 0.51, rot: -12)
            earTriangle(x: 0.75, rot: 12)
        case .rabbit:
            earLong(x: 0.535, rot: -8)
            earLong(x: 0.725, rot: 8)
        case .hamster:
            earRound(x: 0.51)
            earRound(x: 0.75)
        case .parrot:
            EmptyView()
        }
    }

    private func earFloppy(x: CGFloat, side: CGFloat) -> some View {
        Capsule()
            .fill(pal.bodyDark)
            .frame(width: S * 0.10, height: S * 0.22)
            .rotationEffect(.degrees(Double(side * (22 + m.earWiggle))), anchor: .top)
            .position(x: S * x, y: S * 0.265)
    }

    private func earTriangle(x: CGFloat, rot: Double) -> some View {
        ZStack {
            TriangleShape()
                .fill(pal.body)
                .frame(width: S * 0.15, height: S * 0.15)
            TriangleShape()
                .fill(pal.earInner)
                .frame(width: S * 0.075, height: S * 0.075)
                .offset(y: S * 0.028)
        }
        .rotationEffect(.degrees(rot + Double(m.earWiggle) * 0.4), anchor: .bottom)
        .position(x: S * x, y: S * 0.135)
    }

    private func earLong(x: CGFloat, rot: Double) -> some View {
        ZStack {
            Capsule()
                .fill(pal.body)
                .frame(width: S * 0.095, height: S * 0.30)
            Capsule()
                .fill(pal.earInner)
                .frame(width: S * 0.045, height: S * 0.22)
        }
        .rotationEffect(.degrees(rot + Double(m.earWiggle) * 0.6), anchor: .bottom)
        .position(x: S * x, y: S * 0.05)
    }

    private func earRound(x: CGFloat) -> some View {
        ZStack {
            Circle().fill(pal.bodyDark).frame(width: S * 0.13)
            Circle().fill(pal.earInner).frame(width: S * 0.065)
        }
        .position(x: S * x, y: S * 0.145)
    }

    // MARK: Rosto

    private var face: some View {
        ZStack {
            // bochechas rosadas
            blush(x: 0.545)
            blush(x: 0.80)

            // Mancha no olho do doguinho
            if species == .dog {
                Circle()
                    .fill(pal.bodyDark.opacity(0.85))
                    .frame(width: S * 0.13, height: S * 0.15)
                    .position(x: S * 0.56, y: S * 0.35)
            }

            // Almofadas de bigodes brancas no gatinho
            if species == .cat {
                Circle()
                    .fill(.white.opacity(0.80))
                    .frame(width: S * 0.08, height: S * 0.06)
                    .position(x: S * 0.635, y: S * 0.45)
                Circle()
                    .fill(.white.opacity(0.80))
                    .frame(width: S * 0.08, height: S * 0.06)
                    .position(x: S * 0.715, y: S * 0.45)
            }

            eye(x: 0.565)
            eye(x: 0.72)

            // focinho
            Ellipse()
                .fill(pal.belly)
                .frame(width: S * 0.17, height: S * 0.12)
                .position(x: S * 0.675, y: S * 0.44)
            Circle()
                .fill(Color(red: 0.35, green: 0.25, blue: 0.22))
                .frame(width: S * 0.042)
                .position(x: S * 0.675, y: S * 0.405)

            // Dentes salientes do coelhinho
            if species == .rabbit {
                HStack(spacing: S * 0.006) {
                    RoundedRectangle(cornerRadius: S * 0.005)
                        .fill(.white)
                        .frame(width: S * 0.016, height: S * 0.032)
                    RoundedRectangle(cornerRadius: S * 0.005)
                        .fill(.white)
                        .frame(width: S * 0.016, height: S * 0.032)
                }
                .position(x: S * 0.675, y: S * 0.485)
            }

            // Hamster segurando semente
            if species == .hamster && m.mouthOpen > 0.3 {
                // Semente de girassol
                ZStack {
                    TriangleShape()
                        .fill(Color(red: 0.25, green: 0.25, blue: 0.25))
                        .frame(width: S * 0.045, height: S * 0.065)
                    Circle()
                        .fill(Color(red: 0.45, green: 0.45, blue: 0.45))
                        .frame(width: S * 0.045)
                        .offset(y: S * 0.02)
                }
                .rotationEffect(.degrees(15))
                .position(x: S * 0.675, y: S * 0.53)
            }

            // Mãozinhas do hamster
            if species == .hamster {
                Circle()
                    .fill(pal.earInner)
                    .frame(width: S * 0.035)
                    .position(x: S * 0.60, y: S * 0.53)
                Circle()
                    .fill(pal.earInner)
                    .frame(width: S * 0.035)
                    .position(x: S * 0.72, y: S * 0.53)
            }

            mouth

            if species == .cat {
                whisker(x: 0.545, rot: 8, dy: 0)
                whisker(x: 0.545, rot: -8, dy: 0.022)
                whisker(x: 0.805, rot: -8, dy: 0)
                whisker(x: 0.805, rot: 8, dy: 0.022)
            }

            if species == .unicorn {
                // Chifre mágico detalhado com espiral e brilho
                ZStack {
                    TriangleShape()
                        .fill(Color(red: 1.0, green: 0.9, blue: 0.55).opacity(0.4))
                        .frame(width: S * 0.11, height: S * 0.19)
                        .blur(radius: 3)
                    TriangleShape()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 1.0, green: 0.85, blue: 0.45), Color(red: 1.0, green: 0.55, blue: 0.85)],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: S * 0.07, height: S * 0.16)
                    VStack(spacing: S * 0.025) {
                        ForEach(0..<3) { _ in
                            Capsule()
                                .fill(Color.white.opacity(0.75))
                                .frame(width: S * 0.045, height: S * 0.015)
                                .rotationEffect(.degrees(-20))
                        }
                    }
                    .offset(y: -S * 0.01)
                }
                .position(x: S * 0.63, y: S * 0.075)

                // Crina do unicórnio
                maneBlob(x: 0.545, y: 0.115, color: Color(red: 1.0, green: 0.55, blue: 0.75), scale: 1.15)
                maneBlob(x: 0.49, y: 0.17, color: Color(red: 0.65, green: 0.55, blue: 0.95), scale: 1.0)
                maneBlob(x: 0.455, y: 0.24, color: Color(red: 0.45, green: 0.80, blue: 0.95), scale: 0.88)
            }
        }
    }

    /// Bolinha colorida da crina do unicórnio.
    private func maneBlob(x: CGFloat, y: CGFloat, color: Color, scale: CGFloat = 1.0) -> some View {
        Circle()
            .fill(color)
            .frame(width: S * 0.10 * scale)
            .position(x: S * x, y: S * y)
            .shadow(color: color.opacity(0.3), radius: 2)
    }

    private func blush(x: CGFloat) -> some View {
        Circle()
            .fill(Color(red: 1.0, green: 0.6, blue: 0.7).opacity(0.45))
            .frame(width: S * 0.06)
            .position(x: S * x, y: S * 0.435)
    }

    private func eye(x: CGFloat) -> some View {
        ZStack {
            if mood == .verySad {
                Capsule()
                    .fill(Color(red: 0.25, green: 0.18, blue: 0.16))
                    .frame(width: S * 0.065, height: S * 0.015)
                    .rotationEffect(.degrees(x > 0.6 ? 15 : -15))
                Capsule()
                    .fill(Color(red: 0.25, green: 0.18, blue: 0.16))
                    .frame(width: S * 0.015, height: S * 0.03)
                    .offset(x: S * 0.015, y: S * 0.015)
            } else {
                Ellipse()
                    .fill(Color(red: 0.25, green: 0.18, blue: 0.16))
                    .frame(width: S * 0.065, height: S * 0.075)
                Circle()
                    .fill(.white)
                    .frame(width: S * 0.022)
                    .offset(x: -S * 0.012, y: -S * 0.016)
            }
        }
        .scaleEffect(y: max(0.12, m.eyeOpen))
        .position(x: S * x, y: S * 0.345)
    }

    @ViewBuilder
    private var mouth: some View {
        if mood == .verySad {
            SmileShape()
                .stroke(
                    Color(red: 0.35, green: 0.25, blue: 0.22),
                    style: StrokeStyle(lineWidth: S * 0.012, lineCap: .round)
                )
                .frame(width: S * 0.06, height: S * 0.028)
                .rotationEffect(.degrees(180))
                .position(x: S * 0.675, y: S * 0.485)
        } else if m.mouthOpen > 0.15 {
            ZStack {
                Ellipse()
                    .fill(Color(red: 0.55, green: 0.25, blue: 0.25))
                    .frame(width: S * 0.07, height: S * 0.015 + S * 0.06 * m.mouthOpen)
                
                // Língua fofa no doguinho e gatinho
                if species == .dog || species == .cat {
                    Ellipse()
                        .fill(Color(red: 1.0, green: 0.50, blue: 0.55))
                        .frame(width: S * 0.05, height: S * 0.035)
                        .offset(y: S * 0.015)
                } else {
                    Ellipse()
                        .fill(Color(red: 1.0, green: 0.55, blue: 0.6))
                        .frame(width: S * 0.04, height: S * 0.008 + S * 0.03 * m.mouthOpen)
                        .offset(y: S * 0.012)
                }
            }
            .position(x: S * 0.675, y: S * 0.478)
        } else {
            SmileShape()
                .stroke(
                    Color(red: 0.35, green: 0.25, blue: 0.22),
                    style: StrokeStyle(lineWidth: S * 0.012, lineCap: .round)
                )
                .frame(width: S * 0.06, height: S * 0.028)
                .position(x: S * 0.675, y: S * 0.462)
        }
    }

    private func whisker(x: CGFloat, rot: Double, dy: CGFloat) -> some View {
        Capsule()
            .fill(Color(red: 0.35, green: 0.25, blue: 0.22).opacity(0.55))
            .frame(width: S * 0.09, height: S * 0.008)
            .rotationEffect(.degrees(rot))
            .position(x: S * x, y: S * (0.43 + dy))
    }

    @ViewBuilder
    private func accessoryView(_ acc: String) -> some View {
        switch acc {
        case "🎩":
            ZStack(alignment: .bottom) {
                // Aba da cartola
                Ellipse()
                    .fill(Color(red: 0.15, green: 0.15, blue: 0.18))
                    .frame(width: S * 0.22, height: S * 0.04)
                // Corpo da cartola
                UnevenRoundedRectangle(topLeadingRadius: 4, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 4)
                    .fill(Color(red: 0.15, green: 0.15, blue: 0.18))
                    .frame(width: S * 0.14, height: S * 0.15)
                    .offset(y: -S * 0.02)
                // Faixa vermelha
                Rectangle()
                    .fill(Color(red: 0.9, green: 0.25, blue: 0.25))
                    .frame(width: S * 0.14, height: S * 0.03)
                    .offset(y: -S * 0.02)
            }
            .position(x: S * 0.63, y: S * 0.12)
        case "🕶️":
            HStack(spacing: S * 0.02) {
                Circle().fill(Color(red: 0.1, green: 0.1, blue: 0.1)).frame(width: S * 0.08, height: S * 0.08)
                Circle().fill(Color(red: 0.1, green: 0.1, blue: 0.1)).frame(width: S * 0.08, height: S * 0.08)
            }
            .overlay(
                Rectangle().fill(Color(red: 0.1, green: 0.1, blue: 0.1)).frame(width: S * 0.16, height: S * 0.02),
                alignment: .top
            )
            .position(x: S * 0.68, y: S * 0.345)
        case "🎀":
            ZStack {
                // Asas do laço
                HStack(spacing: -S * 0.01) {
                    TriangleShape()
                        .fill(Color(red: 1.0, green: 0.55, blue: 0.7))
                        .frame(width: S * 0.07, height: S * 0.07)
                        .rotationEffect(.degrees(90))
                    TriangleShape()
                        .fill(Color(red: 1.0, green: 0.55, blue: 0.7))
                        .frame(width: S * 0.07, height: S * 0.07)
                        .rotationEffect(.degrees(-90))
                }
                // Centro do laço
                Circle()
                    .fill(Color(red: 0.95, green: 0.35, blue: 0.55))
                    .frame(width: S * 0.03)
            }
            .position(x: S * 0.52, y: S * 0.23)
        case "👑":
            ZStack(alignment: .bottom) {
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 30))
                    path.addLine(to: CGPoint(x: 0, y: 10))
                    path.addLine(to: CGPoint(x: 10, y: 22))
                    path.addLine(to: CGPoint(x: 20, y: 5))
                    path.addLine(to: CGPoint(x: 30, y: 22))
                    path.addLine(to: CGPoint(x: 40, y: 10))
                    path.addLine(to: CGPoint(x: 40, y: 30))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.85, blue: 0.25), Color(red: 0.95, green: 0.70, blue: 0.15)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: S * 0.16, height: S * 0.11)
                
                HStack(spacing: S * 0.03) {
                    Circle().fill(Color.red).frame(width: S * 0.015)
                    Circle().fill(Color.blue).frame(width: S * 0.015)
                    Circle().fill(Color.green).frame(width: S * 0.015)
                }
                .offset(y: -S * 0.015)
            }
            .position(x: S * 0.63, y: S * 0.14)
        default:
            EmptyView()
        }
    }
}

// MARK: - Papagaio

private struct BirdFigure: View {
    let motion: PetMotion
    let size: CGFloat
    let accessory: String?
    let mood: Mood

    private var m: PetMotion { motion }
    private var S: CGFloat { size }

    private let green = Color(red: 0.30, green: 0.72, blue: 0.35)
    private let darkGreen = Color(red: 0.20, green: 0.55, blue: 0.28)
    private let bellyColor = Color(red: 0.75, green: 0.90, blue: 0.55)
    private let red = Color(red: 0.92, green: 0.30, blue: 0.25)
    private let blue = Color(red: 0.25, green: 0.55, blue: 0.90)
    private let orange = Color(red: 0.95, green: 0.60, blue: 0.20)

    var body: some View {
        ZStack {
            Ellipse()
                .fill(.black.opacity(0.12))
                .frame(width: S * 0.45, height: S * 0.07)
                .position(x: S * 0.5, y: S * 0.90)

            // penas da cauda
            tailFeather(color: red, angle: -30)
            tailFeather(color: blue, angle: -46)

            // perninhas
            if m.lie < 0.5 {
                birdLeg(x: 0.46)
                birdLeg(x: 0.56)
            }

            // corpo
            ZStack {
                Ellipse()
                    .fill(green)
                    .frame(width: S * 0.46, height: S * 0.52)
                    .position(x: S * 0.50, y: S * 0.55)
                Ellipse()
                    .fill(bellyColor)
                    .frame(width: S * 0.28, height: S * 0.34)
                    .position(x: S * 0.545, y: S * 0.62)
            }
            .frame(width: S, height: S)
            .scaleEffect(x: 1 + m.lie * 0.1, y: 1 - m.lie * 0.15, anchor: .bottom)

            // asa multicamadas colorida (bate quando corre ou está feliz)
            ZStack {
                // Pena azul externa
                Ellipse()
                    .fill(blue)
                    .frame(width: S * 0.21, height: S * 0.35)
                    .offset(x: -S * 0.015, y: S * 0.015)
                // Pena amarela média
                Ellipse()
                    .fill(orange)
                    .frame(width: S * 0.17, height: S * 0.30)
                    .offset(x: -S * 0.008, y: S * 0.008)
                // Pena verde principal
                Ellipse()
                    .fill(darkGreen)
                    .frame(width: S * 0.18, height: S * 0.28)
            }
            .rotationEffect(.degrees(-14 + Double(m.legSwing) * 1.2 + Double(m.tailWag) * 0.4), anchor: .top)
            .position(x: S * 0.42, y: S * 0.56)

            headGroup
        }
        .frame(width: S, height: S)
    }

    private func birdLeg(x: CGFloat) -> some View {
        VStack(spacing: 0) {
            Capsule().fill(orange).frame(width: S * 0.035, height: S * 0.12)
            Capsule().fill(orange).frame(width: S * 0.09, height: S * 0.03)
        }
        .rotationEffect(.degrees(Double(m.legSwing) * 0.3), anchor: .top)
        .position(x: S * x, y: S * 0.815)
    }

    private func tailFeather(color: Color, angle: Double) -> some View {
        Capsule()
            .fill(color)
            .frame(width: S * 0.07, height: S * 0.28)
            .rotationEffect(.degrees(angle + Double(m.tailWag) * 0.4), anchor: .bottom)
            .position(x: S * 0.33, y: S * 0.52)
    }

    private var headGroup: some View {
        ZStack {
            Circle()
                .fill(green)
                .frame(width: S * 0.36)
                .position(x: S * 0.58, y: S * 0.28)

            // penacho colorido
            Circle().fill(red).frame(width: S * 0.09)
                .position(x: S * 0.52, y: S * 0.105)
            Circle().fill(orange).frame(width: S * 0.07)
                .position(x: S * 0.60, y: S * 0.09)

            // rosto branco
            Ellipse()
                .fill(.white.opacity(0.9))
                .frame(width: S * 0.16, height: S * 0.18)
                .position(x: S * 0.655, y: S * 0.28)

            // olho
            ZStack {
                if mood == .verySad {
                    Capsule()
                        .fill(Color(red: 0.25, green: 0.18, blue: 0.16))
                        .frame(width: S * 0.06, height: S * 0.015)
                        .rotationEffect(.degrees(15))
                    Capsule()
                        .fill(Color(red: 0.25, green: 0.18, blue: 0.16))
                        .frame(width: S * 0.015, height: S * 0.03)
                        .offset(x: S * 0.015, y: S * 0.015)
                } else {
                    Ellipse()
                        .fill(Color(red: 0.2, green: 0.15, blue: 0.15))
                        .frame(width: S * 0.06, height: S * 0.07)
                    Circle()
                        .fill(.white)
                        .frame(width: S * 0.02)
                        .offset(x: -S * 0.01, y: -S * 0.015)
                }
            }
            .scaleEffect(y: max(0.12, m.eyeOpen))
            .position(x: S * 0.655, y: S * 0.27)

            // Bico realista (superior e inferior articulados)
            ZStack {
                // Bico inferior
                TriangleShape()
                    .fill(orange.opacity(0.85))
                    .frame(width: S * 0.08, height: S * 0.07)
                    .rotationEffect(.degrees(105 + Double(m.mouthOpen) * 35))
                    .position(x: S * 0.76, y: S * 0.34)
                
                // Bico superior
                TriangleShape()
                    .fill(orange)
                    .frame(width: S * 0.13, height: S * 0.12)
                    .rotationEffect(.degrees(95 - Double(m.mouthOpen) * 5))
                    .position(x: S * 0.775, y: S * 0.31)
            }

            // bochecha
            Circle()
                .fill(Color(red: 1.0, green: 0.6, blue: 0.7).opacity(0.5))
                .frame(width: S * 0.05)
                .position(x: S * 0.60, y: S * 0.35)
            
            if let acc = accessory {
                accessoryView(acc)
            }
        }
        .frame(width: S, height: S)
        .rotationEffect(.degrees(Double(m.headPitch + m.headSway)), anchor: UnitPoint(x: 0.52, y: 0.42))
    }

    @ViewBuilder
    private func accessoryView(_ acc: String) -> some View {
        switch acc {
        case "🎩":
            ZStack(alignment: .bottom) {
                Ellipse()
                    .fill(Color(red: 0.15, green: 0.15, blue: 0.18))
                    .frame(width: S * 0.18, height: S * 0.035)
                UnevenRoundedRectangle(topLeadingRadius: 4, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 4)
                    .fill(Color(red: 0.15, green: 0.15, blue: 0.18))
                    .frame(width: S * 0.11, height: S * 0.12)
                    .offset(y: -S * 0.015)
                Rectangle()
                    .fill(Color(red: 0.9, green: 0.25, blue: 0.25))
                    .frame(width: S * 0.11, height: S * 0.025)
                    .offset(y: -S * 0.015)
            }
            .position(x: S * 0.58, y: S * 0.05)
        case "🕶️":
            HStack(spacing: S * 0.015) {
                Circle().fill(Color(red: 0.1, green: 0.1, blue: 0.1)).frame(width: S * 0.065, height: S * 0.065)
                Circle().fill(Color(red: 0.1, green: 0.1, blue: 0.1)).frame(width: S * 0.065, height: S * 0.065)
            }
            .overlay(
                Rectangle().fill(Color(red: 0.1, green: 0.1, blue: 0.1)).frame(width: S * 0.13, height: S * 0.015),
                alignment: .top
            )
            .position(x: S * 0.65, y: S * 0.27)
        case "🎀":
            ZStack {
                HStack(spacing: -S * 0.01) {
                    TriangleShape()
                        .fill(Color(red: 1.0, green: 0.55, blue: 0.7))
                        .frame(width: S * 0.06, height: S * 0.06)
                        .rotationEffect(.degrees(90))
                    TriangleShape()
                        .fill(Color(red: 1.0, green: 0.55, blue: 0.7))
                        .frame(width: S * 0.06, height: S * 0.06)
                        .rotationEffect(.degrees(-90))
                }
                Circle()
                    .fill(Color(red: 0.95, green: 0.35, blue: 0.55))
                    .frame(width: S * 0.025)
            }
            .position(x: S * 0.46, y: S * 0.18)
        case "👑":
            ZStack(alignment: .bottom) {
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 25))
                    path.addLine(to: CGPoint(x: 0, y: 8))
                    path.addLine(to: CGPoint(x: 8, y: 18))
                    path.addLine(to: CGPoint(x: 16, y: 4))
                    path.addLine(to: CGPoint(x: 24, y: 18))
                    path.addLine(to: CGPoint(x: 32, y: 8))
                    path.addLine(to: CGPoint(x: 32, y: 25))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.85, blue: 0.25), Color(red: 0.95, green: 0.70, blue: 0.15)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: S * 0.13, height: S * 0.09)
                
                HStack(spacing: S * 0.02) {
                    Circle().fill(Color.red).frame(width: S * 0.012)
                    Circle().fill(Color.blue).frame(width: S * 0.012)
                    Circle().fill(Color.green).frame(width: S * 0.012)
                }
                .offset(y: -S * 0.008)
            }
            .position(x: S * 0.58, y: S * 0.07)
        default:
            EmptyView()
        }
    }
}

#Preview(traits: .landscapeLeft) {
    HStack(spacing: 8) {
        PetCharacterView(species: .dog, pose: .idle, size: 110)
            .environmentObject(GameViewModel())
        PetCharacterView(species: .cat, pose: .sit, size: 110)
            .environmentObject(GameViewModel())
        PetCharacterView(species: .rabbit, pose: .run, size: 110)
            .environmentObject(GameViewModel())
        PetCharacterView(species: .unicorn, pose: .happy, size: 110)
            .environmentObject(GameViewModel())
        PetCharacterView(species: .parrot, pose: .idle, size: 110)
            .environmentObject(GameViewModel())
        PetCharacterView(species: .hamster, pose: .sleep, size: 110)
            .environmentObject(GameViewModel())
    }
    .padding()
    .background(Color(red: 1.0, green: 0.93, blue: 0.82))
}
