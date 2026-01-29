import SwiftUI

struct NebulaSpiralField: View {
    let palette: [Color]
    let strandCount: Int
    let baseRadius: CGFloat
    let orbit: Bool
    let intensity: Double

    @State private var strands: [NebulaStrand] = []

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                guard !strands.isEmpty, !palette.isEmpty else { return }
                let time = timeline.date.timeIntervalSinceReferenceDate
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                context.blendMode = .plusLighter
                context.addFilter(.blur(radius: 2.6))

                for strand in strands {
                    var path = Path()
                    let steps = 420
                    let spin = (orbit ? time * strand.spin : 0) + strand.phase
                    for step in 0...steps {
                        let progress = Double(step) / Double(steps)
                        let t = progress * Double.pi * 2 * strand.turns
                        let wave = sin(t * strand.wave + time * strand.waveSpeed + strand.phase)
                        let flare = abs(sin(t * strand.flare + strand.phase))
                        let ribbonPulse = 0.62 + 0.38 * flare
                        let radius = baseRadius * strand.radiusScale * (0.62 + 0.38 * wave) * ribbonPulse
                        let angle = t + spin + wave * strand.wobble
                        let x = center.x + cos(angle) * radius
                        let y = center.y + sin(angle) * radius * strand.squeeze
                        if step == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    let color = palette[strand.colorIndex % palette.count]
                    let accent = palette[(strand.colorIndex + 2) % palette.count]
                    let alpha = intensity * strand.opacity
                    context.stroke(
                        path,
                        with: .color(color.opacity(0.24 * alpha)),
                        lineWidth: strand.lineWidth * 5.4
                    )
                    context.stroke(
                        path,
                        with: .color(accent.opacity(0.78 * alpha)),
                        lineWidth: strand.lineWidth * 2.3
                    )
                    context.stroke(
                        path,
                        with: .color(Color.white.opacity(0.5 * alpha)),
                        lineWidth: max(1.0, strand.lineWidth * 0.85)
                    )
                }
            }
        }
        .onAppear {
            if strands.isEmpty {
                strands = Self.makeStrands(count: strandCount, paletteCount: palette.count)
            }
        }
    }

    private static func makeStrands(count: Int, paletteCount: Int) -> [NebulaStrand] {
        (0..<count).map { _ in
            NebulaStrand(
                phase: Double.random(in: 0...(Double.pi * 2)),
                spin: Double.random(in: 0.08...0.18),
                lineWidth: CGFloat.random(in: 1.8...3.6),
                radiusScale: CGFloat.random(in: 0.86...1.26),
                squeeze: CGFloat.random(in: 0.3...0.78),
                wobble: Double.random(in: 0.22...0.5),
                opacity: Double.random(in: 0.7...1.0),
                colorIndex: Int.random(in: 0..<max(paletteCount, 1)),
                turns: Double.random(in: 1.6...2.5),
                wave: Double.random(in: 2.4...4.8),
                waveSpeed: Double.random(in: 0.16...0.48),
                flare: Double.random(in: 2.6...5.4)
            )
        }
    }
}

private struct NebulaStrand: Identifiable {
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
    let wave: Double
    let waveSpeed: Double
    let flare: Double
}
