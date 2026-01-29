import AppKit

private func logMessage(_ message: String) {
    let env = ProcessInfo.processInfo.environment
    let logPath = env["NOTES_VIEWER_LOG"] ?? env["CODEX_HOME"].map { "\($0)/skill-workspaces/simple-notes/notes-viewer/NotesViewer.log" }
    guard let path = logPath else { return }
    let url = URL(fileURLWithPath: path)
    let line = "\(message)\n"
    if let data = line.data(using: .utf8) {
        if FileManager.default.fileExists(atPath: url.path) == false {
            FileManager.default.createFile(atPath: url.path, contents: nil)
        }
        if let handle = try? FileHandle(forWritingTo: url) {
            defer { try? handle.close() }
            try? handle.seekToEnd()
            try? handle.write(contentsOf: data)
        }
    }
}

private struct NotesTheme {
    let background: NSColor
    let text: NSColor
    let heading: NSColor
    let subheading: NSColor
    let accent: NSColor
    let bodyFont: NSFont
    let headingFont: NSFont
    let subheadingFont: NSFont
}

private func makeTheme() -> NotesTheme {
    NotesTheme(
        background: NSColor(calibratedRed: 0.06, green: 0.08, blue: 0.11, alpha: 1.0),
        text: NSColor(calibratedWhite: 0.92, alpha: 1.0),
        heading: NSColor(calibratedRed: 0.62, green: 0.86, blue: 1.0, alpha: 1.0),
        subheading: NSColor(calibratedRed: 0.62, green: 1.0, blue: 0.78, alpha: 1.0),
        accent: NSColor(calibratedRed: 0.36, green: 0.83, blue: 0.92, alpha: 1.0),
        bodyFont: NSFont.systemFont(ofSize: 14.0),
        headingFont: NSFont.systemFont(ofSize: 20.0, weight: .semibold),
        subheadingFont: NSFont.systemFont(ofSize: 16.0, weight: .semibold)
    )
}

private func paragraphStyle(lineSpacing: CGFloat, spacingAfter: CGFloat, indent: CGFloat) -> NSParagraphStyle {
    let style = NSMutableParagraphStyle()
    style.lineSpacing = lineSpacing
    style.paragraphSpacing = spacingAfter
    style.headIndent = indent
    style.firstLineHeadIndent = indent
    return style
}

private func formattedNotes(from text: String, theme: NotesTheme) -> NSAttributedString {
    let result = NSMutableAttributedString()
    let lines = text.split(separator: "\n", omittingEmptySubsequences: false)

    for line in lines {
        let rawLine = String(line)
        let trimmed = rawLine.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("# ") {
            let content = trimmed.replacingOccurrences(of: "# ", with: "")
            let attrs: [NSAttributedString.Key: Any] = [
                .font: theme.headingFont,
                .foregroundColor: theme.heading,
                .paragraphStyle: paragraphStyle(lineSpacing: 4.0, spacingAfter: 8.0, indent: 0)
            ]
            result.append(NSAttributedString(string: content + "\n", attributes: attrs))
            continue
        }

        if trimmed.hasPrefix("## ") {
            let content = trimmed.replacingOccurrences(of: "## ", with: "")
            let attrs: [NSAttributedString.Key: Any] = [
                .font: theme.subheadingFont,
                .foregroundColor: theme.subheading,
                .paragraphStyle: paragraphStyle(lineSpacing: 3.0, spacingAfter: 6.0, indent: 0)
            ]
            result.append(NSAttributedString(string: content + "\n", attributes: attrs))
            continue
        }

        let bodyAttrs: [NSAttributedString.Key: Any] = [
            .font: theme.bodyFont,
            .foregroundColor: theme.text,
            .paragraphStyle: paragraphStyle(lineSpacing: 4.0, spacingAfter: 4.0, indent: 0)
        ]
        result.append(NSAttributedString(string: rawLine + "\n", attributes: bodyAttrs))
    }

    return result
}

final class NotesAppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let url: URL
    private let windowTitle: String
    private var window: NSWindow?
    private weak var textView: NSTextView?
    private let theme = makeTheme()

    init(url: URL, windowTitle: String) {
        self.url = url
        self.windowTitle = windowTitle
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.createWindow()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        saveNotes()
    }

    func windowWillClose(_ notification: Notification) {
        saveNotes()
    }

    private func createWindow() {
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1000, height: 700)
        let width = min(980.0, screenFrame.width * 0.7)
        let height = min(720.0, screenFrame.height * 0.7)
        let originX = screenFrame.midX - width / 2.0
        let originY = screenFrame.midY - height / 2.0
        let frame = NSRect(x: originX, y: originY, width: width, height: height)

        let window = NSWindow(
            contentRect: frame,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = windowTitle
        window.isReleasedWhenClosed = false
        window.backgroundColor = theme.background
        window.delegate = self

        let scrollView = NSScrollView(frame: frame)
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder

        let textView = NSTextView(frame: frame)
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.backgroundColor = theme.background
        textView.insertionPointColor = theme.accent
        textView.textContainerInset = NSSize(width: 20, height: 16)
        textView.font = theme.bodyFont
        textView.textColor = theme.text

        let content = loadNotesText()
        let attributed = formattedNotes(from: content, theme: theme)
        textView.textStorage?.setAttributedString(attributed)
        textView.typingAttributes = [
            .font: theme.bodyFont,
            .foregroundColor: theme.text
        ]

        scrollView.documentView = textView

        window.contentView = scrollView
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()

        NSApp.activate(ignoringOtherApps: true)
        NSRunningApplication.current.activate(options: [.activateIgnoringOtherApps, .activateAllWindows])

        self.window = window
        self.textView = textView
    }

    private func loadNotesText() -> String {
        if FileManager.default.fileExists(atPath: url.path) {
            return (try? String(contentsOf: url, encoding: .utf8)) ?? ""
        }
        let placeholder = "# Notes\n\nAdd your notes here."
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? placeholder.write(to: url, atomically: true, encoding: .utf8)
        return placeholder
    }

    private func saveNotes() {
        guard let textView else { return }
        let content = textView.string
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            logMessage("Failed to save notes: \(error.localizedDescription)")
        }
    }
}

let args = CommandLine.arguments
logMessage("NotesViewer args=\(args)")
if args.count < 2 {
    logMessage("NotesViewer missing args; exiting")
    fputs("Usage: NotesViewer <path-to-notes> [window-title]\n", stderr)
    exit(1)
}

let notesPath = args[1]
let title = args.count > 2 ? args[2] : "Simple Notes"

let url = URL(fileURLWithPath: notesPath).standardizedFileURL
let app = NSApplication.shared
app.setActivationPolicy(.regular)
let appDelegate = NotesAppDelegate(url: url, windowTitle: title)
app.delegate = appDelegate
withExtendedLifetime(appDelegate) {
    app.run()
}
