import AppVitalsCore
import Foundation

public actor EventStore {
    private var events: RingBuffer<AppVitalsEvent>

    public init(limit: Int = AppVitalsLimits.production.maxEvents) {
        events = RingBuffer(capacity: limit)
    }

    public func append(_ event: AppVitalsEvent) {
        events.append(event)
    }

    public func all() -> [AppVitalsEvent] {
        events.elements
    }

    public func search(_ query: String) -> [AppVitalsEvent] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return events.elements }
        return events.elements.filter {
            $0.message.localizedCaseInsensitiveContains(trimmed)
                || $0.category.rawValue.localizedCaseInsensitiveContains(trimmed)
                || $0.level.rawValue.localizedCaseInsensitiveContains(trimmed)
        }
    }

    public func removeAll() {
        events.removeAll()
    }
}
