import Foundation

final class MicProbeLogger {
    private let formatter = ISO8601DateFormatter()
    private var fileHandle: FileHandle?

    init() {
        guard let path = ProcessInfo.processInfo.environment["TOKONIX_OVERLAY_MIC_LOG"], !path.isEmpty else {
            return
        }
        let url = URL(fileURLWithPath: path)
        FileManager.default.createFile(atPath: path, contents: nil)
        fileHandle = try? FileHandle(forWritingTo: url)
    }

    func log(_ message: String) {
        guard let fileHandle else { return }
        let timestamp = formatter.string(from: Date())
        let line = "[\(timestamp)] MIC_PROBE \(message)\n"
        if let data = line.data(using: .utf8) {
            fileHandle.write(data)
        }
    }

    deinit {
        try? fileHandle?.close()
    }
}
