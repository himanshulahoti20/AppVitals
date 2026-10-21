import Foundation

public enum TestKind: String, Codable, CaseIterable, Sendable {
    case unit
    case widget
    case integration
}

public enum TestStatus: String, Codable, Sendable {
    case running
    case passed
    case failed
}

public struct TestRun: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let name: String
    public let kind: TestKind
    public let startedAt: Date
    public var endedAt: Date?
    public var status: TestStatus
    public var failureMessage: String?

    public init(
        id: UUID = UUID(),
        name: String,
        kind: TestKind = .integration,
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        status: TestStatus = .running,
        failureMessage: String? = nil
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.status = status
        self.failureMessage = failureMessage
    }

    public var duration: TimeInterval? {
        endedAt.map { $0.timeIntervalSince(startedAt) }
    }
}
