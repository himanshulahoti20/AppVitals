import Foundation

public struct AppVitalsEvent: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let category: AppVitalsEventCategory
    public let level: AppVitalsLogLevel
    public let message: String
    public let metadata: [String: String]

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        category: AppVitalsEventCategory = .custom,
        level: AppVitalsLogLevel = .info,
        message: String,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.timestamp = timestamp
        self.category = category
        self.level = level
        self.message = message
        self.metadata = metadata
    }
}

public enum AppVitalsEventCategory: String, Codable, CaseIterable, Sendable {
    case app
    case navigation
    case network
    case performance
    case warning
    case error
    case custom
}

public enum AppVitalsLogLevel: String, Codable, CaseIterable, Sendable {
    case debug
    case info
    case warning
    case error
}
