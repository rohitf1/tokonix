import SwiftUI

struct PhotonBloomField: View {
    let palette: [Color]
    let ribbonCount: Int
    let baseRadius: CGFloat
    let orbit: Bool
    let intensity: Double

    @State private var ribbons: [PhotonRibbon] = []

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                guard !ribbons.isEmpty, !palette.isEmpty else { return }
                let time = timeline.date.timeIntervalSinceReferenceDate
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                context.blendMode = .plusLighter
                context.addFilter(.blur(radius: 3.4))

                for ribbon in ribbons {
                    var path = Path()
                    let steps = 360
                    let spin = (orbit ? time * ribbon.spin : 0) + ribbon.phase
                    for step in 0...steps {
                        let progress = Double(step) / Double(steps)
                        let t = progress * Double.pi * 2 * ribbon.turns
                        let wave = sin(t * ribbon.lobes + time * ribbon.waveSpeed + ribbon.phase)
                        let ripple = 0.68 + 0.22 * cos(t + ribbon.phase * 0.6) + ribbon.wobble * wave
                        let radius = baseRadius * ribbon.radiusScale * ripple
                        let angle = t + spin + wave * 0.35
                        let x = center.x + cos(angle) * radius
                        let y = center.y + sin(angle) * radius * ribbon.squeeze
                        if step == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    let color = palette[ribbon.colorIndex % palette.count]
                    let accent = palette[(ribbon.colorIndex + 2) % palette.count]
                    let alpha = intensity * ribbon.opacity
                    context.stroke(
                        path,
                        with: .color(color.opacity(0.32 * alpha)),
                        lineWidth: ribbon.lineWidth * 5.0
                    )
                    context.stroke(
                        path,
                        with: .color(accent.opacity(0.65 * alpha)),
                        lineWidth: ribbon.lineWidth * 2.2
                    )
                    context.stroke(
                        path,
                        with: .color(Color.white.opacity(0.4 * alpha)),
                        lineWidth: max(1.0, ribbon.lineWidth * 0.8)
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

    private static func makeRibbons(count: Int, paletteCount: Int) -> [PhotonRibbon] {
        (0..<count).map { _ in
            PhotonRibbon(
                phase: Double.random(in: 0...(Double.pi * 2)),
                spin: Double.random(in: 0.08...0.2),
                lineWidth: CGFloat.random(in: 2.4...4.8),
                radiusScale: CGFloat.random(in: 0.88...1.18),
                squeeze: CGFloat.random(in: 0.42...0.78),
                wobble: Double.random(in: 0.14...0.26),
                opacity: Double.random(in: 0.7...1.0),
                colorIndex: Int.random(in: 0..<max(paletteCount, 1)),
                turns: Double.random(in: 1.8...2.6),
                lobes: Double.random(in: 3.0...6.0),
                waveSpeed: Double.random(in: 0.2...0.55)
            )
        }
    }
}

private struct PhotonRibbon: Identifiable {
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
    let lobes: Double
    let waveSpeed: Double
}
