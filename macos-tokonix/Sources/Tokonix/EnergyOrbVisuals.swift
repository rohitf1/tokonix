import SwiftUI

struct EnergyOrb: View {
    let isListening: Bool
    let isBusy: Bool
    let pulse: Bool
    let orbit: Bool
    let drift: Bool
    let isHovering: Bool

    var body: some View {
        ZStack {
            OrbBackplate(intensity: isHovering ? 1.18 : 0.98, pulse: pulse)

            AuraField(pulse: pulse, drift: drift, colors: auraColors)
                .frame(width: OverlayLayout.orbFieldSize, height: OverlayLayout.orbFieldSize)

            PhotonBloomField(
                palette: bloomPalette,
                ribbonCount: 13,
                baseRadius: OverlayLayout.orbFieldSize * 0.76,
                orbit: orbit,
                intensity: isHovering ? 1.7 : 1.4
            )
            .frame(width: OverlayLayout.orbFieldSize, height: OverlayLayout.orbFieldSize)
            .opacity(isListening ? 1.0 : 0.9)

            FluxRibbonField(
                palette: bloomPalette,
                ribbonCount: 10,
                baseRadius: OverlayLayout.orbFieldSize * 0.79,
                orbit: orbit,
                intensity: isHovering ? 1.7 : 1.35
            )
            .frame(width: OverlayLayout.orbFieldSize, height: OverlayLayout.orbFieldSize)
            .opacity(isListening ? 1.0 : 0.94)

            NebulaSpiralField(
                palette: bloomPalette,
                strandCount: 12,
                baseRadius: OverlayLayout.orbFieldSize * 0.78,
                orbit: orbit,
                intensity: isHovering ? 1.65 : 1.3
            )
            .frame(width: OverlayLayout.orbFieldSize, height: OverlayLayout.orbFieldSize)
            .opacity(isListening ? 1.0 : 0.92)

            VortexArcField(
                palette: bloomPalette,
                arcCount: 16,
                baseRadius: OverlayLayout.orbFieldSize * 0.8,
                orbit: orbit,
                intensity: isHovering ? 1.75 : 1.45
            )
            .frame(width: OverlayLayout.orbFieldSize, height: OverlayLayout.orbFieldSize)
            .opacity(isListening ? 1.0 : 0.92)

            AuroraPetalField(
                palette: bloomPalette,
                petalCount: 12,
                baseRadius: OverlayLayout.orbFieldSize * 0.72,
                orbit: orbit,
                intensity: isHovering ? 1.8 : 1.45
            )
            .frame(width: OverlayLayout.orbFieldSize, height: OverlayLayout.orbFieldSize)
            .opacity(isListening ? 1.0 : 0.92)

            SpectralHaloField(
                palette: ringPalette,
                ribbonCount: 18,
                baseRadius: OverlayLayout.orbFieldSize * 0.68,
                orbit: orbit,
                intensity: isHovering ? 1.85 : 1.5
            )
            .frame(width: OverlayLayout.orbFieldSize, height: OverlayLayout.orbFieldSize)
            .opacity(isListening ? 1.0 : 0.92)

            PlasmaSwirlField(
                palette: swirlPalette,
                swirlCount: 32,
                baseRadius: OverlayLayout.orbFieldSize * 0.62,
                orbit: orbit,
                intensity: isHovering ? 1.7 : 1.35
            )
            .frame(width: OverlayLayout.orbFieldSize, height: OverlayLayout.orbFieldSize)
            .opacity(isListening ? 1.0 : 0.92)

            FilamentField(
                palette: filamentPalette,
                lineCount: 56,
                baseRadius: OverlayLayout.orbFieldSize * 0.56,
                orbit: orbit,
                intensity: isHovering ? 1.6 : 1.28
            )
            .frame(width: OverlayLayout.orbFieldSize, height: OverlayLayout.orbFieldSize)
            .opacity(isListening ? 0.98 : 0.88)

            ParticleField(
                palette: particlePalette,
                count: 420,
                driftBoost: isHovering ? 2.6 : 1.8
            )
            .frame(width: OverlayLayout.orbFieldSize * 1.18, height: OverlayLayout.orbFieldSize * 1.18)
            .blendMode(.plusLighter)
            .opacity(isHovering ? 0.98 : 0.86)

            OrbCore(
                coreGradient: coreGradient,
                ringPalette: ringPalette,
                orbit: orbit,
                glowColor: glowColor,
                isHovering: isHovering,
                pulse: pulse
            )
            .frame(width: OverlayLayout.orbSize, height: OverlayLayout.orbSize)
        }
        .frame(width: OverlayLayout.orbFieldSize, height: OverlayLayout.orbFieldSize)
        .scaleEffect(pulse ? 1.08 : 0.96)
        .animation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true), value: pulse)
    }

    private var coreGradient: RadialGradient {
        RadialGradient(
            colors: [Color.white.opacity(0.98)] + coreColors + [coreAccent.opacity(0.45), OverlayPalette.deepSpace],
            center: .center,
            startRadius: 4,
            endRadius: OverlayLayout.orbSize * 0.7
        )
    }

    private var coreColors: [Color] {
        if isListening { return [OverlayPalette.lime, OverlayPalette.cyan, OverlayPalette.teal] }
        if isBusy { return [OverlayPalette.magenta, OverlayPalette.electricPurple, OverlayPalette.pink] }
        return [OverlayPalette.neonBlue, OverlayPalette.electricPurple, OverlayPalette.magenta]
    }

    private var coreAccent: Color {
        if isListening { return OverlayPalette.cyan }
        if isBusy { return OverlayPalette.magenta }
        return OverlayPalette.pink
    }

    private var auraColors: [Color] {
        if isListening {
            return [OverlayPalette.cyan, OverlayPalette.lime, OverlayPalette.teal, OverlayPalette.neonBlue]
        }
        if isBusy {
            return [OverlayPalette.magenta, OverlayPalette.electricPurple, OverlayPalette.neonBlue, OverlayPalette.cyan]
        }
        return [OverlayPalette.cyan, OverlayPalette.neonBlue, OverlayPalette.electricPurple, OverlayPalette.magenta]
    }

    private var ringPalette: [Color] {
        [
            OverlayPalette.cyan,
            OverlayPalette.neonBlue,
            OverlayPalette.electricPurple,
            OverlayPalette.magenta,
            OverlayPalette.pink,
            OverlayPalette.lime,
            OverlayPalette.cyan,
        ]
    }

    private var bloomPalette: [Color] {
        [
            OverlayPalette.neonBlue,
            OverlayPalette.cyan,
            OverlayPalette.electricPurple,
            OverlayPalette.magenta,
            OverlayPalette.pink,
            OverlayPalette.teal,
            OverlayPalette.lime,
        ]
    }

    private var filamentPalette: [Color] {
        [
            OverlayPalette.cyan,
            OverlayPalette.neonBlue,
            OverlayPalette.electricPurple,
            OverlayPalette.magenta,
            OverlayPalette.pink,
            OverlayPalette.teal,
        ]
    }

    private var swirlPalette: [Color] {
        [
            OverlayPalette.cyan,
            OverlayPalette.neonBlue,
            OverlayPalette.electricPurple,
            OverlayPalette.magenta,
            OverlayPalette.pink,
            OverlayPalette.teal,
            OverlayPalette.lime,
        ]
    }

    private var particlePalette: [Color] {
        if isListening { return [OverlayPalette.cyan, OverlayPalette.lime, OverlayPalette.teal, OverlayPalette.neonBlue] }
        if isBusy { return [OverlayPalette.magenta, OverlayPalette.pink, OverlayPalette.electricPurple, OverlayPalette.cyan] }
        return [OverlayPalette.cyan, OverlayPalette.neonBlue, OverlayPalette.electricPurple, OverlayPalette.magenta, OverlayPalette.pink]
    }

    private var glowColor: Color {
        if isListening { return OverlayPalette.lime }
        if isBusy { return OverlayPalette.magenta }
        return OverlayPalette.cyan
    }
}

private struct OrbBackplate: View {
    let intensity: Double
    let pulse: Bool

    var body: some View {
        let glow = pulse ? 1.08 : 0.94
        let halo = pulse ? 1.04 : 0.96

        return ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            OverlayPalette.midnight.opacity(0.92),
                            OverlayPalette.deepSpace.opacity(0.65),
                            Color.clear,
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: OverlayLayout.orbFieldSize * 0.9
                    )
                )
                .frame(width: OverlayLayout.orbFieldSize * 1.06, height: OverlayLayout.orbFieldSize * 1.06)
                .blur(radius: 56)
                .opacity(intensity * glow)
                .scaleEffect(pulse ? 1.02 : 0.99)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            OverlayPalette.midnight.opacity(0.95),
                            OverlayPalette.deepSpace.opacity(0.55),
                            OverlayPalette.neonBlue.opacity(0.24),
                            OverlayPalette.electricPurple.opacity(0.18),
                            Color.clear,
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: OverlayLayout.orbFieldSize * 0.68
                    )
                )
                .frame(width: OverlayLayout.orbFieldSize * 0.98, height: OverlayLayout.orbFieldSize * 0.98)
                .blur(radius: 44)
                .opacity(intensity * glow)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            OverlayPalette.cyan.opacity(0.45),
                            OverlayPalette.magenta.opacity(0.26),
                            OverlayPalette.neonBlue.opacity(0.22),
                            Color.clear,
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: OverlayLayout.orbFieldSize * 0.52
                    )
                )
                .frame(width: OverlayLayout.orbFieldSize * 0.78, height: OverlayLayout.orbFieldSize * 0.78)
                .blur(radius: 34)
                .blendMode(.plusLighter)
                .opacity(intensity * halo)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.2),
                            OverlayPalette.cyan.opacity(0.12),
                            OverlayPalette.magenta.opacity(0.08),
                            Color.clear,
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: OverlayLayout.orbFieldSize * 0.34
                    )
                )
                .frame(width: OverlayLayout.orbFieldSize * 0.48, height: OverlayLayout.orbFieldSize * 0.48)
                .blur(radius: 24)
                .blendMode(.plusLighter)
                .opacity(intensity * (pulse ? 1.02 : 0.92))

            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            OverlayPalette.cyan.opacity(0.38),
                            OverlayPalette.magenta.opacity(0.48),
                            OverlayPalette.neonBlue.opacity(0.36),
                            OverlayPalette.pink.opacity(0.42),
                            OverlayPalette.cyan.opacity(0.38),
                        ],
                        center: .center
                    ),
                    lineWidth: 10
                )
                .frame(width: OverlayLayout.orbFieldSize * 0.82, height: OverlayLayout.orbFieldSize * 0.82)
                .blur(radius: 18)
                .blendMode(.plusLighter)
                .opacity(intensity * (pulse ? 0.72 : 0.6))

            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            OverlayPalette.neonBlue.opacity(0.45),
                            OverlayPalette.electricPurple.opacity(0.46),
                            OverlayPalette.cyan.opacity(0.4),
                            OverlayPalette.magenta.opacity(0.38),
                            OverlayPalette.neonBlue.opacity(0.45),
                        ],
                        center: .center
                    ),
                    lineWidth: 6
                )
                .frame(width: OverlayLayout.orbFieldSize * 0.64, height: OverlayLayout.orbFieldSize * 0.64)
                .blur(radius: 12)
                .blendMode(.plusLighter)
                .opacity(intensity * (pulse ? 0.6 : 0.52))
        }
    }
}

private struct OrbCore: View {
    let coreGradient: RadialGradient
    let ringPalette: [Color]
    let orbit: Bool
    let glowColor: Color
    let isHovering: Bool
    let pulse: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(coreGradient)
                .shadow(color: glowColor.opacity(isHovering ? 0.95 : 0.7), radius: isHovering ? 52 : 38)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [glowColor.opacity(0.6), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: OverlayLayout.orbSize * 0.74
                    )
                )
                .frame(width: OverlayLayout.orbSize * 1.12, height: OverlayLayout.orbSize * 1.12)
                .blur(radius: 28)
                .opacity(pulse ? 0.7 : 0.55)
                .blendMode(.plusLighter)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.95), glowColor.opacity(0.6), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: OverlayLayout.orbSize * 0.58
                    )
                )
                .frame(width: OverlayLayout.orbSize * 0.9, height: OverlayLayout.orbSize * 0.9)
                .blendMode(.plusLighter)
                .opacity(pulse ? 0.95 : 0.8)
                .scaleEffect(pulse ? 1.06 : 0.98)

            Circle()
                .fill(Color.white.opacity(0.95))
                .frame(width: OverlayLayout.orbSize * 0.24, height: OverlayLayout.orbSize * 0.24)
                .blur(radius: 7)
                .blendMode(.plusLighter)
                .opacity(pulse ? 0.95 : 0.75)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.98), glowColor.opacity(0.25), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: OverlayLayout.orbSize * 0.32
                    )
                )
                .frame(width: OverlayLayout.orbSize * 0.5, height: OverlayLayout.orbSize * 0.5)
                .opacity(pulse ? 0.92 : 0.72)
                .scaleEffect(pulse ? 1.08 : 0.92)
                .blendMode(.plusLighter)

            Circle()
                .stroke(AngularGradient(colors: ringPalette, center: .center), lineWidth: 2.2)
                .frame(width: OverlayLayout.orbSize * 0.92, height: OverlayLayout.orbSize * 0.92)
                .blur(radius: 2)
                .rotationEffect(.degrees(orbit ? 360 : 0))
                .animation(.linear(duration: 22).repeatForever(autoreverses: false), value: orbit)

            OrbArc(
                size: OverlayLayout.orbSize * 0.74,
                lineWidth: 4,
                colors: [OverlayPalette.cyan.opacity(0.98), OverlayPalette.magenta.opacity(0.72)],
                start: 0.02,
                end: 0.86,
                rotation: 14,
                speed: 14,
                orbit: orbit
            )

            OrbArc(
                size: OverlayLayout.orbSize * 0.64,
                lineWidth: 3,
                colors: [OverlayPalette.neonBlue.opacity(0.92), OverlayPalette.pink.opacity(0.7)],
                start: 0.1,
                end: 0.72,
                rotation: -36,
                speed: 18,
                orbit: orbit
            )

            OrbArc(
                size: OverlayLayout.orbSize * 0.84,
                lineWidth: 2.2,
                colors: [OverlayPalette.teal.opacity(0.82), OverlayPalette.pink.opacity(0.65)],
                start: 0.18,
                end: 0.7,
                rotation: 62,
                speed: 24,
                orbit: orbit
            )

            RibbonRing(
                size: OverlayLayout.orbSize * 0.9,
                thickness: 2.8,
                rotation: -12,
                speed: 26,
                orbit: orbit,
                gradient: [OverlayPalette.cyan.opacity(0.75), OverlayPalette.electricPurple.opacity(0.6)],
                squeeze: 0.16
            )

            RibbonRing(
                size: OverlayLayout.orbSize * 0.7,
                thickness: 2.2,
                rotation: 28,
                speed: 20,
                orbit: orbit,
                gradient: [OverlayPalette.magenta.opacity(0.5), OverlayPalette.neonBlue.opacity(0.7)],
                squeeze: 0.2
            )

            RibbonRing(
                size: OverlayLayout.orbSize * 0.96,
                thickness: 1.6,
                rotation: 60,
                speed: 30,
                orbit: orbit,
                gradient: [OverlayPalette.magenta.opacity(0.4), OverlayPalette.cyan.opacity(0.6)],
                squeeze: 0.14
            )

            RibbonRing(
                size: OverlayLayout.orbSize * 1.02,
                thickness: 1.2,
                rotation: -48,
                speed: 34,
                orbit: orbit,
                gradient: [OverlayPalette.pink.opacity(0.55), OverlayPalette.neonBlue.opacity(0.5)],
                squeeze: 0.12
            )

            OrbArc(
                size: OverlayLayout.orbSize * 0.52,
                lineWidth: 2.2,
                colors: [OverlayPalette.teal.opacity(0.9), OverlayPalette.magenta.opacity(0.7)],
                start: 0.06,
                end: 0.9,
                rotation: -18,
                speed: 16,
                orbit: orbit
            )

            OrbArc(
                size: OverlayLayout.orbSize * 0.98,
                lineWidth: 1.4,
                colors: [OverlayPalette.pink.opacity(0.55), OverlayPalette.cyan.opacity(0.7)],
                start: 0.22,
                end: 0.78,
                rotation: 82,
                speed: 34,
                orbit: orbit
            )

            Circle()
                .stroke(
                    RadialGradient(
                        colors: [glowColor.opacity(0.75), Color.clear],
                        center: .center,
                        startRadius: 4,
                        endRadius: OverlayLayout.orbSize * 0.44
                    ),
                    lineWidth: 10
                )
                .frame(width: OverlayLayout.orbSize * 0.72, height: OverlayLayout.orbSize * 0.72)
                .blur(radius: 12)
                .opacity(pulse ? 0.75 : 0.5)
                .scaleEffect(pulse ? 1.08 : 0.95)

            Circle()
                .stroke(
                    LinearGradient(
                        colors: [glowColor.opacity(0.65), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 8
                )
                .frame(width: OverlayLayout.orbSize * 0.66, height: OverlayLayout.orbSize * 0.66)
                .blur(radius: 7)
                .opacity(isHovering ? 0.95 : 0.7)
        }
    }
}

private struct OrbArc: View {
    let size: CGFloat
    let lineWidth: CGFloat
    let colors: [Color]
    let start: CGFloat
    let end: CGFloat
    let rotation: Double
    let speed: Double
    let orbit: Bool

    var body: some View {
        Circle()
            .trim(from: start, to: end)
            .stroke(
                AngularGradient(colors: colors, center: .center),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
            .frame(width: size, height: size)
            .rotationEffect(.degrees(rotation))
            .rotationEffect(.degrees(orbit ? 360 : 0))
            .animation(.linear(duration: speed).repeatForever(autoreverses: false), value: orbit)
            .blur(radius: 0.8)
    }
}

private struct RibbonRing: View {
    let size: CGFloat
    let thickness: CGFloat
    let rotation: Double
    let speed: Double
    let orbit: Bool
    let gradient: [Color]
    let squeeze: CGFloat

    var body: some View {
        Capsule()
            .stroke(
                LinearGradient(colors: gradient, startPoint: .leading, endPoint: .trailing),
                lineWidth: thickness
            )
            .frame(width: size, height: size * squeeze)
            .rotationEffect(.degrees(rotation))
            .rotationEffect(.degrees(orbit ? 360 : 0))
            .animation(.linear(duration: speed).repeatForever(autoreverses: false), value: orbit)
            .blur(radius: 0.4)
    }
}

struct AuraField: View {
    let pulse: Bool
    let drift: Bool
    let colors: [Color]

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [colors[0].opacity(pulse ? 0.95 : 0.7), Color.clear],
                        center: .center,
                        startRadius: 12,
                        endRadius: OverlayLayout.orbFieldSize * 0.82
                    )
                )
                .frame(width: OverlayLayout.orbFieldSize * 1.14, height: OverlayLayout.orbFieldSize * 1.14)
                .blur(radius: 104)
                .offset(x: drift ? 150 : -150, y: drift ? -120 : 120)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [colors[1].opacity(0.72), Color.clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: OverlayLayout.orbFieldSize * 0.78
                    )
                )
                .frame(width: OverlayLayout.orbFieldSize * 1.06, height: OverlayLayout.orbFieldSize * 1.06)
                .blur(radius: 92)
                .offset(x: drift ? -130 : 130, y: drift ? 130 : -130)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [colors[2].opacity(0.65), Color.clear],
                        center: .center,
                        startRadius: 8,
                        endRadius: OverlayLayout.orbFieldSize * 0.72
                    )
                )
                .frame(width: OverlayLayout.orbFieldSize * 0.98, height: OverlayLayout.orbFieldSize * 0.98)
                .blur(radius: 84)
                .offset(x: drift ? 80 : -80, y: drift ? 170 : 170)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [colors[3].opacity(0.58), Color.clear],
                        center: .center,
                        startRadius: 6,
                        endRadius: OverlayLayout.orbFieldSize * 0.66
                    )
                )
                .frame(width: OverlayLayout.orbFieldSize * 0.9, height: OverlayLayout.orbFieldSize * 0.9)
                .blur(radius: 76)
                .offset(x: drift ? -100 : 100, y: drift ? -180 : 180)
        }
        .blendMode(.plusLighter)
        .opacity(pulse ? 1.0 : 0.85)
    }
}

private struct FilamentField: View {
    let palette: [Color]
    let lineCount: Int
    let baseRadius: CGFloat
    let orbit: Bool
    let intensity: Double

    @State private var filaments: [Filament] = []

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                guard !filaments.isEmpty, !palette.isEmpty else { return }
                let time = timeline.date.timeIntervalSinceReferenceDate
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                context.blendMode = .plusLighter
                context.addFilter(.blur(radius: 1.9))

                for filament in filaments {
                    var path = Path()
                    let steps = 160
                    for step in 0...steps {
                        let progress = Double(step) / Double(steps)
                        let spin = orbit ? time * 0.12 : 0
                        let angle = progress * Double.pi * 2 * filament.turns
                            + time * filament.speed
                            + filament.phase
                            + spin
                        let wave = sin(progress * Double.pi * 4 + filament.wobble)
                        let radius = baseRadius * filament.radiusScale * (0.86 + 0.14 * wave)
                        let x = center.x + cos(angle) * radius
                        let y = center.y + sin(angle) * radius * filament.squeeze
                        if step == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    let color = palette[filament.colorIndex % palette.count]
                    context.stroke(
                        path,
                        with: .color(color.opacity(intensity * filament.opacity)),
                        lineWidth: filament.lineWidth
                    )
                }
            }
        }
        .onAppear {
            if filaments.isEmpty {
                filaments = Self.makeFilaments(count: lineCount)
            }
        }
    }

    private static func makeFilaments(count: Int) -> [Filament] {
        (0..<count).map { _ in
            Filament(
                phase: Double.random(in: 0...(Double.pi * 2)),
                speed: Double.random(in: 0.2...0.42),
                lineWidth: CGFloat.random(in: 1.4...3.4),
                radiusScale: CGFloat.random(in: 0.85...1.3),
                squeeze: CGFloat.random(in: 0.44...0.78),
                wobble: Double.random(in: 0...(Double.pi * 2)),
                opacity: Double.random(in: 0.6...0.95),
                colorIndex: Int.random(in: 0..<8),
                turns: Double.random(in: 2.6...4.2)
            )
        }
    }
}

private struct Filament: Identifiable {
    let id = UUID()
    let phase: Double
    let speed: Double
    let lineWidth: CGFloat
    let radiusScale: CGFloat
    let squeeze: CGFloat
    let wobble: Double
    let opacity: Double
    let colorIndex: Int
    let turns: Double
}

private struct ParticleField: View {
    let palette: [Color]
    let count: Int
    let driftBoost: Double

    @State private var particles: [Particle] = []

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                guard !particles.isEmpty, !palette.isEmpty else { return }
                let time = timeline.date.timeIntervalSinceReferenceDate
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                context.blendMode = .plusLighter
                context.addFilter(.blur(radius: 1.6))

                for particle in particles {
                    let phase = time * particle.speed + particle.phase
                    let angle = particle.angle + phase
                    let drift = (time * particle.driftSpeed * driftBoost + particle.driftPhase)
                        .truncatingRemainder(dividingBy: 1)
                    let radius = particle.radius + CGFloat(drift) * particle.driftRange
                    let x = center.x + cos(angle) * radius
                    let y = center.y + sin(angle * 1.3) * radius * 0.6
                    let twinkle = 0.3 + 0.7 * sin(phase + particle.twinkle)
                    let fade = max(0.05, 1 - drift)
                    let alpha = max(0.2, min(1.0, twinkle * fade * 1.35))
                    let sizeScale = 0.6 + fade * 0.7
                    let color = palette[particle.colorIndex % palette.count]
                    let size = particle.size * sizeScale
                    let rect = CGRect(
                        x: x - size / 2,
                        y: y - size / 2,
                        width: size,
                        height: size
                    )
                    let glowSize = size * 2.2
                    let glowRect = CGRect(
                        x: x - glowSize / 2,
                        y: y - glowSize / 2,
                        width: glowSize,
                        height: glowSize
                    )
                    context.fill(Path(ellipseIn: glowRect), with: .color(color.opacity(alpha * 0.35)))
                    context.fill(Path(ellipseIn: rect), with: .color(color.opacity(alpha)))
                }
            }
        }
        .onAppear {
            if particles.isEmpty {
                particles = Self.makeParticles(count: count, palette: palette)
            }
        }
    }

    private static func makeParticles(count: Int, palette: [Color]) -> [Particle] {
        (0..<count).map { _ in
            let angle = Double.random(in: 0...(Double.pi * 2))
            let radius = CGFloat.random(in: 60...255)
            let size = CGFloat.random(in: 1.0...5.4)
            let speed = Double.random(in: 0.08...0.28)
            let phase = Double.random(in: 0...(Double.pi * 2))
            let twinkle = Double.random(in: 0...(Double.pi * 2))
            let driftSpeed = Double.random(in: 0.05...0.18)
            let driftPhase = Double.random(in: 0...1)
            let driftRange = CGFloat.random(in: 28...88)
            let colorIndex = Int.random(in: 0..<max(palette.count, 1))
            return Particle(
                radius: radius,
                angle: angle,
                size: size,
                speed: speed,
                phase: phase,
                twinkle: twinkle,
                driftSpeed: driftSpeed,
                driftPhase: driftPhase,
                driftRange: driftRange,
                colorIndex: colorIndex
            )
        }
    }
}

private struct Particle: Identifiable {
    let id = UUID()
    let radius: CGFloat
    let angle: Double
    let size: CGFloat
    let speed: Double
    let phase: Double
    let twinkle: Double
    let driftSpeed: Double
    let driftPhase: Double
    let driftRange: CGFloat
    let colorIndex: Int
}

enum OverlayPalette {
    static let midnight = Color(red: 0.03, green: 0.04, blue: 0.07)
    static let deepSpace = Color(red: 0.04, green: 0.07, blue: 0.12)
    static let neonBlue = Color(red: 0.22, green: 0.55, blue: 0.98)
    static let electricPurple = Color(red: 0.56, green: 0.3, blue: 0.98)
    static let cyan = Color(red: 0.2, green: 0.86, blue: 0.98)
    static let magenta = Color(red: 1.0, green: 0.32, blue: 0.85)
    static let pink = Color(red: 1.0, green: 0.52, blue: 0.86)
    static let lime = Color(red: 0.55, green: 0.98, blue: 0.72)
    static let teal = Color(red: 0.14, green: 0.88, blue: 0.78)
    static let ember = Color(red: 0.98, green: 0.62, blue: 0.4)

    static let userStream = [cyan, neonBlue, magenta, pink]
    static let agentStream = [lime, teal, cyan, electricPurple]
    static let reasoningStream = [cyan, neonBlue, electricPurple, magenta]
}
