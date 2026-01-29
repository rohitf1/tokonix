import SwiftUI

enum WordBurstEmissionStyle {
    case cadenced
    case immediate
}

struct WordBurstStream: View {
    let text: String
    let isActive: Bool
    let palette: [Color]
    let maxActive: Int
    let minInterval: TimeInterval
    let jitter: TimeInterval
    let resetOnShrink: Bool
    let emissionStyle: WordBurstEmissionStyle

    @State private var bursts: [WordBurst] = []
    @State private var processedCount = 0
    @State private var lastText = ""
    @State private var colorIndex = 0
    @State private var lastBurstAt = Date.distantPast
    @State private var streamAngle = Double.random(in: 0...(Double.pi * 2))
    @State private var streamSpin = Double.random(in: 0.18...0.32) * (Bool.random() ? 1 : -1)

    var body: some View {
        ZStack {
            ForEach(bursts) { burst in
                WordBurstLabel(burst: burst)
                    .multilineTextAlignment(.center)
                    .opacity(burst.opacity)
                    .scaleEffect(burst.scale)
                    .blur(radius: burst.blur)
                    .offset(burst.offset)
            }
        }
        .frame(width: OverlayLayout.orbFieldSize, height: OverlayLayout.orbFieldSize)
        .onAppear {
            handleTextChange()
        }
        .onChange(of: text) { _ in
            handleTextChange()
        }
        .onChange(of: isActive) { _ in
            handleTextChange()
        }
    }

    private func handleTextChange() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            bursts.removeAll()
            processedCount = 0
            lastText = trimmed
            lastBurstAt = .distantPast
            streamAngle = Double.random(in: 0...(Double.pi * 2))
            streamSpin = Double.random(in: 0.18...0.32) * (Bool.random() ? 1 : -1)
            return
        }
        if resetOnShrink, trimmed.count < Int(Double(lastText.count) * 0.6) {
            bursts.removeAll()
            processedCount = 0
            lastBurstAt = .distantPast
            streamAngle = Double.random(in: 0...(Double.pi * 2))
            streamSpin = Double.random(in: 0.18...0.32) * (Bool.random() ? 1 : -1)
        }
        lastText = trimmed

        guard isActive else { return }
        let words = trimmed.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        if words.count < processedCount {
            processedCount = words.count
        }
        guard words.count > processedCount else { return }
        let newWords = Array(words[processedCount...])
        processedCount = words.count

        let chunks: [String]
        let useCadence: Bool
        switch emissionStyle {
        case .cadenced:
            chunks = chunkWords(newWords)
            useCadence = true
        case .immediate:
            chunks = newWords
            useCadence = false
        }
        enqueueChunks(chunks, useCadence: useCadence)
    }

    private func chunkWords(_ words: [String]) -> [String] {
        var chunks: [String] = []
        var index = 0
        while index < words.count {
            let remaining = words.count - index
            let maxGroup = words.count > 7 ? 2 : 3
            let groupSize = min(remaining, Int.random(in: 1...maxGroup))
            let chunk = words[index..<index + groupSize].joined(separator: " ")
            chunks.append(chunk)
            index += groupSize
        }
        return chunks
    }

    private func enqueueChunks(_ chunks: [String], useCadence: Bool) {
        guard !chunks.isEmpty else { return }
        let now = Date()
        if !useCadence {
            let elapsed = now.timeIntervalSince(lastBurstAt)
            let baseDelay = max(0, minInterval - elapsed)
            var scheduledAt = now.addingTimeInterval(baseDelay)
            let jitterRange = min(jitter, minInterval * 0.5)
            for chunk in chunks {
                let extra = Double.random(in: 0...jitterRange)
                let delay = scheduledAt.timeIntervalSince(now) + extra
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    enqueueBurst(chunk)
                }
                let pause = chunkHasPunctuation(chunk) ? minInterval * 1.4 : minInterval
                scheduledAt = scheduledAt.addingTimeInterval(pause)
            }
            lastBurstAt = scheduledAt
            return
        }
        let elapsed = now.timeIntervalSince(lastBurstAt)
        let baseDelay = max(0, (minInterval * 0.25) - elapsed)
        var scheduledAt = now.addingTimeInterval(baseDelay)
        for chunk in chunks {
            let cadence = cadence(for: chunk)
            let extra = Double.random(in: 0...jitter)
            let delay = scheduledAt.timeIntervalSince(now) + extra
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                enqueueBurst(chunk)
            }
            scheduledAt = scheduledAt.addingTimeInterval(cadence)
        }
        lastBurstAt = scheduledAt
    }

    private func cadence(for chunk: String) -> TimeInterval {
        let wordCount = max(1, chunk.split(whereSeparator: { $0.isWhitespace }).count)
        let base = minInterval * (0.48 + 0.16 * Double(min(wordCount, 4)))
        let lengthBoost = min(0.35, Double(chunk.count) * 0.014)
        let punctuationBoost: TimeInterval
        if let last = chunk.last, ".!?".contains(last) {
            punctuationBoost = minInterval * 2.6
        } else {
            punctuationBoost = 0
        }
        return (base + lengthBoost + punctuationBoost) * Double.random(in: 0.6...1.5)
    }

    private func enqueueBurst(_ text: String) {
        let id = UUID()
        let isImmediate = emissionStyle == .immediate
        let angle = streamAngle + Double.random(in: -0.55...0.55)
        advanceStreamAngle()
        let minRadius = OverlayLayout.orbSize * 0.04
        let maxRadius = OverlayLayout.orbSize * 0.86
        let radius = CGFloat.random(in: minRadius...maxRadius)
        let baseX = cos(angle) * radius
        let baseY = sin(angle) * radius * 0.82
        let entryOffset = CGSize(width: baseX * 0.06, height: baseY * 0.06)
        let outward = CGFloat.random(in: 3.0...3.9)
        let spiral = CGFloat.random(in: -0.85...0.85)
        let spiralAngle = angle + Double(spiral)
        let spiralKick = CGSize(
            width: cos(spiralAngle) * CGFloat.random(in: 80...190),
            height: sin(spiralAngle) * CGFloat.random(in: 80...190)
        )
        let curveDirection = Bool.random() ? 1.0 : -1.0
        let curveAngle = angle + (Double.pi / 2) * curveDirection
        let curveKick = CGSize(
            width: cos(curveAngle) * CGFloat.random(in: 70...160),
            height: sin(curveAngle) * CGFloat.random(in: 70...160)
        )
        let lift = CGFloat.random(in: 120...240)
        let exitOffset = CGSize(
            width: baseX * outward + spiralKick.width + curveKick.width + CGFloat.random(in: -80...80),
            height: baseY * (outward - 0.02) + spiralKick.height + curveKick.height - lift
        )
        let color = palette[colorIndex % palette.count]
        colorIndex += 1
        let rotation = Double.random(in: -24...24)
        let settleRotation = rotation * 0.3
        let fontSize = isImmediate
            ? CGFloat.random(in: 11.0...19.0)
            : CGFloat.random(in: 11.5...22.0)
        let glow = isImmediate
            ? Double.random(in: 0.9...1.6)
            : Double.random(in: 1.1...2.1)
        let floatPhase = Double.random(in: 0...(Double.pi * 2))
        let floatSpeed = Double.random(in: 0.55...1.55)
        let floatAmplitude = CGFloat.random(in: 12...26)
        let orbitPhase = Double.random(in: 0...(Double.pi * 2))
        let orbitSpeed = Double.random(in: 0.45...1.3)
        let orbitRadius = CGFloat.random(in: 12...28)
        let orbitSqueeze = CGFloat.random(in: 0.4...0.88)
        let spinSpeed = Double.random(in: 0.45...1.35) * (Bool.random() ? 1 : -1)
        let spinPhase = Double.random(in: 0...(Double.pi * 2))
        let spinAmplitude = Double.random(in: 6...14)
        let flowAngle = angle + Double.random(in: -0.45...0.45)
        let flowRadius = CGFloat.random(in: 12...28)
        let flowSpeed = Double.random(in: 0.55...1.5)

        let burst = WordBurst(
            id: id,
            text: text,
            color: color,
            opacity: 0,
            offset: entryOffset,
            scale: 0.78,
            rotation: rotation,
            blur: 6,
            fontSize: fontSize,
            glow: glow,
            floatPhase: floatPhase,
            floatSpeed: floatSpeed,
            floatAmplitude: floatAmplitude,
            orbitPhase: orbitPhase,
            orbitSpeed: orbitSpeed,
            orbitRadius: orbitRadius,
            orbitSqueeze: orbitSqueeze,
            spinSpeed: spinSpeed,
            spinPhase: spinPhase,
            spinAmplitude: spinAmplitude,
            flowAngle: flowAngle,
            flowRadius: flowRadius,
            flowSpeed: flowSpeed
        )
        bursts.append(burst)
        if bursts.count > maxActive {
            bursts.removeFirst(bursts.count - maxActive)
        }

        let entryDuration = isImmediate
            ? 0.14 + Double.random(in: 0...0.12)
            : 0.2 + Double.random(in: 0...0.24)
        withAnimation(.easeOut(duration: entryDuration)) {
            updateBurst(id: id) { burst in
                burst.opacity = 1
                burst.offset = CGSize(width: baseX, height: baseY)
                burst.scale = 1.18
                burst.rotation = settleRotation
                burst.blur = 0.25
            }
        }

        let lengthBoost = min(0.7, Double(text.count) * 0.035)
        let holdBase = isImmediate ? 0.5 : 0.8
        let holdJitter = isImmediate ? Double.random(in: 0.18...0.6) : Double.random(in: 0.3...1.1)
        let hold = holdBase + lengthBoost + holdJitter
        let exitDuration = isImmediate
            ? 0.6 + Double.random(in: 0...0.25)
            : 0.8 + Double.random(in: 0...0.4)
        DispatchQueue.main.asyncAfter(deadline: .now() + hold) {
            withAnimation(.easeInOut(duration: exitDuration)) {
                updateBurst(id: id) { burst in
                    burst.opacity = 0
                    burst.offset = exitOffset
                    burst.scale = 0.9
                    burst.rotation = rotation * -0.45
                    burst.blur = 3.6
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + exitDuration) {
                bursts.removeAll { $0.id == id }
            }
        }
    }

    private func advanceStreamAngle() {
        streamAngle += streamSpin + Double.random(in: -0.16...0.16)
        if streamAngle > Double.pi * 2 {
            streamAngle -= Double.pi * 2
        }
        if streamAngle < 0 {
            streamAngle += Double.pi * 2
        }
    }

    private func chunkHasPunctuation(_ chunk: String) -> Bool {
        guard let last = chunk.last else { return false }
        return ".!?".contains(last)
    }

    private func updateBurst(id: UUID, update: (inout WordBurst) -> Void) {
        guard let index = bursts.firstIndex(where: { $0.id == id }) else { return }
        update(&bursts[index])
    }
}

struct ReasoningThoughtStream: View {
    let text: String
    let isActive: Bool
    let palette: [Color]
    let maxActive: Int
    let repeatInterval: TimeInterval

    private let debugLogger = OverlayDebugLogger.shared
    @State private var bursts: [WordBurst] = []
    @State private var pendingChunks: [String] = []
    @State private var loopChunks: [String] = []
    @State private var bufferWords: [String] = []
    @State private var processedCount = 0
    @State private var lastText = ""
    @State private var loopIndex = 0
    @State private var lastEmitted = ""
    @State private var lastInputAt = Date.distantPast
    @State private var colorIndex = 0
    @State private var emitTask: Task<Void, Never>?
    @State private var loggedInactiveEmit = false
    @State private var isActiveState = false
    @State private var isRepeating = false
    @State private var stableLoopChunks: [String] = []

    private let minWords = 3
    private let maxWords = 3
    private let maxChars = 80
    private let idleFlushDelay: TimeInterval = 0.55
    private let placeholderChunk = "Thinking in progress"

    var body: some View {
        ZStack {
            ForEach(bursts) { burst in
                WordBurstLabel(burst: burst)
                    .multilineTextAlignment(.center)
                    .opacity(burst.opacity)
                    .scaleEffect(burst.scale)
                    .blur(radius: burst.blur)
                    .offset(burst.offset)
            }
        }
        .frame(width: OverlayLayout.orbFieldSize, height: OverlayLayout.orbFieldSize)
        .onAppear {
            isActiveState = isActive
            debugLogger.log("reasoning stream appear active=\(isActiveState) textLen=\(text.count)")
            handleTextChange()
            if isActiveState {
                startLoop()
            } else {
                emitTask?.cancel()
                emitTask = nil
            }
        }
        .onDisappear {
            debugLogger.log("reasoning stream disappear active=\(isActive)")
            emitTask?.cancel()
        }
        .onChange(of: text) { _ in
            handleTextChange()
        }
        .onChange(of: isActive) { _ in
            isActiveState = isActive
            debugLogger.log("reasoning stream active=\(isActiveState) textLen=\(text.count)")
            handleTextChange()
            if isActiveState {
                startLoop()
            } else {
                emitTask?.cancel()
                emitTask = nil
            }
        }
    }

    private func handleTextChange() {
        if !isActive {
            resetAll()
            return
        }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            resetAll()
            return
        }
        if !lastText.isEmpty, !trimmed.hasPrefix(lastText) {
            resetAll()
        }
        let words = trimmed.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        if words.count < processedCount {
            processedCount = words.count
        }
        guard words.count > processedCount else {
            lastText = trimmed
            return
        }
        let newWords = Array(words[processedCount...])
        processedCount = words.count
        bufferWords.append(contentsOf: newWords)
        lastInputAt = Date()
        let chunks = consumeBuffer(allowPartial: false)
        if !chunks.isEmpty {
            if isRepeating {
                debugLogger.log("reasoning stream loop replace count=\(chunks.count)")
                replaceLoop(with: chunks)
            } else {
                debugLogger.log("reasoning stream loop append count=\(chunks.count)")
                appendLoop(with: chunks)
            }
        }
        lastText = trimmed
    }

    private func consumeBuffer(allowPartial: Bool) -> [String] {
        guard !bufferWords.isEmpty else { return [] }
        var chunks: [String] = []
        var current: [String] = []
        let remaining = bufferWords
        bufferWords.removeAll()
        for word in remaining {
            current.append(word)
            let joined = current.joined(separator: " ")
            if current.count >= maxWords || joined.count >= maxChars {
                let chunk = joined.trimmingCharacters(in: .whitespacesAndNewlines)
                if !chunk.isEmpty {
                    chunks.append(chunk)
                }
                current.removeAll()
                continue
            }
            if current.count >= minWords, wordHasPunctuation(word) {
                let chunk = joined.trimmingCharacters(in: .whitespacesAndNewlines)
                if !chunk.isEmpty {
                    chunks.append(chunk)
                }
                current.removeAll()
            }
        }
        if allowPartial, !current.isEmpty {
            let joined = current.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            if !joined.isEmpty {
                chunks.append(joined)
                current.removeAll()
            }
        }
        bufferWords = current
        return chunks
    }

    private func startLoop() {
        emitTask?.cancel()
        emitTask = Task { @MainActor in
            debugLogger.log("reasoning stream loop started active=\(isActiveState)")
            while !Task.isCancelled {
                let interval = max(0.6, repeatInterval)
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                guard !Task.isCancelled else { return }
                emitNext()
            }
        }
    }

    private func emitNext() {
        guard isActiveState else {
            if !loggedInactiveEmit {
                debugLogger.log("reasoning stream emit skipped inactive")
                loggedInactiveEmit = true
            }
            return
        }
        if loggedInactiveEmit {
            debugLogger.log("reasoning stream emit resumed active")
            loggedInactiveEmit = false
        }
        if pendingChunks.isEmpty, !bufferWords.isEmpty {
            let idle = Date().timeIntervalSince(lastInputAt)
            if bufferWords.count >= minWords || idle >= idleFlushDelay {
                let chunks = consumeBuffer(allowPartial: true)
                if !chunks.isEmpty {
                    replaceLoop(with: chunks)
                }
            }
        }
        if !pendingChunks.isEmpty {
            let next = pendingChunks.removeFirst()
            enqueueBurst(next, isRepeat: false)
            lastEmitted = next
            return
        }
        guard !loopChunks.isEmpty else { return }
        if !isRepeating {
            isRepeating = true
        }
        var next = loopChunks[loopIndex % loopChunks.count]
        loopIndex += 1
        if next == lastEmitted, loopChunks.count > 1 {
            next = loopChunks[loopIndex % loopChunks.count]
            loopIndex += 1
        }
        enqueueBurst(next, isRepeat: true)
        lastEmitted = next
    }

    private func replaceLoop(with chunks: [String]) {
        let uniqueChunks = chunks.reduce(into: [String]()) { result, chunk in
            if !result.contains(chunk) {
                result.append(chunk)
            }
        }
        guard !uniqueChunks.isEmpty else { return }
        let fullChunks = uniqueChunks.filter { !isShortChunk($0) }
        isRepeating = false
        pendingChunks = uniqueChunks
        if fullChunks.isEmpty {
            loopChunks = stableLoopChunks.isEmpty ? [placeholderChunk] : stableLoopChunks
        } else {
            loopChunks = fullChunks
            stableLoopChunks = fullChunks
        }
        loopIndex = 0
        lastEmitted = ""
    }

    private func appendLoop(with chunks: [String]) {
        let uniqueChunks = chunks.reduce(into: [String]()) { result, chunk in
            if !result.contains(chunk) {
                result.append(chunk)
            }
        }
        guard !uniqueChunks.isEmpty else { return }
        let shortChunks = uniqueChunks.filter { isShortChunk($0) }
        if !shortChunks.isEmpty {
            let pendingNew = shortChunks.filter { chunk in
                !pendingChunks.contains(chunk)
            }
            pendingChunks.append(contentsOf: pendingNew)
        }
        let fullChunks = uniqueChunks.filter { !isShortChunk($0) }
        guard !fullChunks.isEmpty else { return }
        let newChunks = fullChunks.filter { chunk in
            !loopChunks.contains(chunk)
        }
        guard !newChunks.isEmpty else { return }
        let pendingNew = newChunks.filter { chunk in
            !pendingChunks.contains(chunk)
        }
        pendingChunks.append(contentsOf: pendingNew)
        loopChunks.append(contentsOf: newChunks)
        stableLoopChunks = loopChunks
        if loopChunks.count == newChunks.count {
            loopIndex = 0
            lastEmitted = ""
        }
    }

    private func enqueueBurst(_ text: String, isRepeat: Bool) {
        guard !text.isEmpty else { return }
        let id = UUID()
        let angle = Double.random(in: 0...(Double.pi * 2))
        let minRadius = OverlayLayout.orbSize * 0.04
        let maxRadius = OverlayLayout.orbSize * 0.36
        let radius = CGFloat.random(in: minRadius...maxRadius)
        let baseX = cos(angle) * radius
        let baseY = sin(angle) * radius
        let entryOffset = CGSize(width: baseX * 0.08, height: baseY * 0.08)
        let outward = CGFloat.random(in: 2.8...4.2)
        let jitterX = CGFloat.random(in: -110...110)
        let jitterY = CGFloat.random(in: -110...110)
        let exitOffset = CGSize(
            width: baseX * outward + jitterX,
            height: baseY * outward + jitterY
        )
        let color = palette[colorIndex % palette.count]
        colorIndex += 1
        let rotation = Double.random(in: -18...18)
        let settleRotation = rotation * 0.2
        let fontSize = isRepeat
            ? CGFloat.random(in: 28.5...37.5)
            : CGFloat.random(in: 31.5...42.0)
        let glow = isRepeat
            ? Double.random(in: 0.22...0.5)
            : Double.random(in: 0.3...0.7)
        let floatPhase = Double.random(in: 0...(Double.pi * 2))
        let floatSpeed = Double.random(in: 0.32...0.85)
        let floatAmplitude = CGFloat.random(in: 6...16)
        let orbitPhase = Double.random(in: 0...(Double.pi * 2))
        let orbitSpeed = Double.random(in: 0.28...0.75)
        let orbitRadius = CGFloat.random(in: 6...16)
        let orbitSqueeze = CGFloat.random(in: 0.55...0.92)
        let spinSpeed = Double.random(in: 0.2...0.55) * (Bool.random() ? 1 : -1)
        let spinPhase = Double.random(in: 0...(Double.pi * 2))
        let spinAmplitude = Double.random(in: 3...9)
        let flowAngle = angle + Double.random(in: -0.35...0.35)
        let flowRadius = CGFloat.random(in: 6...16)
        let flowSpeed = Double.random(in: 0.32...0.8)

        let burst = WordBurst(
            id: id,
            text: text,
            color: color,
            opacity: 0,
            offset: entryOffset,
            scale: 0.92,
            rotation: rotation,
            blur: 3.5,
            fontSize: fontSize,
            glow: glow,
            floatPhase: floatPhase,
            floatSpeed: floatSpeed,
            floatAmplitude: floatAmplitude,
            orbitPhase: orbitPhase,
            orbitSpeed: orbitSpeed,
            orbitRadius: orbitRadius,
            orbitSqueeze: orbitSqueeze,
            spinSpeed: spinSpeed,
            spinPhase: spinPhase,
            spinAmplitude: spinAmplitude,
            flowAngle: flowAngle,
            flowRadius: flowRadius,
            flowSpeed: flowSpeed
        )
        bursts.append(burst)
        if bursts.count > maxActive {
            bursts.removeFirst(bursts.count - maxActive)
        }

        let entryDuration = 0.2 + Double.random(in: 0...0.12)
        withAnimation(.easeOut(duration: entryDuration)) {
            updateBurst(id: id) { burst in
                burst.opacity = 1
                burst.offset = CGSize(width: baseX, height: baseY)
                burst.scale = 1.0
                burst.rotation = settleRotation
                burst.blur = 0.4
            }
        }

        let lengthBoost = min(0.35, Double(text.count) * 0.02)
        let hold = 0.5 + lengthBoost + Double.random(in: 0.1...0.35)
        let exitDuration = 0.85 + Double.random(in: 0...0.35)
        DispatchQueue.main.asyncAfter(deadline: .now() + hold) {
            withAnimation(.easeInOut(duration: exitDuration)) {
                updateBurst(id: id) { burst in
                    burst.opacity = 0
                    burst.offset = exitOffset
                    burst.scale = 0.82
                    burst.rotation = rotation * -0.35
                    burst.blur = 3.4
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + exitDuration) {
                bursts.removeAll { $0.id == id }
            }
        }
    }

    private func updateBurst(id: UUID, update: (inout WordBurst) -> Void) {
        guard let index = bursts.firstIndex(where: { $0.id == id }) else { return }
        update(&bursts[index])
    }

    private func wordHasPunctuation(_ word: String) -> Bool {
        guard let last = word.last else { return false }
        return ",.!?;:".contains(last)
    }

    private func chunkHasPunctuation(_ chunk: String) -> Bool {
        guard let last = chunk.last else { return false }
        return ",.!?;:".contains(last)
    }

    private func isShortChunk(_ chunk: String) -> Bool {
        let count = chunk.split(whereSeparator: { $0.isWhitespace }).count
        return count <= 1
    }

    private func resetAll() {
        bursts.removeAll()
        pendingChunks.removeAll()
        loopChunks.removeAll()
        stableLoopChunks.removeAll()
        bufferWords.removeAll()
        processedCount = 0
        lastText = ""
        loopIndex = 0
        lastEmitted = ""
        lastInputAt = .distantPast
        colorIndex = 0
        isRepeating = false
    }

    private func resetStream() {
        bursts.removeAll()
        pendingChunks.removeAll()
        loopChunks.removeAll()
        stableLoopChunks.removeAll()
        bufferWords.removeAll()
        processedCount = 0
        loopIndex = 0
        lastEmitted = ""
        lastInputAt = .distantPast
        colorIndex = 0
        isRepeating = false
    }
}

struct WordBurst: Identifiable {
    let id: UUID
    let text: String
    let color: Color
    var opacity: Double
    var offset: CGSize
    var scale: CGFloat
    var rotation: Double
    var blur: CGFloat
    var fontSize: CGFloat
    var glow: Double
    var floatPhase: Double
    var floatSpeed: Double
    var floatAmplitude: CGFloat
    var orbitPhase: Double
    var orbitSpeed: Double
    var orbitRadius: CGFloat
    var orbitSqueeze: CGFloat
    var spinSpeed: Double
    var spinPhase: Double
    var spinAmplitude: Double
    var flowAngle: Double
    var flowRadius: CGFloat
    var flowSpeed: Double
}

private struct WordBurstLabel: View {
    let burst: WordBurst

    var body: some View {
        let font = Font.custom("Avenir Next", size: burst.fontSize).weight(.semibold)
        let glowRadius = CGFloat(6 + 10 * burst.glow)
        let haloRadius = CGFloat(14 + 14 * burst.glow)
        let shimmerRadius = CGFloat(18 + 14 * burst.glow)

        return TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let driftX = sin(time * burst.floatSpeed + burst.floatPhase) * burst.floatAmplitude
            let driftY = cos(time * burst.floatSpeed * 0.9 + burst.floatPhase) * burst.floatAmplitude * 0.7
            let orbit = time * burst.orbitSpeed + burst.orbitPhase
            let orbitX = cos(orbit) * burst.orbitRadius
            let orbitY = sin(orbit) * burst.orbitRadius * burst.orbitSqueeze
            let spin = sin(time * burst.spinSpeed + burst.spinPhase) * burst.spinAmplitude
            let flow = sin(time * burst.flowSpeed + burst.floatPhase)
            let flowX = cos(burst.flowAngle) * burst.flowRadius * CGFloat(flow)
            let flowY = sin(burst.flowAngle) * burst.flowRadius * CGFloat(flow)
            let pulse = 1 + 0.03 * sin(time * burst.floatSpeed * 0.7 + burst.floatPhase)

            ZStack {
                Text(burst.text)
                    .font(font)
                    .tracking(0.6)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                burst.color.opacity(1.0),
                                Color.white.opacity(0.95),
                                burst.color.opacity(0.7),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: burst.color.opacity(0.8), radius: glowRadius)
                    .shadow(color: burst.color.opacity(0.4), radius: haloRadius)

                Text(burst.text)
                    .font(font)
                    .foregroundColor(burst.color.opacity(0.22))
                    .blur(radius: 8 + 4 * burst.glow)
                    .opacity(0.45)
                    .offset(x: -flowX * 1.4, y: -flowY * 1.4)

                Text(burst.text)
                    .font(font)
                    .foregroundColor(burst.color.opacity(0.4))
                    .blur(radius: 8 + 5 * burst.glow)
                    .opacity(0.65)

                Text(burst.text)
                    .font(font)
                    .foregroundColor(Color.white.opacity(0.55))
                    .blur(radius: shimmerRadius)
                    .opacity(0.5)
            }
            .rotationEffect(.degrees(burst.rotation + spin))
            .scaleEffect(pulse)
            .offset(x: driftX + orbitX + flowX * 0.4, y: driftY + orbitY + flowY * 0.4)
            .blendMode(.plusLighter)
        }
    }
}
