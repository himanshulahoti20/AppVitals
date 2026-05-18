import Foundation

public struct CrashContext: Codable, Equatable, Sendable {
    public var capturedAt: Date
    public var visibleScreenName: String?
    public var recentEvents: [AppVitalsEvent]
    public var recentNetworkTransactions: [NetworkTransaction]

    public init(
        capturedAt: Date = Date(),
        visibleScreenName: String? = nil,
        recentEvents: [AppVitalsEvent] = [],
        recentNetworkTransactions: [NetworkTransaction] = []
    ) {
        self.capturedAt = capturedAt
        self.visibleScreenName = visibleScreenName
        self.recentEvents = recentEvents
        self.recentNetworkTransactions = recentNetworkTransactions
    }
}
