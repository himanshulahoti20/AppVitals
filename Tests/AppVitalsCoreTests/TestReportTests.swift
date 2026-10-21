import AppVitalsCore
import Foundation
import Testing

@Test func reportKeepsOnlyDataInsideRunWindowAndSummarisesFailures() throws {
    let start = Date(timeIntervalSince1970: 1000)
    let run = TestRun(
        name: "Checkout flow",
        kind: .integration,
        startedAt: start,
        endedAt: start.addingTimeInterval(4),
        status: .failed,
        failureMessage: "expected 200"
    )
    let url = try #require(URL(string: "https://example.com/pay"))
    let failed = NetworkTransaction(
        startedAt: start.addingTimeInterval(1),
        completedAt: start.addingTimeInterval(3.5),
        request: NetworkRequestSnapshot(method: "POST", url: url),
        response: NetworkResponseSnapshot(statusCode: 500)
    )
    let outside = NetworkTransaction(startedAt: start.addingTimeInterval(-5), request: NetworkRequestSnapshot(method: "GET", url: url))
    let events = [
        AppVitalsEvent(timestamp: start.addingTimeInterval(2), category: .test, level: .error, message: "Tapped pay"),
        AppVitalsEvent(
            timestamp: start.addingTimeInterval(2),
            category: .performance,
            level: .warning,
            message: "Frame drop: 30 FPS",
            metadata: ["fps": "30.0"]
        ),
        AppVitalsEvent(timestamp: start.addingTimeInterval(9), message: "after the run"),
    ]
    let memory = [
        MemorySnapshot(timestamp: start, usedBytes: 100 * 1_048_576),
        MemorySnapshot(timestamp: start.addingTimeInterval(4), usedBytes: 130 * 1_048_576),
    ]

    let report = TestReport(run: run, events: events, transactions: [failed, outside], memorySnapshots: memory)

    #expect(report.events.count == 2)
    #expect(report.transactions.count == 1)
    #expect(report.failedTransactions.count == 1)
    #expect(report.performance.slowRequests == 1)
    #expect(report.performance.frameDrops == 1)
    #expect(report.performance.peakMemoryMB == 130)
    #expect(report.performance.memoryDeltaMB == 30)

    let text = report.plainText()
    #expect(text.contains("FAILED"))
    #expect(text.contains("Failure Diagnostics"))
    #expect(text.contains("expected 200"))
    #expect(text.contains("NET POST 500"))

    let decoded = try JSONDecoder.report.decode(TestReport.self, from: report.jsonData())
    #expect(decoded.run == report.run)
    #expect(decoded.events == report.events)
    #expect(decoded.transactions == report.transactions)
    #expect(decoded.performance == report.performance)
}

private extension JSONDecoder {
    static var report: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }
}
