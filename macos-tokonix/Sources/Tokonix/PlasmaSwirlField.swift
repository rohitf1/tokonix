import SwiftUI

struct PlasmaSwirlField: View {
    let palette: [Color]
    let swirlCount: Int
    let baseRadius: CGFloat
    let orbit: Bool
    let intensity: Double

    @State private var swirls: [SwirlRibbon] = []

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                guard !swirls.isEmpty, !palette.isEmpty else { return }
                let time = timeline.date.timeIntervalSinceReferenceDate
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                context.blendMode = .plusLighter
                context.addFilter(.blur(radius: 3.2))

                for swirl in swirls {
                    var path = Path()
                    let steps = 320
                    let spin = (orbit ? time * swirl.speed : 0) + swirl.phase
                    for step in 0...steps {
                        let progress = Double(step) / Double(steps)
                        let t = progress * Double.pi * 2 * swirl.turns
                        let wobble = sin(t * swirl.lobes + swirl.phase) * swirl.wobble
                        let radiusPulse = 0.7 + 0.3 * cos(t + swirl.phase * 1.1)
                        let radius = baseRadius * swirl.radiusScale * radiusPulse
                        let angle = t + spin + wobble
                        let x = center.x + cos(angle) * radius
                        let y = center.y + sin(angle) * radius * swirl.squeeze
                        if step == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    let color = palette[swirl.colorIndex % palette.count]
                    let glow = color.opacity(0.45 * intensity * swirl.opacity)
                    context.stroke(path, with: .color(glow), lineWidth: swirl.lineWidth * 4.0)
                    context.stroke(
                        path,
                        with: .color(color.opacity(0.85 * intensity * swirl.opacity)),
                        lineWidth: swirl.lineWidth
                    )
                    context.stroke(
                        path,
                        with: .color(Color.white.opacity(0.35 * intensity * swirl.opacity)),
                        lineWidth: max(1.0, swirl.lineWidth * 0.55)
                    )
                }
            }
        }
        .onAppear {
            if swirls.isEmpty {
                swirls = Self.makeSwirls(count: swirlCount)
            }
        }
    }

    private static func makeSwirls(count: Int) -> [SwirlRibbon] {
        (0..<count).map { _ in
            SwirlRibbon(
                phase: Double.random(in: 0...(Double.pi * 2)),
                speed: Double.random(in: 0.16...0.36),
                lineWidth: CGFloat.random(in: 1.8...4.4),
                radiusScale: CGFloat.random(in: 0.85...1.4),
                squeeze: CGFloat.random(in: 0.32...0.78),
                wobble: Double.random(in: 0.2...0.46),
                opacity: Double.random(in: 0.65...1.0),
                colorIndex: Int.random(in: 0..<12),
                turns: Double.random(in: 3.0...4.8),
                lobes: Double.random(in: 4.6...9.2)
            )
        }
    }
}

private struct SwirlRibbon: Identifiable {
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
    let lobes: Double
}
