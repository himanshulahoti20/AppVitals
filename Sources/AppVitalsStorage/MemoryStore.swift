import AppVitalsCore
import Foundation

public actor MemoryStore {
    private var snapshots: RingBuffer<MemorySnapshot>
    private var objectStats: [String: (created: Int, disposed: Int)] = [:]
    private var streamCounts: [String: Int] = [:]
    private var viewRebuilds: [String: (count: Int, lastAt: Date)] = [:]

    public init(snapshotLimit: Int = 60) {
        snapshots = RingBuffer(capacity: snapshotLimit)
    }

    public func recordSnapshot(_ snapshot: MemorySnapshot) {
        snapshots.append(snapshot)
    }

    public func allSnapshots() -> [MemorySnapshot] {
        snapshots.elements
    }

    public func latestSnapshot() -> MemorySnapshot? {
        snapshots.elements.last
    }

    public func objectCreated(_ name: String) {
        let current = objectStats[name] ?? (0, 0)
        objectStats[name] = (current.created + 1, current.disposed)
    }

    public func objectDisposed(_ name: String) {
        let current = objectStats[name] ?? (0, 0)
        objectStats[name] = (current.created, min(current.created, current.disposed + 1))
    }

    public func allObjectStats() -> [ObjectLifecycleStats] {
        objectStats
            .map { ObjectLifecycleStats(name: $0.key, created: $0.value.created, disposed: $0.value.disposed) }
            .sorted { $0.name < $1.name }
    }

    public func streamOpened(_ name: String) {
        streamCounts[name, default: 0] += 1
    }

    public func streamClosed(_ name: String) {
        let current = streamCounts[name] ?? 0
        streamCounts[name] = max(0, current - 1)
    }

    public func allStreamStats() -> [StreamStats] {
        streamCounts
            .filter { $0.value > 0 }
            .map { StreamStats(name: $0.key, activeCount: $0.value) }
            .sorted { $0.name < $1.name }
    }

    public func viewRebuilt(_ name: String) {
        let current = viewRebuilds[name]
        viewRebuilds[name] = ((current?.count ?? 0) + 1, Date())
    }

    public func allViewRebuildStats() -> [ViewRebuildStats] {
        viewRebuilds
            .map { ViewRebuildStats(name: $0.key, rebuildCount: $0.value.count, lastRebuildAt: $0.value.lastAt) }
            .sorted { $0.rebuildCount > $1.rebuildCount }
    }

    public func clear() {
        snapshots.removeAll()
        objectStats.removeAll()
        streamCounts.removeAll()
        viewRebuilds.removeAll()
    }
}
