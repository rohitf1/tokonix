import SwiftUI

struct AuroraPetalField: View {
    let palette: [Color]
    let petalCount: Int
    let baseRadius: CGFloat
    let orbit: Bool
    let intensity: Double

    @State private var petals: [AuroraPetal] = []

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                guard !petals.isEmpty, !palette.isEmpty else { return }
                let time = timeline.date.timeIntervalSinceReferenceDate
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                context.blendMode = .plusLighter
                context.addFilter(.blur(radius: 3.0))

                for petal in petals {
                    var path = Path()
                    let steps = 400
                    let spin = (orbit ? time * petal.spin : 0) + petal.phase
                    for step in 0...steps {
                        let progress = Double(step) / Double(steps)
                        let t = progress * Double.pi * 2 * petal.turns
                        let petalWave = abs(sin(t * petal.petals + petal.phase))
                        let ripple = 0.74 + 0.26 * sin(t * petal.wave + time * petal.waveSpeed + petal.phase)
                        let radius = baseRadius * petal.radiusScale * (0.35 + 0.65 * petalWave) * ripple
                        let angle = t + spin + petalWave * petal.wobble
                        let x = center.x + cos(angle) * radius
                        let y = center.y + sin(angle) * radius * petal.squeeze
                        if step == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    let color = palette[petal.colorIndex % palette.count]
                    let accent = palette[(petal.colorIndex + 1) % palette.count]
                    let alpha = intensity * petal.opacity
                    context.stroke(
                        path,
                        with: .color(color.opacity(0.32 * alpha)),
                        lineWidth: petal.lineWidth * 4.6
                    )
                    context.stroke(
                        path,
                        with: .color(accent.opacity(0.7 * alpha)),
                        lineWidth: petal.lineWidth * 2.1
                    )
                    context.stroke(
                        path,
                        with: .color(Color.white.opacity(0.45 * alpha)),
                        lineWidth: max(1.0, petal.lineWidth * 0.8)
                    )
                }
            }
        }
        .onAppear {
            if petals.isEmpty {
                petals = Self.makePetals(count: petalCount, paletteCount: palette.count)
            }
        }
    }

    private static func makePetals(count: Int, paletteCount: Int) -> [AuroraPetal] {
        (0..<count).map { _ in
            AuroraPetal(
                phase: Double.random(in: 0...(Double.pi * 2)),
                spin: Double.random(in: 0.12...0.28),
                lineWidth: CGFloat.random(in: 2.0...4.6),
                radiusScale: CGFloat.random(in: 0.86...1.24),
                squeeze: CGFloat.random(in: 0.3...0.78),
                wobble: Double.random(in: 0.22...0.52),
                opacity: Double.random(in: 0.7...1.0),
                colorIndex: Int.random(in: 0..<max(paletteCount, 1)),
                turns: Double.random(in: 1.6...2.5),
                petals: Double.random(in: 3.8...6.6),
                wave: Double.random(in: 2.4...4.6),
                waveSpeed: Double.random(in: 0.2...0.55)
            )
        }
    }
}

private struct AuroraPetal: Identifiable {
    let id = UUID()
    let phase: Double
    let spin: Double
    let lineWidth: CGFloat
    let radiusScale: CGFloat
    let squeeze: CGFloat
    let wobble: Double
    let opacity: Double
    let colorIndex: Int
    let turns: Double
    let petals: Double
    let wave: Double
    let waveSpeed: Double
}
