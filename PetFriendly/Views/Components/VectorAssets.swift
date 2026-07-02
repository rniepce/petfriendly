import SwiftUI

// MARK: - Shape de Estrela de 5 Pontas

struct StarShape: Shape {
    let corners: Int = 5
    let smoothness: CGFloat = 0.45

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        let angle = CGFloat.pi / CGFloat(corners)
        let cx = center.x
        let cy = center.y
        let length = min(rect.width, rect.height) / 2
        
        var first = true
        for i in 0..<corners * 2 {
            let r = i.isMultiple(of: 2) ? length : length * smoothness
            let theta = CGFloat(i) * angle - CGFloat.pi / 2
            let x = cx + r * cos(theta)
            let y = cy + r * sin(theta)
            
            if first {
                path.move(to: CGPoint(x: x, y: y))
                first = false
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Sol Vetorial Animado

struct VectorSun: View {
    @State private var rotation: Double = 0
    @State private var pulse: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Brilho externo (glowing background)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 1.0, green: 0.90, blue: 0.55).opacity(0.65), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 75
                    )
                )
                .frame(width: 150, height: 150)
                .scaleEffect(pulse)
            
            // Raios do sol rotacionando
            ZStack {
                ForEach(0..<8) { i in
                    Capsule()
                        .fill(LinearGradient(colors: [Color(red: 1.0, green: 0.75, blue: 0.20), Color(red: 1.0, green: 0.90, blue: 0.45)], startPoint: .top, endPoint: .bottom))
                        .frame(width: 12, height: 38)
                        .offset(y: -52)
                        .rotationEffect(.degrees(Double(i) * 45))
                }
            }
            .rotationEffect(.degrees(rotation))
            
            // Núcleo do sol
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.88, blue: 0.35), Color(red: 1.0, green: 0.60, blue: 0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 66, height: 66)
                .shadow(color: Color(red: 1.0, green: 0.60, blue: 0.15).opacity(0.4), radius: 8, x: 0, y: 3)
        }
        .onAppear {
            withAnimation(.linear(duration: 18).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                pulse = 1.15
            }
        }
    }
}

// MARK: - Nuvem Vetorial Animada

struct VectorCloud: View {
    let scale: CGFloat
    let opacity: Double
    @State private var offset: CGFloat = 0
    @State private var bob: CGFloat = 0
    private let randomRange: CGFloat = CGFloat.random(in: 12...35)
    
    init(scale: CGFloat = 1.0, opacity: Double = 0.95) {
        self.scale = scale
        self.opacity = opacity
    }

    var body: some View {
        ZStack {
            // Sombra da nuvem
            cloudBase
                .fill(Color.black.opacity(0.06))
                .offset(y: 6)
            
            // Nuvem principal
            cloudBase
                .fill(
                    LinearGradient(
                        colors: [.white, Color(red: 0.92, green: 0.96, blue: 1.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .frame(width: 140, height: 80)
        .scaleEffect(scale)
        .opacity(opacity)
        .offset(x: offset, y: bob)
        .onAppear {
            // Animação de flutuação lateral lenta (drift)
            withAnimation(.easeInOut(duration: Double.random(in: 8...14)).repeatForever(autoreverses: true)) {
                offset = CGFloat.random(in: -randomRange...randomRange)
            }
            // Animação de subida e descida leve (bob)
            withAnimation(.easeInOut(duration: Double.random(in: 4...6)).repeatForever(autoreverses: true)) {
                bob = CGFloat.random(in: -8...8)
            }
        }
    }
    
    private var cloudBase: some Shape {
        Path { path in
            path.addEllipse(in: CGRect(x: 10, y: 30, width: 65, height: 45))
            path.addEllipse(in: CGRect(x: 45, y: 15, width: 70, height: 60))
            path.addEllipse(in: CGRect(x: 85, y: 35, width: 45, height: 40))
            path.addRect(CGRect(x: 40, y: 45, width: 60, height: 30))
        }
    }
}

// MARK: - Arco-Íris Vetorial

struct VectorRainbow: View {
    @State private var animateGlow = false
    
    var body: some View {
        ZStack {
            ForEach(0..<6) { i in
                ArcView(index: i)
            }
        }
        .opacity(animateGlow ? 0.85 : 0.65)
        .blur(radius: 2)
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                animateGlow = true
            }
        }
    }
    
    struct ArcView: View {
        let index: Int
        
        var body: some View {
            let radius = CGFloat(110 + index * 13)
            let color: Color = {
                switch index {
                case 0: return Color(red: 1.0, green: 0.55, blue: 0.60)    // Rosa/Vermelho pastel
                case 1: return Color(red: 1.0, green: 0.72, blue: 0.50)    // Laranja pastel
                case 2: return Color(red: 1.0, green: 0.90, blue: 0.55)    // Amarelo pastel
                case 3: return Color(red: 0.60, green: 0.87, blue: 0.65)    // Verde pastel
                case 4: return Color(red: 0.55, green: 0.80, blue: 1.0)     // Azul pastel
                default: return Color(red: 0.75, green: 0.65, blue: 0.95)   // Roxo pastel
                }
            }()
            
            return Circle()
                .trim(from: 0.5, to: 1.0)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .frame(width: radius * 2, height: radius * 2)
                .rotationEffect(.degrees(0))
        }
    }
}

// MARK: - Estrela Vetorial Animada

struct VectorStar: View {
    let size: CGFloat
    let delay: Double
    @State private var rotation: Double = 0
    @State private var pulse: CGFloat = 1.0
    
    init(size: CGFloat = 24, delay: Double = 0) {
        self.size = size
        self.delay = delay
    }

    var body: some View {
        StarShape()
            .fill(
                LinearGradient(
                    colors: [Color(red: 1.0, green: 0.92, blue: 0.45), Color(red: 1.0, green: 0.78, blue: 0.15)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .shadow(color: Color(red: 1.0, green: 0.78, blue: 0.15).opacity(0.55), radius: size * 0.25, x: 0, y: 0)
            .rotationEffect(.degrees(rotation))
            .scaleEffect(pulse)
            .onAppear {
                withAnimation(.linear(duration: Double.random(in: 4...8)).repeatForever(autoreverses: false).delay(delay)) {
                    rotation = 360
                }
                withAnimation(.easeInOut(duration: Double.random(in: 1.2...2.0)).repeatForever(autoreverses: true).delay(delay)) {
                    pulse = 0.7
                }
            }
    }
}

// MARK: - Flores Vetoriais para o Jardim

struct VectorFlower: View {
    let size: CGFloat
    @State private var sway = false
    private let randomAngle: Double = Double.random(in: 4...10)
    
    init(size: CGFloat = 30) {
        self.size = size
    }

    var body: some View {
        VStack(spacing: 0) {
            // Flor
            ZStack {
                // Pétalas
                ForEach(0..<5) { i in
                    Circle()
                        .fill(Color.white)
                        .frame(width: size * 0.44, height: size * 0.44)
                        .offset(y: -size * 0.26)
                        .rotationEffect(.degrees(Double(i) * 72))
                }
                
                // Miolo
                Circle()
                    .fill(Color(red: 1.0, green: 0.78, blue: 0.2))
                    .frame(width: size * 0.38, height: size * 0.38)
                    .shadow(color: .black.opacity(0.08), radius: 2)
            }
            .frame(width: size, height: size)
            
            // Caule
            Rectangle()
                .fill(Color(red: 0.40, green: 0.72, blue: 0.35))
                .frame(width: size * 0.1, height: size * 0.6)
        }
        .rotationEffect(.degrees(sway ? randomAngle : -randomAngle), anchor: .bottom)
        .onAppear {
            withAnimation(.easeInOut(duration: Double.random(in: 2.5...4)).repeatForever(autoreverses: true)) {
                sway = true
            }
        }
    }
}
