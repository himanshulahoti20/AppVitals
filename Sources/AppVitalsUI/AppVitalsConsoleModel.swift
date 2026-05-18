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
}
