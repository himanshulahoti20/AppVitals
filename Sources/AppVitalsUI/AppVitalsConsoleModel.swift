import AppVitalsCore
import AppVitalsStorage
import Foundation
import Observation

public enum NetworkStatusFilter: String, CaseIterable, Sendable {
    case success = "2xx"
    case redirect = "3xx"
    case clientError = "4xx"
    case serverError = "5xx"
    case failed = "Failed"
}

public enum TimelineEntry: Identifiable, Sendable {
    case event(AppVitalsEvent)
    case transaction(NetworkTransaction)

    public var id: UUID {
        switch self {
        case let .event(event): event.id
        case let .transaction(transaction): transaction.id
        }
    }

    public var timestamp: Date {
        switch self {
        case let .event(event): event.timestamp
        case let .transaction(transaction): transaction.startedAt
        }
    }
}

@MainActor
@Observable
public final class AppVitalsConsoleModel {
    public var searchText = ""
    public var selectedCategory: AppVitalsEventCategory?
    public private(set) var transactions: [NetworkTransaction] = []
    public private(set) var memorySnapshots: [MemorySnapshot] = []
    public private(set) var objectLifecycleStats: [ObjectLifecycleStats] = []
    public private(set) var streamStats: [StreamStats] = []
    public private(set) var viewRebuildStats: [ViewRebuildStats] = []
    private var allEvents: [AppVitalsEvent] = []

    public var networkMethodFilter: String?
    public var networkStatusFilter: NetworkStatusFilter?
    public var isGroupedByHost: Bool = false
    public var showSlowOnly: Bool = false

    private let stores: AppVitalsStores

    public init(stores: AppVitalsStores) {
        self.stores = stores
    }

    /// Filtered by category if one is selected; otherwise all events.
    public var events: [AppVitalsEvent] {
        guard let cat = selectedCategory else { return allEvents }
        return allEvents.filter { $0.category == cat }
    }

    /// All error-level events regardless of the category filter.
    public var errors: [AppVitalsEvent] {
        allEvents.filter { $0.level == .error || $0.category == .error }
    }

    /// Transactions with method, status, and slow-only filters applied.
    public var filteredTransactions: [NetworkTransaction] {
        transactions.filter { tx in
            if let method = networkMethodFilter {
                guard tx.request.method.uppercased() == method else { return false }
            }
            if let status = networkStatusFilter {
                switch status {
                case .success:
                    guard let statusCode = tx.response?.statusCode, (200 ..< 300).contains(statusCode) else { return false }
                case .redirect:
                    guard let statusCode = tx.response?.statusCode, (300 ..< 400).contains(statusCode) else { return false }
                case .clientError:
                    guard let statusCode = tx.response?.statusCode, (400 ..< 500).contains(statusCode) else { return false }
                case .serverError:
                    guard let statusCode = tx.response?.statusCode, statusCode >= 500 else { return false }
                case .failed:
                    guard tx.response == nil else { return false }
                }
            }
            if showSlowOnly {
                guard let duration = tx.duration, duration > 2.0 else { return false }
            }
            return true
        }
    }

    /// `filteredTransactions` grouped by host, sorted alphabetically.
    public var groupedByHost: [(host: String, transactions: [NetworkTransaction])] {
        let dict = Dictionary(grouping: filteredTransactions) {
            $0.request.url.host ?? "unknown"
        }
        return dict.map { (host: $0.key, transactions: $0.value) }
            .sorted { $0.host < $1.host }
    }

    /// All events and network transactions merged and sorted newest-first.
    public var timeline: [TimelineEntry] {
        let events = allEvents.map { TimelineEntry.event($0) }
        let txs = transactions.map { TimelineEntry.transaction($0) }
        return (events + txs).sorted { $0.timestamp > $1.timestamp }
    }

    public func refresh() async {
        async let fetchedEvents = stores.events.search(searchText)
        async let fetchedTransactions = stores.network.search(searchText)
        async let fetchedSnapshots = stores.memory.allSnapshots()
        async let fetchedObjects = stores.memory.allObjectStats()
        async let fetchedStreams = stores.memory.allStreamStats()
        async let fetchedRebuilds = stores.memory.allViewRebuildStats()
        allEvents = await fetchedEvents
        transactions = await fetchedTransactions
        memorySnapshots = await fetchedSnapshots
        objectLifecycleStats = await fetchedObjects
        streamStats = await fetchedStreams
        viewRebuildStats = await fetchedRebuilds
    }

    public func exportLogsText() -> String {
        let formatter = ISO8601DateFormatter()
        return events.map {
            "[\(formatter.string(from: $0.timestamp))] [\($0.level.rawValue.uppercased())] [\($0.category.rawValue)] \($0.message)"
        }.joined(separator: "\n")
    }

    public func exportNetworkText() -> String {
        let formatter = ISO8601DateFormatter()
        return filteredTransactions.map {
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

    public func exportMemoryText() -> String {
        var lines: [String] = []
        if let latest = memorySnapshots.last {
            lines.append(String(format: "Current memory: %.1f MB", latest.usedMB))
            if let peak = memorySnapshots.map(\.usedMB).max() {
                lines.append(String(format: "Peak memory: %.1f MB", peak))
            }
        }
        if !objectLifecycleStats.isEmpty {
            lines.append("\nObject Lifecycle:")
            for stat in objectLifecycleStats {
                lines.append("  \(stat.name): created=\(stat.created) disposed=\(stat.disposed) active=\(stat.active)")
            }
        }
        if !streamStats.isEmpty {
            lines.append("\nActive Streams:")
            for stat in streamStats {
                lines.append("  \(stat.name): \(stat.activeCount) active")
            }
        }
        if !viewRebuildStats.isEmpty {
            lines.append("\nView Rebuilds:")
            for stat in viewRebuildStats {
                lines.append("  \(stat.name): \(stat.rebuildCount) rebuilds")
            }
        }
        return lines.joined(separator: "\n")
    }

    public func exportTimelineText() -> String {
        let formatter = ISO8601DateFormatter()
        return timeline.map { entry in
            switch entry {
            case let .event(event):
                return """
                [\(formatter.string(from: event.timestamp))] EVENT [\(event.level.rawValue.uppercased())] \
                [\(event.category.rawValue)] \(event.message)
                """
            case let .transaction(transaction):
                let status = transaction.response.map { "\($0.statusCode)" } ?? "—"
                let duration = transaction.duration.map { String(format: "%.3fs", $0) } ?? "—"
                return """
                [\(formatter.string(from: transaction.startedAt))] NET \(transaction.request.method) \
                \(status) \(duration) \(transaction.request.url.absoluteString)
                """
            }
        }.joined(separator: "\n")
    }
}
