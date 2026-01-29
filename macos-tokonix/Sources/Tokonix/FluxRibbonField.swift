import SwiftUI

struct FluxRibbonField: View {
    let palette: [Color]
    let ribbonCount: Int
    let baseRadius: CGFloat
    let orbit: Bool
    let intensity: Double

    @State private var ribbons: [FluxRibbon] = []

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                guard !ribbons.isEmpty, !palette.isEmpty else { return }
                let time = timeline.date.timeIntervalSinceReferenceDate
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                context.blendMode = .plusLighter
                context.addFilter(.blur(radius: 3.1))

                for ribbon in ribbons {
                    var path = Path()
                    let steps = 380
                    let spin = (orbit ? time * ribbon.spin : 0) + ribbon.phase
                    for step in 0...steps {
                        let progress = Double(step) / Double(steps)
                        let t = progress * Double.pi * 2 * ribbon.turns
                        let wave = sin(t * ribbon.wave + time * ribbon.waveSpeed + ribbon.phase)
                        let flare = 0.72 + 0.28 * cos(t * ribbon.flare + ribbon.phase)
                        let corkscrew = sin(t * ribbon.corkscrew + time * ribbon.corkscrewSpeed + ribbon.phase)
                        let radius = baseRadius * ribbon.radiusScale * (0.68 + 0.32 * wave) * flare
                        let angle = t + spin + wave * 0.42 + corkscrew * 0.24
                        let x = center.x + cos(angle) * radius
                        let y = center.y + sin(angle) * radius * ribbon.squeeze
                        if step == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }

                    let color = palette[ribbon.colorIndex % palette.count]
                    let accent = palette[(ribbon.colorIndex + 1) % palette.count]
                    let alpha = intensity * ribbon.opacity
                    let gradient = GraphicsContext.Shading.linearGradient(
                        Gradient(colors: [
                            color.opacity(0.35 * alpha),
                            accent.opacity(0.85 * alpha),
                            Color.white.opacity(0.6 * alpha),
                            accent.opacity(0.35 * alpha),
                        ]),
                        startPoint: CGPoint(x: center.x - baseRadius, y: center.y - baseRadius * 0.45),
                        endPoint: CGPoint(x: center.x + baseRadius, y: center.y + baseRadius * 0.5)
                    )

                    context.stroke(path, with: gradient, lineWidth: ribbon.lineWidth * 4.2)
                    context.stroke(
                        path,
                        with: .color(accent.opacity(0.9 * alpha)),
                        lineWidth: ribbon.lineWidth * 1.6
                    )
                    context.stroke(
                        path,
                        with: .color(Color.white.opacity(0.55 * alpha)),
                        lineWidth: max(1.0, ribbon.lineWidth * 0.7)
                    )
                }
            }
        }
        .onAppear {
            if ribbons.isEmpty {
                ribbons = Self.makeRibbons(count: ribbonCount, paletteCount: palette.count)
            }
        }
    }

    private static func makeRibbons(count: Int, paletteCount: Int) -> [FluxRibbon] {
        (0..<count).map { _ in
            FluxRibbon(
                phase: Double.random(in: 0...(Double.pi * 2)),
                spin: Double.random(in: 0.08...0.2),
                lineWidth: CGFloat.random(in: 2.2...4.4),
                radiusScale: CGFloat.random(in: 0.86...1.24),
                squeeze: CGFloat.random(in: 0.28...0.78),
                opacity: Double.random(in: 0.65...1.0),
                colorIndex: Int.random(in: 0..<max(paletteCount, 1)),
                turns: Double.random(in: 2.1...3.1),
                wave: Double.random(in: 2.8...5.6),
                waveSpeed: Double.random(in: 0.18...0.48),
                flare: Double.random(in: 2.2...4.8),
                corkscrew: Double.random(in: 1.6...3.4),
                corkscrewSpeed: Double.random(in: 0.14...0.38)
            )
        }
    }
}

private struct FluxRibbon: Identifiable {
    let id = UUID()
    let phase: Double
    let spin: Double
    let lineWidth: CGFloat
    let radiusScale: CGFloat
    let squeeze: CGFloat
    let opacity: Double
    let colorIndex: Int
    let turns: Double
    let wave: Double
    let waveSpeed: Double
    let flare: Double
    let corkscrew: Double
    let corkscrewSpeed: Double
}
