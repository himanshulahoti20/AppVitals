import AppVitalsCore
import AppVitalsStorage
import Foundation

public enum AppVitalsTestFactory {
    public static func event(
        _ message: String = "Test event",
        category: AppVitalsEventCategory = .custom,
        level: AppVitalsLogLevel = .info
    ) -> AppVitalsEvent {
        AppVitalsEvent(category: category, level: level, message: message)
    }

    public static func transaction(url: URL? = nil) -> NetworkTransaction {
        guard let url = url ?? URL(string: "https://example.com/api") else { preconditionFailure("Invalid default URL") }
        return NetworkTransaction(
            request: NetworkRequestSnapshot(method: "GET", url: url),
            response: NetworkResponseSnapshot(statusCode: 200, headers: ["Content-Type": "application/json"], body: Data("{}".utf8))
        )
    }

    public static func stores(eventLimit: Int = 10, networkLimit: Int = 10) -> AppVitalsStores {
        AppVitalsStores(
            events: EventStore(limit: eventLimit),
            network: NetworkTransactionStore(limit: networkLimit),
            crashContext: CrashContextStore(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        )
    }
}
