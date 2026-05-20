import AppVitalsCore
import AppVitalsStorage
import Foundation
import Observation

@MainActor
@Observable
public final class AppVitalsConsoleModel {
    public var searchText = ""
    public var selectedCategory: AppVitalsEventCategory?
    public private(set) var transactions: [NetworkTransaction] = []
    private var allEvents: [AppVitalsEvent] = []

    private let stores: AppVitalsStores

    public init(stores: AppVitalsStores) {
        self.stores = stores
    }

    /// Computed so SwiftUI automatically re-renders when selectedCategory or allEvents changes.
    public var events: [AppVitalsEvent] {
        guard let cat = selectedCategory else { return allEvents }
        return allEvents.filter { $0.category == cat }
    }

    /// Errors tab always shows all error-level events regardless of the category filter.
    public var errors: [AppVitalsEvent] {
        allEvents.filter { $0.level == .error || $0.category == .error }
    }

    public func refresh() async {
        async let fetchedEvents = stores.events.search(searchText)
        async let fetchedTransactions = stores.network.search(searchText)
        allEvents = await fetchedEvents
        transactions = await fetchedTransactions
    }

    public func exportLogsText() -> String {
        let formatter = ISO8601DateFormatter()
        return events.map {
            "[\(formatter.string(from: $0.timestamp))] [\($0.level.rawValue.uppercased())] [\($0.category.rawValue)] \($0.message)"
        }.joined(separator: "\n")
    }

    public func exportNetworkText() -> String {
        let formatter = ISO8601DateFormatter()
        return transactions.map {
            let status = $0.response.map { "\($0.statusCode)" } ?? "—"
            let duration = $0.duration.map { String(format: "%.3fs", $0) } ?? "—"
            return "[\(formatter.string(from: $0.startedAt))] \($0.request.method) \(status) \(duration) \($0.request.url.absoluteString)"
        }.joined(separator: "\n")
    }

    public func exportErrorsText() -> String {
        let formatter = ISO8601DateFormatter()
        return errors.map {
            "[\(formatter.string(from: $0.timestamp))] [\($0.level.rawValue.uppercased())] \($0.message)"
        }.joined(separator: "\n")
    }
}
