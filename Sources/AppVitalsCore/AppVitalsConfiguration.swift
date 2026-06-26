import Foundation

public struct AppVitalsConfiguration: Sendable, Equatable {
    public var isEnabled: Bool
    public var isNetworkTrackingEnabled: Bool
    public var isShakeToDebugEnabled: Bool
    public var redactionPolicy: RedactionPolicy
    public var limits: AppVitalsLimits
    public var slowRequestThreshold: TimeInterval
    public var isFPSMonitoringEnabled: Bool
    public var fpsDropThreshold: Double
    public var isMemoryMonitoringEnabled: Bool
    public var memorySpikeThresholdMB: Double

    public init(
        isEnabled: Bool = true,
        isNetworkTrackingEnabled: Bool = false,
        isShakeToDebugEnabled: Bool = false,
        redactionPolicy: RedactionPolicy = .productionSafe,
        limits: AppVitalsLimits = .production,
        slowRequestThreshold: TimeInterval = 0,
        isFPSMonitoringEnabled: Bool = false,
        fpsDropThreshold: Double = 50.0,
        isMemoryMonitoringEnabled: Bool = false,
        memorySpikeThresholdMB: Double = 50.0
    ) {
        self.isEnabled = isEnabled
        self.isNetworkTrackingEnabled = isNetworkTrackingEnabled
        self.isShakeToDebugEnabled = isShakeToDebugEnabled
        self.redactionPolicy = redactionPolicy
        self.limits = limits
        self.slowRequestThreshold = slowRequestThreshold
        self.isFPSMonitoringEnabled = isFPSMonitoringEnabled
        self.fpsDropThreshold = fpsDropThreshold
        self.isMemoryMonitoringEnabled = isMemoryMonitoringEnabled
        self.memorySpikeThresholdMB = memorySpikeThresholdMB
    }

    public static let production = AppVitalsConfiguration()

    public static let debug = AppVitalsConfiguration(
        isEnabled: true,
        isNetworkTrackingEnabled: true,
        isShakeToDebugEnabled: true,
        slowRequestThreshold: 3.0,
        isFPSMonitoringEnabled: true,
        isMemoryMonitoringEnabled: true
    )

    public static var current: AppVitalsConfiguration {
        #if DEBUG
            return .debug
        #else
            return .production
        #endif
    }
}

public struct AppVitalsLimits: Sendable, Equatable {
    public var maxEvents: Int
    public var maxNetworkTransactions: Int
    public var maxBodyBytes: Int

    public init(maxEvents: Int = 500, maxNetworkTransactions: Int = 150, maxBodyBytes: Int = 256_000) {
        self.maxEvents = max(1, maxEvents)
        self.maxNetworkTransactions = max(1, maxNetworkTransactions)
        self.maxBodyBytes = max(0, maxBodyBytes)
    }

    public static let production = AppVitalsLimits()
}

public struct RedactionPolicy: Sendable, Equatable {
    public var redactedHeaderNames: Set<String>
    public var redactedQueryItemNames: Set<String>

    public init(redactedHeaderNames: Set<String>, redactedQueryItemNames: Set<String>) {
        self.redactedHeaderNames = Set(redactedHeaderNames.map { $0.lowercased() })
        self.redactedQueryItemNames = Set(redactedQueryItemNames.map { $0.lowercased() })
    }

    public static let productionSafe = RedactionPolicy(
        redactedHeaderNames: ["authorization", "cookie", "set-cookie", "x-api-key"],
        redactedQueryItemNames: ["token", "access_token", "api_key", "password"]
    )
}
