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

    static func compute(t: Double, pose: PetPose) -> PetMotion {
        var m = PetMotion()

        // piscada rápida a cada ~3,8 segundos
        let blinkCycle = t.truncatingRemainder(dividingBy: 3.8)
        m.eyeOpen = blinkCycle > 3.62 ? 0.15 : 1

        switch pose {
        case .idle:
            m.bob = CGFloat(sin(t * 2.2)) * 0.008
            m.breath = 1 + CGFloat(sin(t * 2.2)) * 0.012
            m.tailWag = CGFloat(sin(t * 3.0)) * 12
            m.earWiggle = sin(t * 0.8) > 0.97 ? CGFloat(sin(t * 30)) * 8 : 0
        case .walk:
            m.legSwing = CGFloat(sin(t * 7)) * 16
            m.bob = abs(CGFloat(sin(t * 7))) * 0.012
            m.tailWag = CGFloat(sin(t * 7)) * 10
        case .run:
            m.legSwing = CGFloat(sin(t * 13)) * 27
            m.bob = abs(CGFloat(sin(t * 13))) * 0.02
            m.lean = 7
            m.tailWag = 14 + CGFloat(sin(t * 13)) * 8
            m.earWiggle = CGFloat(sin(t * 13 + 1)) * 10
            m.mouthOpen = 0.35
        case .sit:
            m.sit = 1
            m.breath = 1 + CGFloat(sin(t * 2.0)) * 0.012
            m.tailWag = CGFloat(sin(t * 4.5)) * 16
        case .eat:
            m.headPitch = 26 + CGFloat(sin(t * 9)) * 5
            m.mouthOpen = (CGFloat(sin(t * 9)) + 1) / 2
            m.tailWag = CGFloat(sin(t * 6)) * 18
        case .sleep:
            m.lie = 1
            m.eyeOpen = 0
            m.breath = 1 + CGFloat(sin(t * 1.5)) * 0.03
            m.headPitch = 10
        case .happy:
            m.bob = -abs(CGFloat(sin(t * 6))) * 0.05
            m.tailWag = CGFloat(sin(t * 12)) * 22
            m.mouthOpen = 0.5
            m.earWiggle = CGFloat(sin(t * 12)) * 8
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

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let m = PetMotion.compute(t: t, pose: pose)

            Group {
                if species == .parrot {
                    BirdFigure(motion: m, size: size)
                } else {
                    QuadrupedFigure(species: species, motion: m, size: size)
                }
            }
            .rotationEffect(.degrees(Double(m.lean)))
            .offset(y: m.bob * size)
            .scaleEffect(x: facing, y: 1)
            .scaleEffect(x: 1, y: m.breath, anchor: .bottom)
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
        return Capsule()
            .fill(front ? pal.body : pal.bodyDark)
            .frame(width: S * 0.085, height: h)
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
            }
            if species == .dog {
                Ellipse()
                    .fill(pal.bodyDark.opacity(0.8))
                    .frame(width: S * 0.16, height: S * 0.11)
                    .position(x: S * 0.36, y: S * 0.56)
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
            face
        }
        .frame(width: S, height: S)
        .rotationEffect(.degrees(Double(m.headPitch)), anchor: UnitPoint(x: 0.52, y: 0.55))
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

            if species == .rabbit {
                RoundedRectangle(cornerRadius: S * 0.012)
                    .fill(.white)
                    .frame(width: S * 0.045, height: S * 0.045)
                    .position(x: S * 0.675, y: S * 0.478)
            }

            mouth

            if species == .cat {
                whisker(x: 0.545, rot: 8, dy: 0)
                whisker(x: 0.545, rot: -8, dy: 0.022)
                whisker(x: 0.805, rot: -8, dy: 0)
                whisker(x: 0.805, rot: 8, dy: 0.022)
            }

            if species == .unicorn {
                TriangleShape()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.95, green: 0.70, blue: 0.20), Color(red: 1.0, green: 0.87, blue: 0.45)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: S * 0.07, height: S * 0.16)
                    .position(x: S * 0.63, y: S * 0.075)
                maneBlob(x: 0.545, y: 0.115, color: Color(red: 1.0, green: 0.55, blue: 0.75))
                maneBlob(x: 0.49, y: 0.17, color: Color(red: 0.65, green: 0.55, blue: 0.95))
                maneBlob(x: 0.455, y: 0.24, color: Color(red: 0.45, green: 0.80, blue: 0.95))
            }
        }
    }

    private func blush(x: CGFloat) -> some View {
        Circle()
            .fill(Color(red: 1.0, green: 0.6, blue: 0.7).opacity(0.45))
            .frame(width: S * 0.06)
            .position(x: S * x, y: S * 0.435)
    }

    private func eye(x: CGFloat) -> some View {
        ZStack {
            Ellipse()
                .fill(Color(red: 0.25, green: 0.18, blue: 0.16))
                .frame(width: S * 0.065, height: S * 0.075)
            Circle()
                .fill(.white)
                .frame(width: S * 0.022)
                .offset(x: -S * 0.012, y: -S * 0.016)
        }
        .scaleEffect(y: max(0.12, m.eyeOpen))
        .position(x: S * x, y: S * 0.345)
    }

    @ViewBuilder
    private var mouth: some View {
        if m.mouthOpen > 0.15 {
            ZStack {
                Ellipse()
                    .fill(Color(red: 0.55, green: 0.25, blue: 0.25))
                    .frame(width: S * 0.07, height: S * 0.015 + S * 0.06 * m.mouthOpen)
                Ellipse()
                    .fill(Color(red: 1.0, green: 0.55, blue: 0.6))
                    .frame(width: S * 0.04, height: S * 0.008 + S * 0.03 * m.mouthOpen)
                    .offset(y: S * 0.012)
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
}

// MARK: - Papagaio

private struct BirdFigure: View {
    let motion: PetMotion
    let size: CGFloat

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

            // asa (bate quando corre ou está feliz)
            Ellipse()
                .fill(darkGreen)
                .frame(width: S * 0.20, height: S * 0.34)
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
                Ellipse()
                    .fill(Color(red: 0.2, green: 0.15, blue: 0.15))
                    .frame(width: S * 0.06, height: S * 0.07)
                Circle()
                    .fill(.white)
                    .frame(width: S * 0.02)
                    .offset(x: -S * 0.01, y: -S * 0.015)
            }
            .scaleEffect(y: max(0.12, m.eyeOpen))
            .position(x: S * 0.655, y: S * 0.27)

            // bico
            TriangleShape()
                .fill(orange)
                .frame(width: S * 0.12, height: S * 0.11)
                .rotationEffect(.degrees(95 + Double(m.mouthOpen) * 12))
                .position(x: S * 0.775, y: S * 0.315)

            // bochecha
            Circle()
                .fill(Color(red: 1.0, green: 0.6, blue: 0.7).opacity(0.5))
                .frame(width: S * 0.05)
                .position(x: S * 0.60, y: S * 0.35)
        }
        .frame(width: S, height: S)
        .rotationEffect(.degrees(Double(m.headPitch)), anchor: UnitPoint(x: 0.52, y: 0.42))
    }
}

#Preview(traits: .landscapeLeft) {
    HStack(spacing: 8) {
        PetCharacterView(species: .dog, pose: .idle, size: 110)
        PetCharacterView(species: .cat, pose: .sit, size: 110)
        PetCharacterView(species: .rabbit, pose: .run, size: 110)
        PetCharacterView(species: .unicorn, pose: .happy, size: 110)
        PetCharacterView(species: .parrot, pose: .idle, size: 110)
        PetCharacterView(species: .hamster, pose: .sleep, size: 110)
    }
    .padding()
    .background(Color(red: 1.0, green: 0.93, blue: 0.82))
}
