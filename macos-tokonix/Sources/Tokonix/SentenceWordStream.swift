import AppKit
import SwiftUI

enum WordStreamSource {
    case user
    case agent
}

struct SentenceWordStream: View {
    let userText: String
    let agentText: String
    let isUserActive: Bool
    let isAgentActive: Bool
    let maxLines: Int
    let maxWidth: CGFloat

    @State private var tokens: [SentenceToken] = []
    @State private var queuedTokens: [SentenceToken] = []
    @State private var processedUserCount = 0
    @State private var processedAgentCount = 0
    @State private var lastUserText = ""
    @State private var lastAgentText = ""
    @State private var userColorIndex = 0
    @State private var agentColorIndex = 0
    @State private var isBursting = false

    private let lineSpacing: CGFloat = 8
    private let wordSpacing: CGFloat = 12
    private let perWordDelay: TimeInterval = 0.06
    private let fontSize: CGFloat = 32
    private let burstDuration: TimeInterval = 0.22

    private var lineHeight: CGFloat {
        fontSize * 1.4
    }

    private var blockHeight: CGFloat {
        lineHeight * CGFloat(maxLines) + lineSpacing * CGFloat(maxLines - 1)
    }

    var body: some View {
        let positions = layoutPositions(for: tokens)

        ZStack {
            ForEach(tokens) { token in
                let targetPosition = positions[token.id] ?? CGPoint(x: maxWidth / 2, y: blockHeight / 2)
                let basePosition = token.isExiting ? (token.lockedPosition ?? targetPosition) : targetPosition
                let offset = token.isExiting ? token.exitOffset : (token.isSettled ? .zero : token.entryOffset)
                let opacity: Double = token.isExiting ? 0 : (token.isSettled ? 1 : 0.35)
                let scale: CGFloat = token.isExiting ? 0.85 : (token.isSettled ? 1.0 : token.entryScale)
                let blur: CGFloat = token.isSettled || token.isExiting ? 0 : 4
                let rotation = token.isExiting ? token.exitRotation : (token.isSettled ? 0 : token.entryRotation)
                let tilt = token.isExiting ? token.exitRotation * 0.35 : (token.isSettled ? 0 : token.entryTilt)

                SentenceTokenView(token: token, fontSize: fontSize)
                    .position(basePosition)
                    .offset(offset)
                    .opacity(opacity)
                    .scaleEffect(scale)
                    .blur(radius: blur)
                    .rotationEffect(.degrees(rotation))
                    .rotation3DEffect(.degrees(tilt), axis: (x: 1, y: 0, z: 0))
                    .animation(burstAnimation(), value: token.isExiting)
            }
        }
        .frame(width: maxWidth, height: blockHeight, alignment: .center)
        .onAppear {
            handleTextUpdate(source: .user, text: userText, isActive: isUserActive)
            handleTextUpdate(source: .agent, text: agentText, isActive: isAgentActive)
        }
        .onChange(of: userText) { _ in
            handleTextUpdate(source: .user, text: userText, isActive: isUserActive)
        }
        .onChange(of: agentText) { _ in
            handleTextUpdate(source: .agent, text: agentText, isActive: isAgentActive)
        }
        .onChange(of: isUserActive) { _ in
            handleTextUpdate(source: .user, text: userText, isActive: isUserActive)
        }
        .onChange(of: isAgentActive) { _ in
            handleTextUpdate(source: .agent, text: agentText, isActive: isAgentActive)
        }
    }

    private func handleTextUpdate(source: WordStreamSource, text: String, isActive: Bool) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            resetAll()
            return
        }

        switch source {
        case .user:
            let previous = lastUserText
            if !previous.isEmpty, !trimmed.hasPrefix(previous) {
                resetAll()
            } else if !isActive, trimmed == previous {
                return
            }
            lastUserText = trimmed
            let words = splitWords(trimmed)
            if words.count < processedUserCount {
                processedUserCount = words.count
            }
            guard words.count > processedUserCount else { return }
            let newWords = Array(words[processedUserCount...])
            processedUserCount = words.count
            enqueueWords(newWords, source: .user)
        case .agent:
            let previous = lastAgentText
            if !previous.isEmpty, !trimmed.hasPrefix(previous) {
                resetAll()
            } else if !isActive, trimmed == previous {
                return
            }
            lastAgentText = trimmed
            let words = splitWords(trimmed)
            if words.count < processedAgentCount {
                processedAgentCount = words.count
            }
            guard words.count > processedAgentCount else { return }
            let newWords = Array(words[processedAgentCount...])
            processedAgentCount = words.count
            enqueueWords(newWords, source: .agent)
        }
    }

    private func enqueueWords(_ words: [String], source: WordStreamSource) {
        guard !words.isEmpty else { return }
        let font = nsFont()
        let palette = source == .user ? OverlayPalette.userStream : OverlayPalette.agentStream
        let startIndex = source == .user ? userColorIndex : agentColorIndex
        var index = startIndex
        let tokens = words.map { word in
            defer { index += 1 }
            return SentenceToken(
                id: UUID(),
                text: word,
                color: palette[index % palette.count],
                width: measureWord(word, font: font),
                isExiting: false,
                isSettled: false,
                entryOffset: makeEntryOffset(),
                exitOffset: makeExitOffset(),
                entryRotation: Double.random(in: -16...16),
                entryTilt: Double.random(in: -10...10),
                entryScale: CGFloat.random(in: 0.55...0.72),
                exitRotation: Double.random(in: -22...22),
                lockedPosition: nil
            )
        }
        if source == .user {
            userColorIndex = index
        } else {
            agentColorIndex = index
        }
        queuedTokens.append(contentsOf: tokens)
        processQueue()
    }

    private func processQueue() {
        guard !isBursting else { return }
        guard !queuedTokens.isEmpty else { return }
        let next = queuedTokens.removeFirst()
        let updated = tokens + [next]
        if lineCount(for: updated) > maxLines {
            burstAndRestart(with: next)
            return
        }
        withAnimation(entryAnimation()) {
            tokens.append(next)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
            settleToken(next.id)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + perWordDelay) {
            processQueue()
        }
    }

    private func settleToken(_ id: UUID) {
        guard let index = tokens.firstIndex(where: { $0.id == id }) else { return }
        withAnimation(entryAnimation()) {
            tokens[index].isSettled = true
        }
    }

    private func burstAndRestart(with next: SentenceToken) {
        isBursting = true
        queuedTokens.insert(next, at: 0)
        let lockedPositions = layoutPositions(for: tokens)
        withAnimation(burstAnimation()) {
            tokens = tokens.map { token in
                var updated = token
                updated.isExiting = true
                updated.isSettled = true
                updated.lockedPosition = lockedPositions[token.id]
                return updated
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + burstDuration) {
            tokens.removeAll()
            isBursting = false
            processQueue()
        }
    }

    private func resetAll() {
        tokens.removeAll()
        queuedTokens.removeAll()
        processedUserCount = 0
        processedAgentCount = 0
        lastUserText = ""
        lastAgentText = ""
        userColorIndex = 0
        agentColorIndex = 0
        isBursting = false
    }

    private func splitWords(_ text: String) -> [String] {
        text.split(whereSeparator: { $0.isWhitespace }).map(String.init)
    }

    private func lineCount(for tokens: [SentenceToken]) -> Int {
        buildLines(for: tokens).count
    }

    private func buildLines(for tokens: [SentenceToken]) -> [[SentenceToken]] {
        guard !tokens.isEmpty else { return [] }
        var lines: [[SentenceToken]] = []
        var current: [SentenceToken] = []
        var width: CGFloat = 0
        for token in tokens {
            let extra = (current.isEmpty ? 0 : wordSpacing) + token.width
            if width + extra > maxWidth, !current.isEmpty {
                lines.append(current)
                current = [token]
                width = token.width
            } else {
                current.append(token)
                width += extra
            }
        }
        if !current.isEmpty {
            lines.append(current)
        }
        return lines
    }

    private func layoutPositions(for tokens: [SentenceToken]) -> [UUID: CGPoint] {
        let lines = buildLines(for: tokens)
        var positions: [UUID: CGPoint] = [:]
        var y = lineHeight / 2
        for line in lines.prefix(maxLines) {
            let wordsWidth = line.reduce(0) { $0 + $1.width }
            let spacingWidth = wordSpacing * CGFloat(max(0, line.count - 1))
            let lineWidth = wordsWidth + spacingWidth
            var x = max(0, (maxWidth - lineWidth) / 2)
            for token in line {
                x += token.width / 2
                positions[token.id] = CGPoint(x: x, y: y)
                x += token.width / 2 + wordSpacing
            }
            y += lineHeight + lineSpacing
        }
        return positions
    }

    private func measureWord(_ word: String, font: NSFont) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let size = (word as NSString).size(withAttributes: attributes)
        return ceil(size.width)
    }

    private func nsFont() -> NSFont {
        NSFont(name: "Avenir Next", size: fontSize) ?? NSFont.systemFont(ofSize: fontSize, weight: .semibold)
    }

    private func makeEntryOffset() -> CGSize {
        let angle = Double.random(in: 0...(Double.pi * 2))
        let radius = OverlayLayout.orbSize * CGFloat.random(in: 0.12...0.3)
        let baseLift = OverlayLayout.orbSize * 0.45
        let x = cos(angle) * radius
        let y = baseLift + sin(angle) * radius * 0.6
        return CGSize(width: x, height: y)
    }

    private func makeExitOffset() -> CGSize {
        let angle = Double.random(in: 0...(Double.pi * 2))
        let radius = OverlayLayout.orbSize * CGFloat.random(in: 0.4...0.7)
        let x = cos(angle) * radius
        let y = sin(angle) * radius
        return CGSize(width: x, height: y)
    }

    private func entryAnimation() -> Animation {
        Animation.timingCurve(0.12, 0.9, 0.22, 1.0, duration: 0.48)
    }

    private func burstAnimation() -> Animation {
        Animation.timingCurve(0.3, 0.0, 0.6, 1.0, duration: burstDuration)
    }
}

private struct SentenceToken: Identifiable {
    let id: UUID
    let text: String
    let color: Color
    let width: CGFloat
    var isExiting: Bool
    var isSettled: Bool
    let entryOffset: CGSize
    let exitOffset: CGSize
    let entryRotation: Double
    let entryTilt: Double
    let entryScale: CGFloat
    let exitRotation: Double
    var lockedPosition: CGPoint?
}

private struct SentenceTokenView: View {
    let token: SentenceToken
    let fontSize: CGFloat

    var body: some View {
        let font = Font.custom("Avenir Next", size: fontSize).weight(.semibold)
        let gradient = LinearGradient(
            colors: [
                OverlayPalette.cyan.opacity(1.0),
                OverlayPalette.neonBlue.opacity(0.98),
                OverlayPalette.magenta.opacity(0.92),
                OverlayPalette.teal.opacity(0.9)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        let glow = OverlayPalette.cyan.opacity(0.7)
        return ZStack {
            Text(token.text)
                .font(font)
                .foregroundStyle(gradient)
                .shadow(color: glow, radius: 12, x: 0, y: 0)
                .shadow(color: OverlayPalette.magenta.opacity(0.6), radius: 16, x: 0, y: 0)

            Text(token.text)
                .font(font)
                .foregroundStyle(gradient.opacity(0.3))
                .blur(radius: 10)
                .opacity(0.55)
        }
    }
}
