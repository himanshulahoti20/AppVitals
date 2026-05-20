@_exported import AppVitalsCore
@_exported import AppVitalsNetwork
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

    init(configuration: AppVitalsConfiguration = .production) {
        self.configuration = configuration
        stores = AppVitalsStores(
            events: EventStore(limit: configuration.limits.maxEvents),
            network: NetworkTransactionStore(limit: configuration.limits.maxNetworkTransactions),
            crashContext: CrashContextStore()
        )
    }

    func start(_ configuration: AppVitalsConfiguration, crashReporters: [any AppVitalsCrashReporter]) async {
        var mergedConfiguration = configuration
        mergedConfiguration.isNetworkTrackingEnabled = configuration.isNetworkTrackingEnabled || self.configuration.isNetworkTrackingEnabled
        self.configuration = mergedConfiguration
        self.crashReporters = crashReporters

        if mergedConfiguration.isNetworkTrackingEnabled {
            NetworkTracking.installGlobalURLProtocol(store: stores.network, configuration: mergedConfiguration)
        }
        await log("App launched", category: .app, level: .info, metadata: [:])
    }

    func enableNetworkTracking() {
        configuration.isNetworkTrackingEnabled = true
        NetworkTracking.installGlobalURLProtocol(store: stores.network, configuration: configuration)
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
