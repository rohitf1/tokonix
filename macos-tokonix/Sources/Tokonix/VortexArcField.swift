import SwiftUI

struct VortexArcField: View {
    let palette: [Color]
    let arcCount: Int
    let baseRadius: CGFloat
    let orbit: Bool
    let intensity: Double

    @State private var arcs: [VortexArc] = []

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                guard !arcs.isEmpty, !palette.isEmpty else { return }
                let time = timeline.date.timeIntervalSinceReferenceDate
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                context.blendMode = .plusLighter
                context.addFilter(.blur(radius: 2.8))

                for arc in arcs {
                    var path = Path()
                    let steps = 240
                    let spin = (orbit ? time * arc.spin : 0) + arc.phase
                    for step in 0...steps {
                        let progress = Double(step) / Double(steps)
                        let travel = arc.start + arc.span * progress
                        let t = travel * Double.pi * 2
                        let ripple = 0.78 + 0.22 * sin(t * arc.ripple + time * arc.rippleSpeed + arc.phase)
                        let flare = 0.7 + 0.3 * abs(sin(t * arc.flare + arc.phase))
                        let wobble = sin(t * 1.6 + arc.phase) * arc.wobble
                        let radius = baseRadius * arc.radiusScale * ripple * flare
                        let angle = t + spin + wobble
                        let x = center.x + cos(angle) * radius
                        let y = center.y + sin(angle) * radius * arc.squeeze
                        if step == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    let color = palette[arc.colorIndex % palette.count]
                    let accent = palette[(arc.colorIndex + 1) % palette.count]
                    let alpha = intensity * arc.opacity
                    context.stroke(
                        path,
                        with: .color(color.opacity(0.32 * alpha)),
                        lineWidth: arc.thickness * 4.6
                    )
                    context.stroke(
                        path,
                        with: .color(accent.opacity(0.78 * alpha)),
                        lineWidth: arc.thickness * 2.0
                    )
                    context.stroke(
                        path,
                        with: .color(Color.white.opacity(0.45 * alpha)),
                        lineWidth: max(1.0, arc.thickness * 0.7)
                    )
                }
            }
        }
        .onAppear {
            if arcs.isEmpty {
                arcs = Self.makeArcs(count: arcCount, paletteCount: palette.count)
            }
        }
    }

    private static func makeArcs(count: Int, paletteCount: Int) -> [VortexArc] {
        (0..<count).map { _ in
            VortexArc(
                phase: Double.random(in: 0...(Double.pi * 2)),
                spin: Double.random(in: 0.06...0.18),
                thickness: CGFloat.random(in: 1.8...4.8),
                radiusScale: CGFloat.random(in: 0.86...1.32),
                squeeze: CGFloat.random(in: 0.26...0.84),
                opacity: Double.random(in: 0.65...1.0),
                colorIndex: Int.random(in: 0..<max(paletteCount, 1)),
                start: Double.random(in: 0...1),
                span: Double.random(in: 0.22...0.58),
                wobble: Double.random(in: 0.18...0.46),
                flare: Double.random(in: 2.4...4.8),
                ripple: Double.random(in: 1.8...3.6),
                rippleSpeed: Double.random(in: 0.12...0.32)
            )
        }
    }
}

private struct VortexArc: Identifiable {
    let id = UUID()
    let phase: Double
    let spin: Double
    let thickness: CGFloat
    let radiusScale: CGFloat
    let squeeze: CGFloat
    let opacity: Double
    let colorIndex: Int
    let start: Double
    let span: Double
    let wobble: Double
    let flare: Double
    let ripple: Double
    let rippleSpeed: Double
}
