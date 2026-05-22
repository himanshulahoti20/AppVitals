import AppVitalsCore
import AppVitalsStorage
import Foundation

public enum NetworkTracking {
    public static func installGlobalURLProtocol(
        store: NetworkTransactionStore,
        eventStore: EventStore? = nil,
        configuration: AppVitalsConfiguration
    ) {
        AppVitalsURLProtocol.configure(store: store, eventStore: eventStore, configuration: configuration)
        URLProtocol.registerClass(AppVitalsURLProtocol.self)
    }

    public static func sessionConfiguration(from base: URLSessionConfiguration = .default) -> URLSessionConfiguration {
        let configuration = base
        var protocolClasses = configuration.protocolClasses ?? []
        if !protocolClasses.contains(where: { $0 == AppVitalsURLProtocol.self }) {
            protocolClasses.insert(AppVitalsURLProtocol.self, at: 0)
        }
        configuration.protocolClasses = protocolClasses
        return configuration
    }
}
