import SwiftUI

struct SpectralHaloField: View {
    let palette: [Color]
    let ribbonCount: Int
    let baseRadius: CGFloat
    let orbit: Bool
    let intensity: Double

    @State private var ribbons: [HaloRibbon] = []

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                guard !ribbons.isEmpty, !palette.isEmpty else { return }
                let time = timeline.date.timeIntervalSinceReferenceDate
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                context.blendMode = .plusLighter
                context.addFilter(.blur(radius: 4.1))

                for ribbon in ribbons {
                    var path = Path()
                    let steps = 320
                    let spin = (orbit ? time * ribbon.spin : 0) + ribbon.phase
                    for step in 0...steps {
                        let progress = Double(step) / Double(steps)
                        let t = progress * Double.pi * 2 * ribbon.turns
                        let wave = sin(t * ribbon.wave + time * ribbon.waveSpeed + ribbon.phase) * ribbon.wobble
                        let radiusPulse = 0.78 + 0.22 * cos(t + ribbon.phase * 0.6)
                        let radius = baseRadius * ribbon.radiusScale * radiusPulse
                        let angle = t + spin + wave
                        let x = center.x + cos(angle) * radius
                        let y = center.y + sin(angle) * radius * ribbon.squeeze
                        if step == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    let color = palette[ribbon.colorIndex % palette.count]
                    let alpha = intensity * ribbon.opacity
                    context.stroke(
                        path,
                        with: .color(color.opacity(0.35 * alpha)),
                        lineWidth: ribbon.lineWidth * 4.8
                    )
                    context.stroke(
                        path,
                        with: .color(color.opacity(0.95 * alpha)),
                        lineWidth: ribbon.lineWidth
                    )
                    context.stroke(
                        path,
                        with: .color(Color.white.opacity(0.45 * alpha)),
                        lineWidth: max(1.0, ribbon.lineWidth * 0.6)
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

    private static func makeRibbons(count: Int, paletteCount: Int) -> [HaloRibbon] {
        (0..<count).map { _ in
            HaloRibbon(
                phase: Double.random(in: 0...(Double.pi * 2)),
                spin: Double.random(in: 0.07...0.22),
                lineWidth: CGFloat.random(in: 2.6...5.6),
                radiusScale: CGFloat.random(in: 0.85...1.45),
                squeeze: CGFloat.random(in: 0.24...0.7),
                wobble: Double.random(in: 0.2...0.5),
                opacity: Double.random(in: 0.65...1.0),
                colorIndex: Int.random(in: 0..<max(paletteCount, 1)),
                turns: Double.random(in: 2.2...3.6),
                wave: Double.random(in: 3.0...6.2),
                waveSpeed: Double.random(in: 0.2...0.55)
            )
        }
    }
}

private struct HaloRibbon: Identifiable {
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
}
