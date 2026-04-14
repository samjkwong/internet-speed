import Foundation

struct SpeedResult: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let downloadMbps: Double
    let uploadMbps: Double

    init(timestamp: Date, downloadMbps: Double, uploadMbps: Double) {
        self.id = UUID()
        self.timestamp = timestamp
        self.downloadMbps = downloadMbps
        self.uploadMbps = uploadMbps
    }
}

struct IntervalOption: Hashable {
    let minutes: Int
    let label: String
    var seconds: TimeInterval { TimeInterval(minutes * 60) }
}

let intervalOptions = [
    IntervalOption(minutes: 5, label: "5 min"),
    IntervalOption(minutes: 15, label: "15 min"),
    IntervalOption(minutes: 30, label: "30 min"),
    IntervalOption(minutes: 60, label: "60 min"),
]

let defaultInterval = intervalOptions[1] // 15 min

@MainActor
final class SpeedTestManager: ObservableObject {
    @Published var results: [SpeedResult] = []
    @Published var currentInterval: IntervalOption = defaultInterval
    @Published var isTesting = false
    @Published var menuBarTitle = "-- Mbps"

    private var timer: Timer?
    private let historyURL: URL
    private let maxResults = 100

    init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!.appendingPathComponent("InternetSpeed")
        try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        historyURL = appSupport.appendingPathComponent("history.json")

        loadHistory()
        scheduleTimer()
        runTest()
    }

    func setInterval(_ option: IntervalOption) {
        currentInterval = option
        scheduleTimer()
    }

    func runTest() {
        guard !isTesting else { return }
        isTesting = true
        menuBarTitle = "Testing..."

        Task.detached { [weak self] in
            let result = await Self.executeSpeedTest()
            await self?.handleResult(result)
        }
    }

    private func handleResult(_ result: Result<SpeedResult, Error>) {
        switch result {
        case .success(let speed):
            results.append(speed)
            if results.count > maxResults {
                results.removeFirst(results.count - maxResults)
            }
            let dl = Int(speed.downloadMbps)
            let ul = Int(speed.uploadMbps)
            menuBarTitle = "\u{2193}\(dl) \u{2191}\(ul) Mbps"
            saveHistory()
        case .failure(let error):
            menuBarTitle = "Error"
            print("Speed test error: \(error)")
        }
        isTesting = false
    }

    private func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(
            withTimeInterval: currentInterval.seconds,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                self?.runTest()
            }
        }
    }

    private nonisolated static func findSpeedTestBinary() -> String? {
        let candidates = [
            "/opt/homebrew/bin/speedtest",
            "/usr/local/bin/speedtest",
        ]
        for path in candidates {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }
        // Fall back to PATH
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["speedtest"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        try? process.run()
        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let path, !path.isEmpty {
            return path
        }
        return nil
    }

    private nonisolated static func executeSpeedTest() async -> Result<SpeedResult, Error> {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                guard let binary = findSpeedTestBinary() else {
                    continuation.resume(returning: .failure(
                        NSError(domain: "InternetSpeed", code: 1, userInfo: [
                            NSLocalizedDescriptionKey: "Ookla Speedtest CLI not found. Install with: brew install teamookla/speedtest/speedtest"
                        ])
                    ))
                    return
                }

                let process = Process()
                process.executableURL = URL(fileURLWithPath: binary)
                process.arguments = ["--format=json", "--accept-license"]

                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = FileHandle.nullDevice

                do {
                    try process.run()
                    process.waitUntilExit()

                    guard process.terminationStatus == 0 else {
                        throw NSError(domain: "InternetSpeed", code: 2, userInfo: [
                            NSLocalizedDescriptionKey: "speedtest exited with code \(process.terminationStatus)"
                        ])
                    }

                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

                    guard
                        let download = json?["download"] as? [String: Any],
                        let dlBandwidth = download["bandwidth"] as? Double,
                        let upload = json?["upload"] as? [String: Any],
                        let ulBandwidth = upload["bandwidth"] as? Double
                    else {
                        throw NSError(domain: "InternetSpeed", code: 3, userInfo: [
                            NSLocalizedDescriptionKey: "Unexpected JSON format"
                        ])
                    }

                    // Ookla reports bytes/sec, convert to Mbps
                    let dlMbps = dlBandwidth * 8 / 1_000_000
                    let ulMbps = ulBandwidth * 8 / 1_000_000

                    let result = SpeedResult(
                        timestamp: Date(),
                        downloadMbps: dlMbps,
                        uploadMbps: ulMbps
                    )
                    continuation.resume(returning: .success(result))
                } catch {
                    continuation.resume(returning: .failure(error))
                }
            }
        }
    }

    // MARK: - Persistence

    private func loadHistory() {
        guard let data = try? Data(contentsOf: historyURL),
              let decoded = try? JSONDecoder().decode([SpeedResult].self, from: data) else {
            return
        }
        results = decoded.suffix(maxResults).map { $0 }
    }

    private func saveHistory() {
        guard let data = try? JSONEncoder().encode(results) else { return }
        try? data.write(to: historyURL, options: .atomic)
    }
}
