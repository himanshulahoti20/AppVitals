@_exported import AppVitalsCore
@_exported import AppVitalsNetwork
@_exported import AppVitalsPerformance
@_exported import AppVitalsStorage
#if canImport(SwiftUI)
    @_exported import AppVitalsUI
#endif

import Foundation

public enum AppVitals {
    private static let runtime = AppVitalsRuntime()

    public static func start(
        _ configuration: AppVitalsConfiguration = .production,
        crashReporters: [any AppVitalsCrashReporter] = []
    ) {
        Task {
            await runtime.start(configuration, crashReporters: crashReporters)
        }
    }

    public static func trackNetwork() {
        Task {
            await runtime.enableNetworkTracking()
        }
    }

    public static func trackPerformance() {
        Task {
            await runtime.enablePerformanceMonitoring()
        }
    }

    /// Returns a token that tracks one live instance of `name`.
    /// Store the token as a property — when the owning object deinits, disposal is recorded automatically.
    public static func trackLifetime(named name: String) -> LifecycleToken {
        LifecycleToken(name: name, store: stores.memory)
    }

    /// Returns a token that tracks one active subscription/stream named `name`.
    /// Nil the token (or let it deinit) to record the stream closing.
    public static func trackStream(named name: String) -> StreamToken {
        StreamToken(name: name, store: stores.memory)
    }

    /// Manually records one rebuild for the named view. Use `.trackRebuilds(_:store:)` modifier for automatic counting.
    public static func countRebuild(_ viewName: String) {
        Task {
            await stores.memory.viewRebuilt(viewName)
        }
    }

    public static func markStartupComplete() {
        Task {
            await runtime.markStartupComplete()
        }
    }

    public static func enableShakeToDebug() {
        stores.sharedState.isShakeToDebugEnabled = true
    }

    public static func log(
        _ message: String,
        category: AppVitalsEventCategory = .custom,
        level: AppVitalsLogLevel = .info,
        metadata: [String: String] = [:]
    ) {
        Task {
            await runtime.log(message, category: category, level: level, metadata: metadata)
        }
    }

    public static func screen(_ name: String?) {
        Task {
            await runtime.setVisibleScreenName(name)
        }
    }

    public static var stores: AppVitalsStores {
        runtime.stores
    }

    public static func openConsole() {
        NotificationCenter.default.post(name: AppVitalsNotification.openConsole, object: nil)
    }

    public static func persistCrashContext() {
        Task {
            await runtime.persistCrashContext()
        }
    }
}

private actor AppVitalsRuntime {
    nonisolated let stores: AppVitalsStores
    private var configuration: AppVitalsConfiguration
    private var crashReporters: [any AppVitalsCrashReporter] = []
    private var frameRateMonitor: FrameRateMonitor?
    private var memoryMonitor: MemoryMonitor?
    private var startupBeganAt: Date?

    init(configuration: AppVitalsConfiguration = .production) {
        self.configuration = configuration
        stores = AppVitalsStores(
            events: EventStore(limit: configuration.limits.maxEvents),
            network: NetworkTransactionStore(limit: configuration.limits.maxNetworkTransactions),
            crashContext: CrashContextStore()
        )
    }

    func start(_ configuration: AppVitalsConfiguration, crashReporters: [any AppVitalsCrashReporter]) async {
        startupBeganAt = Date()
        var mergedConfiguration = configuration
        mergedConfiguration.isNetworkTrackingEnabled = configuration.isNetworkTrackingEnabled || self.configuration.isNetworkTrackingEnabled
        self.configuration = mergedConfiguration
        self.crashReporters = crashReporters

        if mergedConfiguration.isNetworkTrackingEnabled {
            NetworkTracking.installGlobalURLProtocol(
                store: stores.network,
                eventStore: stores.events,
                configuration: mergedConfiguration
            )
        }
        if mergedConfiguration.isFPSMonitoringEnabled {
            await enablePerformanceMonitoring()
        }
        if mergedConfiguration.isMemoryMonitoringEnabled {
            await enableMemoryMonitoring()
        }
        await log("App launched", category: .app, level: .info, metadata: [:])
    }

    func enableNetworkTracking() {
        configuration.isNetworkTrackingEnabled = true
        NetworkTracking.installGlobalURLProtocol(
            store: stores.network,
            eventStore: stores.events,
            configuration: configuration
        )
    }

    func enablePerformanceMonitoring() async {
        guard frameRateMonitor == nil else { return }
        let monitor = FrameRateMonitor(
            dropThreshold: configuration.fpsDropThreshold,
            eventStore: stores.events
        )
        monitor.start()
        frameRateMonitor = monitor
    }

    func enableMemoryMonitoring() async {
        guard memoryMonitor == nil else { return }
        let monitor = MemoryMonitor(
            spikeThresholdMB: configuration.memorySpikeThresholdMB,
            memoryStore: stores.memory,
            eventStore: stores.events
        )
        monitor.start()
        memoryMonitor = monitor
    }

    func markStartupComplete() async {
        guard let began = startupBeganAt else { return }
        startupBeganAt = nil
        let elapsed = Date().timeIntervalSince(began)
        await log(
            String(format: "Startup completed in %.3fs", elapsed),
            category: .performance,
            level: .info,
            metadata: ["duration_ms": "\(Int(elapsed * 1000))"]
        )
    }

    func log(
        _ message: String,
        category: AppVitalsEventCategory,
        level: AppVitalsLogLevel,
        metadata: [String: String]
    ) async {
        guard configuration.isEnabled else { return }
        await stores.events.append(AppVitalsEvent(category: category, level: level, message: message, metadata: metadata))
        for reporter in crashReporters {
            reporter.addBreadcrumb(message: message, category: category.rawValue, level: level, metadata: metadata)
            if level == .error || category == .error {
                reporter.recordNonFatal(message: message, metadata: metadata)
            }
        }
    }

    func setVisibleScreenName(_ name: String?) async {
        await stores.crashContext.setVisibleScreenName(name)
        for reporter in crashReporters {
            reporter.setScreenContext(name)
        }
        if let name {
            await log("Screen visible: \(name)", category: .navigation, level: .info, metadata: ["screen": name])
        }
    }

    func persistCrashContext() async {
        do {
            let events = await stores.events.all()
            let networkTransactions = await stores.network.all()
            try await stores.crashContext.persist(
                events: events,
                networkTransactions: networkTransactions
            )
        } catch {
            await log(
                "Failed to persist crash context: \(error.localizedDescription)",
                category: .error,
                level: .error,
                metadata: [:]
            )
        }
    }
}
