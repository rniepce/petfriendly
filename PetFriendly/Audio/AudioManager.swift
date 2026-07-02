import AVFoundation
import UIKit

/// Efeitos sonoros curtos, sintetizados na hora.
enum SFX: CaseIterable {
    case pop      // toque em botões / soltar comida
    case nom      // mastigando
    case boing    // pulo / bola
    case splash   // água e bolhas
    case chime    // recompensa / estrela
    case bark     // latido (cachorro)
    case meow     // miau (gato)
    case squeak   // guincho (hamster)
    case chirp    // piar (papagaio)
    case sparkle  // brilho mágico (unicórnio)
}

/// Gera e toca a musiquinha de fundo (estilo caixinha de música) e os efeitos,
/// tudo sintetizado em código — o app não precisa de arquivos de áudio.
final class AudioManager: ObservableObject {
    static let shared = AudioManager()

    @Published var musicOn: Bool {
        didSet {
            UserDefaults.standard.set(musicOn, forKey: "petfriendly.musicOn")
            applyMusic()
        }
    }
    @Published var soundOn: Bool {
        didSet {
            UserDefaults.standard.set(soundOn, forKey: "petfriendly.soundOn")
        }
    }

    private let engine = AVAudioEngine()
    private let musicNode = AVAudioPlayerNode()
    private var sfxNodes: [AVAudioPlayerNode] = []
    private var sfxIndex = 0
    private var musicBuffer: AVAudioPCMBuffer?
    private var sfxBuffers: [SFX: AVAudioPCMBuffer] = [:]
    private var started = false
    private let sampleRate: Double = 44100

    private init() {
        musicOn = UserDefaults.standard.object(forKey: "petfriendly.musicOn") as? Bool ?? true
        soundOn = UserDefaults.standard.object(forKey: "petfriendly.soundOn") as? Bool ?? true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appBecameActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    @objc private func appBecameActive() {
        guard started else { return }
        if !engine.isRunning {
            try? engine.start()
            applyMusic()
        }
    }

    /// Chame uma vez quando o app abre.
    func start() {
        guard !started else { return }
        started = true

        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)

        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }

        engine.attach(musicNode)
        engine.connect(musicNode, to: engine.mainMixerNode, format: format)
        for _ in 0..<3 {
            let node = AVAudioPlayerNode()
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: format)
            sfxNodes.append(node)
        }
        musicNode.volume = 0.55

        musicBuffer = Self.renderMusicLoop(sampleRate: sampleRate, format: format)
        for sfx in SFX.allCases {
            sfxBuffers[sfx] = Self.renderSFX(sfx, sampleRate: sampleRate, format: format)
        }

        engine.prepare()
        try? engine.start()
        applyMusic()
    }

    private func applyMusic() {
        guard started, engine.isRunning, let buffer = musicBuffer else { return }
        musicNode.stop()
        if musicOn {
            musicNode.scheduleBuffer(buffer, at: nil, options: .loops)
            musicNode.play()
        }
    }

    func play(_ sfx: SFX) {
        guard started, soundOn, engine.isRunning, let buffer = sfxBuffers[sfx] else { return }
        let node = sfxNodes[sfxIndex % sfxNodes.count]
        sfxIndex += 1
        node.stop()
        node.volume = 0.9
        node.scheduleBuffer(buffer, at: nil)
        node.play()
    }

    /// Toca o som de voz característico da espécie
    func playVoice(for species: PetSpecies) {
        switch species {
        case .dog:
            play(.bark)
        case .cat:
            play(.meow)
        case .rabbit:
            play(.boing)
        case .hamster:
            play(.squeak)
        case .parrot:
            play(.chirp)
        case .unicorn:
            play(.sparkle)
        }
    }

    // MARK: - Síntese da música

    /// Melodia original pentatônica, tocada com timbre de caixinha de música,
    /// com um baixo suave por baixo. O loop tem 32 tempos (~23 segundos).
    private static func renderMusicLoop(sampleRate: Double, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let bpm = 84.0
        let beat = 60.0 / bpm
        let loopBeats = 32.0
        let frameCount = Int(loopBeats * beat * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount)) else { return nil }
        buffer.frameLength = AVAudioFrameCount(frameCount)
        guard let data = buffer.floatChannelData?[0] else { return nil }
        for i in 0..<frameCount { data[i] = 0 }

        // (nota MIDI, início em tempos, duração em tempos)
        let melody: [(Int, Double, Double)] = [
            (72, 0, 1), (76, 1, 1), (79, 2, 1.5), (76, 3.5, 0.5),
            (81, 4, 1), (79, 5, 1), (76, 6, 2),
            (74, 8, 1), (76, 9, 1), (79, 10, 1.5), (74, 11.5, 0.5),
            (76, 12, 1), (74, 13, 1), (72, 14, 2),
            (76, 16, 1), (79, 17, 1), (81, 18, 1.5), (79, 19.5, 0.5),
            (84, 20, 1), (81, 21, 1), (79, 22, 2),
            (81, 24, 1), (79, 25, 1), (76, 26, 1), (79, 27, 1),
            (74, 28, 1), (76, 29, 1), (72, 30, 2),
        ]
        let bass: [(Int, Double, Double)] = [
            (48, 0, 2), (55, 2, 2), (45, 4, 2), (52, 6, 2),
            (50, 8, 2), (57, 10, 2), (48, 12, 2), (55, 14, 2),
            (48, 16, 2), (55, 18, 2), (45, 20, 2), (52, 22, 2),
            (45, 24, 2), (52, 26, 2), (55, 28, 2), (48, 30, 2),
        ]

        func addNote(midi: Int, startBeat: Double, durBeats: Double, gain: Float, bell: Bool) {
            let freq = 440.0 * pow(2.0, (Double(midi) - 69.0) / 12.0)
            let startFrame = Int(startBeat * beat * sampleRate)
            let tail = bell ? 0.9 : 0.4
            let total = Int((durBeats * beat + tail) * sampleRate)
            let decay = bell ? 0.35 : 0.5
            for j in 0..<total {
                let idx = startFrame + j
                if idx >= frameCount { break }
                let time = Double(j) / sampleRate
                let attack = min(1.0, time / 0.01)
                let env = attack * exp(-time / decay)
                var s = sin(2 * Double.pi * freq * time)
                if bell {
                    s += 0.4 * sin(4 * Double.pi * freq * time) * exp(-time / 0.15)
                    s += 0.15 * sin(6 * Double.pi * freq * time) * exp(-time / 0.08)
                }
                data[idx] += Float(s * env) * gain
            }
        }

        for n in melody { addNote(midi: n.0, startBeat: n.1, durBeats: n.2, gain: 0.16, bell: true) }
        for n in bass { addNote(midi: n.0, startBeat: n.1, durBeats: n.2, gain: 0.09, bell: false) }

        for i in 0..<frameCount {
            data[i] = max(-0.95, min(0.95, data[i]))
        }
        return buffer
    }

    // MARK: - Síntese dos efeitos

    private static func renderSFX(_ sfx: SFX, sampleRate: Double, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let dur: Double
        switch sfx {
        case .pop: dur = 0.14
        case .nom: dur = 0.16
        case .boing: dur = 0.30
        case .splash: dur = 0.35
        case .chime: dur = 0.8
        case .bark: dur = 0.15
        case .meow: dur = 0.35
        case .squeak: dur = 0.08
        case .chirp: dur = 0.12
        case .sparkle: dur = 0.40
        }
        let frameCount = Int(dur * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount)) else { return nil }
        buffer.frameLength = AVAudioFrameCount(frameCount)
        guard let data = buffer.floatChannelData?[0] else { return nil }
 
        var noiseState: UInt32 = 12345
        func noise() -> Double {
            noiseState = noiseState &* 1664525 &+ 1013904223
            return Double(noiseState % 20000) / 10000.0 - 1.0
        }
 
        var lowpass = 0.0
        for i in 0..<frameCount {
            let time = Double(i) / sampleRate
            let progress = time / dur
            var s = 0.0
            switch sfx {
            case .pop:
                let f = 650.0 - 380.0 * progress
                s = sin(2 * Double.pi * f * time) * exp(-time / 0.045)
            case .nom:
                let f = 320.0 - 120.0 * progress
                s = sin(2 * Double.pi * f * time) * exp(-time / 0.06)
                s += 0.3 * sin(2 * Double.pi * f * 2.7 * time) * exp(-time / 0.03)
            case .boing:
                let f = 220.0 + 360.0 * progress + 30.0 * sin(2 * Double.pi * 18 * time)
                s = sin(2 * Double.pi * f * time) * exp(-time / 0.14)
            case .splash:
                lowpass += 0.12 * (noise() - lowpass)
                s = lowpass * 2.2 * exp(-time / 0.12)
            case .chime:
                s = sin(2 * Double.pi * 1318.5 * time) * exp(-time / 0.25) * 0.6
                if time > 0.16 {
                    let second = time - 0.16
                    s += sin(2 * Double.pi * 1568.0 * second) * exp(-second / 0.3) * 0.6
                }
            case .bark:
                let f = 280.0 - 150.0 * progress
                s = sin(2 * Double.pi * f * time) * exp(-time / 0.08)
                s += 0.35 * noise() * exp(-time / 0.05)
            case .meow:
                let f = 380.0 + 120.0 * sin(progress * Double.pi)
                s = sin(2 * Double.pi * f * time) * exp(-time / 0.22)
                s += 0.25 * sin(2 * Double.pi * f * 2 * time) * exp(-time / 0.14)
            case .squeak:
                let f = 1100.0 + 900.0 * progress
                s = sin(2 * Double.pi * f * time) * exp(-time / 0.045)
            case .chirp:
                let f = 900.0 + 1300.0 * sin(progress * Double.pi)
                s = sin(2 * Double.pi * f * time) * exp(-time / 0.08)
            case .sparkle:
                s = sin(2 * Double.pi * 987.77 * time) * exp(-time / 0.15) * 0.5
                if time > 0.08 {
                    let second = time - 0.08
                    s += sin(2 * Double.pi * 1318.51 * second) * exp(-second / 0.15) * 0.5
                }
                if time > 0.16 {
                    let third = time - 0.16
                    s += sin(2 * Double.pi * 1568.0 * third) * exp(-third / 0.2) * 0.5
                }
            }
            data[i] = Float(max(-0.9, min(0.9, s * 0.8)))
        }
        return buffer
    }
}
