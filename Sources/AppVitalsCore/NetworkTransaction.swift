import Foundation

public struct NetworkTransaction: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var startedAt: Date
    public var completedAt: Date?
    public var request: NetworkRequestSnapshot
    public var response: NetworkResponseSnapshot?
    public var errorDescription: String?

    public init(
        id: UUID = UUID(),
        startedAt: Date = Date(),
        completedAt: Date? = nil,
        request: NetworkRequestSnapshot,
        response: NetworkResponseSnapshot? = nil,
        errorDescription: String? = nil
    ) {
        self.id = id
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.request = request
        self.response = response
        self.errorDescription = errorDescription
    }

    public var duration: TimeInterval? {
        completedAt.map { $0.timeIntervalSince(startedAt) }
    }
}

public struct NetworkRequestSnapshot: Codable, Equatable, Sendable {
    public var method: String
    public var url: URL
    public var headers: [String: String]
    public var body: Data?

    public init(method: String, url: URL, headers: [String: String] = [:], body: Data? = nil) {
        self.method = method
        self.url = url
        self.headers = headers
        self.body = body
    }
}

public struct NetworkResponseSnapshot: Codable, Equatable, Sendable {
    public var statusCode: Int
    public var headers: [String: String]
    public var body: Data?

    public init(statusCode: Int, headers: [String: String] = [:], body: Data? = nil) {
        self.statusCode = statusCode
        self.headers = headers
        self.body = body
    }
}
