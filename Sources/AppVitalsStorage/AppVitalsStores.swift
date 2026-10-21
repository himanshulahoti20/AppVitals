import AppVitalsCore
import Foundation

public struct AppVitalsStores: Sendable {
    public let events: EventStore
    public let network: NetworkTransactionStore
    public let crashContext: CrashContextStore
    public let memory: MemoryStore
    public let testRuns: TestRunStore
    public let sharedState: AppVitalsSharedState

    public init(
        events: EventStore,
        network: NetworkTransactionStore,
        crashContext: CrashContextStore,
        memory: MemoryStore = MemoryStore(),
        testRuns: TestRunStore = TestRunStore(),
        sharedState: AppVitalsSharedState = AppVitalsSharedState()
    ) {
        self.events = events
        self.network = network
        self.crashContext = crashContext
        self.memory = memory
        self.testRuns = testRuns
        self.sharedState = sharedState
    }
}

public extension AppVitalsStores {
    /// Builds the report for a test run from everything captured in its time window.
    func testReport(for id: UUID, slowRequestThreshold: TimeInterval = 2.0) async -> TestReport? {
        guard let run = await testRuns.run(id) else { return nil }
        return await TestReport(
            run: run,
            events: events.all(),
            transactions: network.all(),
            memorySnapshots: memory.allSnapshots(),
            slowRequestThreshold: slowRequestThreshold
        )
    }
}
