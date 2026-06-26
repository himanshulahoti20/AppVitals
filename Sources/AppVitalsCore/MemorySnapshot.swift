import Foundation

public struct MemorySnapshot: Identifiable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let usedBytes: UInt64

    public var usedMB: Double {
        Double(usedBytes) / 1_048_576
    }

    public init(id: UUID = UUID(), timestamp: Date = Date(), usedBytes: UInt64) {
        self.id = id
        self.timestamp = timestamp
        self.usedBytes = usedBytes
    }
}

public struct ObjectLifecycleStats: Sendable {
    public let name: String
    public let created: Int
    public let disposed: Int

    public var active: Int {
        max(0, created - disposed)
    }

    public init(name: String, created: Int, disposed: Int) {
        self.name = name
        self.created = created
        self.disposed = disposed
    }
}

public struct StreamStats: Sendable {
    public let name: String
    public let activeCount: Int

    public init(name: String, activeCount: Int) {
        self.name = name
        self.activeCount = activeCount
    }
}

public struct ViewRebuildStats: Identifiable, Sendable {
    public var id: String {
        name
    }

    public let name: String
    public let rebuildCount: Int
    public let lastRebuildAt: Date

    public init(name: String, rebuildCount: Int, lastRebuildAt: Date) {
        self.name = name
        self.rebuildCount = rebuildCount
        self.lastRebuildAt = lastRebuildAt
    }
}
