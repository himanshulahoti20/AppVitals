import AppVitalsCore
import AppVitalsStorage
import Foundation

#if canImport(Darwin)
    import Darwin

    /// Polls physical memory footprint at a fixed interval and logs warning events on significant spikes.
    /// Timer callbacks are always on the main thread; mutable timer/sample state is therefore main-thread-only.
    /// The class is `@unchecked Sendable` for the same reason as `FrameRateMonitor`.
    public final class MemoryMonitor: @unchecked Sendable {
        private var timer: Timer?
        private var lastSampleMB: Double = 0

        private let sampleInterval: TimeInterval
        private let spikeThresholdMB: Double
        private let memoryStore: MemoryStore
        private let eventStore: EventStore

        public init(
            sampleInterval: TimeInterval = 5.0,
            spikeThresholdMB: Double = 50.0,
            memoryStore: MemoryStore,
            eventStore: EventStore
        ) {
            self.sampleInterval = sampleInterval
            self.spikeThresholdMB = spikeThresholdMB
            self.memoryStore = memoryStore
            self.eventStore = eventStore
        }

        public func start() {
            DispatchQueue.main.async { [weak self] in
                guard let self, timer == nil else { return }
                let newTimer = Timer.scheduledTimer(withTimeInterval: sampleInterval, repeats: true) { [weak self] _ in
                    self?.sample()
                }
                newTimer.tolerance = 1.0
                timer = newTimer
                sample()
            }
        }

        public func stop() {
            DispatchQueue.main.async { [weak self] in
                self?.timer?.invalidate()
                self?.timer = nil
                self?.lastSampleMB = 0
            }
        }

        private func sample() {
            guard let bytes = physicalFootprint() else { return }
            let snapshot = MemorySnapshot(usedBytes: bytes)
            let mb = snapshot.usedMB
            let previous = lastSampleMB
            lastSampleMB = mb

            let store = memoryStore
            let events = eventStore
            let threshold = spikeThresholdMB
            Task {
                await store.recordSnapshot(snapshot)
                let delta = mb - previous
                if previous > 0, delta >= threshold {
                    await events.append(AppVitalsEvent(
                        category: .performance,
                        level: .warning,
                        message: String(format: "Memory spike: +%.1f MB (now %.1f MB)", delta, mb),
                        metadata: [
                            "delta_mb": String(format: "%.1f", delta),
                            "used_mb": String(format: "%.1f", mb),
                        ]
                    ))
                }
            }
        }

        private func physicalFootprint() -> UInt64? {
            var info = mach_task_basic_info()
            var count = mach_msg_type_number_t(
                MemoryLayout<mach_task_basic_info>.size / MemoryLayout<integer_t>.size
            )
            let result = withUnsafeMutablePointer(to: &info) {
                $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                    task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
                }
            }
            return result == KERN_SUCCESS ? UInt64(info.resident_size) : nil
        }
    }

#else

    public final class MemoryMonitor: @unchecked Sendable {
        public init(
            sampleInterval: TimeInterval = 5.0,
            spikeThresholdMB: Double = 50.0,
            memoryStore: MemoryStore,
            eventStore: EventStore
        ) {}
        public func start() {}
        public func stop() {}
    }

#endif

// MARK: - Lifecycle tracking

/// Store a `LifecycleToken` as a property in any class you want to track.
/// When the owning object deinits, the token deinits too, automatically recording the disposal.
public final class LifecycleToken: Sendable {
    private let name: String
    private let store: MemoryStore

    public init(name: String, store: MemoryStore) {
        self.name = name
        self.store = store
        let capturedStore = store
        let capturedName = name
        Task { await capturedStore.objectCreated(capturedName) }
    }

    deinit {
        let capturedStore = store
        let capturedName = name
        Task { await capturedStore.objectDisposed(capturedName) }
    }
}

// MARK: - Stream / listener tracking

/// Hold a `StreamToken` for the lifetime of a subscription or async stream consumer.
/// Disposing (nil-ing) the token decrements the active count for that stream name.
public final class StreamToken: Sendable {
    private let name: String
    private let store: MemoryStore

    public init(name: String, store: MemoryStore) {
        self.name = name
        self.store = store
        let capturedStore = store
        let capturedName = name
        Task { await capturedStore.streamOpened(capturedName) }
    }

    deinit {
        let capturedStore = store
        let capturedName = name
        Task { await capturedStore.streamClosed(capturedName) }
    }
}
