import AppVitalsCore
import Foundation

public actor TestRunStore {
    private var runs: [TestRun] = []
    private let limit: Int

    public init(limit: Int = 100) {
        self.limit = max(1, limit)
    }

    public func begin(name: String, kind: TestKind) -> TestRun {
        let run = TestRun(name: name, kind: kind)
        runs.append(run)
        if runs.count > limit { runs.removeFirst(runs.count - limit) }
        return run
    }

    /// Marks the run passed, or failed when `failure` is non-nil. Returns nil for unknown ids.
    public func finish(_ id: UUID, failure: String? = nil) -> TestRun? {
        guard let index = runs.firstIndex(where: { $0.id == id }) else { return nil }
        runs[index].endedAt = Date()
        runs[index].status = failure == nil ? .passed : .failed
        runs[index].failureMessage = failure
        return runs[index]
    }

    public func run(_ id: UUID) -> TestRun? {
        runs.first { $0.id == id }
    }

    public func all() -> [TestRun] {
        runs
    }

    public func removeAll() {
        runs.removeAll()
    }
}
