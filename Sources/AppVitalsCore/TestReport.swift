import Foundation

public struct TestPerformance: Codable, Equatable, Sendable {
    public var duration: TimeInterval?
    public var peakMemoryMB: Double?
    public var memoryDeltaMB: Double?
    public var frameDrops: Int
    public var requestCount: Int
    public var slowRequests: Int
    public var averageRequestDuration: TimeInterval?
}

/// Everything AppVitals captured while one test ran: debug logs, API traffic, performance and failure diagnostics.
/// Data is attributed to the test by time window, so tests running in parallel in one process share each other's data.
public struct TestReport: Codable, Equatable, Sendable {
    public let run: TestRun
    public let events: [AppVitalsEvent]
    public let transactions: [NetworkTransaction]
    public let performance: TestPerformance

    public init(
        run: TestRun,
        events: [AppVitalsEvent],
        transactions: [NetworkTransaction],
        memorySnapshots: [MemorySnapshot] = [],
        slowRequestThreshold: TimeInterval = 2.0
    ) {
        let window = run.startedAt ... (run.endedAt ?? Date())
        let events = events.filter { window.contains($0.timestamp) }.sorted { $0.timestamp < $1.timestamp }
        let transactions = transactions.filter { window.contains($0.startedAt) }.sorted { $0.startedAt < $1.startedAt }
        let memory = memorySnapshots.filter { window.contains($0.timestamp) }.sorted { $0.timestamp < $1.timestamp }
        let durations = transactions.compactMap(\.duration)

        self.run = run
        self.events = events
        self.transactions = transactions
        performance = TestPerformance(
            duration: run.duration,
            peakMemoryMB: memory.map(\.usedMB).max(),
            memoryDeltaMB: memory.count > 1 ? memory[memory.count - 1].usedMB - memory[0].usedMB : nil,
            frameDrops: events
                .count(where: { $0.category == .performance && $0.metadata["fps"] != nil }), // fps metadata is set only by
            // FrameRateMonitor,
            requestCount: transactions.count,
            slowRequests: durations.count(where: { $0 > slowRequestThreshold }),
            averageRequestDuration: durations.isEmpty ? nil : durations.reduce(0, +) / Double(durations.count)
        )
    }

    /// Error/warning logs recorded during the run.
    public var problemEvents: [AppVitalsEvent] {
        events.filter { $0.level == .error || $0.level == .warning }
    }

    /// Requests that errored or returned a 4xx/5xx status.
    public var failedTransactions: [NetworkTransaction] {
        transactions.filter { $0.response.map { $0.statusCode >= 400 } ?? true }
    }

    public func jsonData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .secondsSince1970 // .iso8601 would drop sub-second precision
        return try encoder.encode(self)
    }

    public func plainText() -> String {
        var lines = ["Test: \(run.name) [\(run.kind.rawValue)] — \(run.status.rawValue.uppercased())"]
        if let duration = run.duration {
            lines.append(String(format: "Duration: %.3fs", duration))
        }

        if run.status == .failed {
            lines.append("\nFailure Diagnostics")
            lines.append("  Reason: \(run.failureMessage ?? "unknown")")
            lines += problemEvents.map { "  [\($0.level.rawValue.uppercased())] \($0.message)" }
            lines += failedTransactions.map { "  \(describe($0))" }
        }

        lines.append("\nPerformance")
        lines.append("  Requests: \(performance.requestCount) (\(performance.slowRequests) slow)")
        if let average = performance.averageRequestDuration {
            lines.append(String(format: "  Avg request: %.3fs", average))
        }
        lines.append("  Frame drops: \(performance.frameDrops)")
        if let peak = performance.peakMemoryMB {
            lines.append(String(format: "  Peak memory: %.1f MB", peak))
        }
        if let delta = performance.memoryDeltaMB {
            lines.append(String(format: "  Memory delta: %+.1f MB", delta))
        }

        lines.append("\nTimeline")
        let entries: [(Date, String)] = events.map { ($0.timestamp, "LOG [\($0.level.rawValue.uppercased())] \($0.message)") }
            + transactions.map { ($0.startedAt, describe($0)) }
        lines += entries.sorted { $0.0 < $1.0 }.map { String(format: "  +%.3fs ", $0.0.timeIntervalSince(run.startedAt)) + $0.1 }
        return lines.joined(separator: "\n")
    }

    /// Writes `<name>-<id>.txt` and `.json` into `directory` (e.g. for CI artifacts or test attachments) and returns both URLs.
    @discardableResult
    public func write(to directory: URL) throws -> [URL] {
        let base = run.name.map { $0.isLetter || $0.isNumber ? String($0) : "_" }.joined() + "-" + run.id.uuidString.prefix(8)
        let text = directory.appendingPathComponent(base + ".txt")
        let json = directory.appendingPathComponent(base + ".json")
        try Data(plainText().utf8).write(to: text, options: .atomic)
        try jsonData().write(to: json, options: .atomic)
        return [text, json]
    }

    private func describe(_ transaction: NetworkTransaction) -> String {
        let status = transaction.response.map { "\($0.statusCode)" } ?? transaction.errorDescription ?? "—"
        let duration = transaction.duration.map { String(format: " %.3fs", $0) } ?? ""
        return "NET \(transaction.request.method) \(status)\(duration) \(transaction.request.url.absoluteString)"
    }
}
