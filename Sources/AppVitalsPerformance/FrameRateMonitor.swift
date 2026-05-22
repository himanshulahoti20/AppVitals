import AppVitalsCore
import AppVitalsStorage
import Foundation

#if canImport(UIKit)
    import UIKit

    /// Monitors display frame rate and logs a warning event whenever FPS drops below `dropThreshold`.
    /// All CADisplayLink interaction is dispatched to the main thread. The class is `@unchecked Sendable`
    /// because the mutable display-link state is only ever read/written on the main thread.
    public final class FrameRateMonitor: @unchecked Sendable {
        private var displayLink: CADisplayLink?
        private var lastTimestamp: Double = 0
        private var accumulatedTime: Double = 0
        private var frameCount: Int = 0

        private let dropThreshold: Double
        private let sampleInterval: Double = 1.0
        private let eventStore: EventStore

        public init(dropThreshold: Double = 50.0, eventStore: EventStore) {
            self.dropThreshold = dropThreshold
            self.eventStore = eventStore
        }

        public func start() {
            DispatchQueue.main.async { [weak self] in
                guard let self, displayLink == nil else { return }
                let link = CADisplayLink(target: self, selector: #selector(tick(_:)))
                link.add(to: .main, forMode: .common)
                displayLink = link
            }
        }

        public func stop() {
            DispatchQueue.main.async { [weak self] in
                self?.displayLink?.invalidate()
                self?.displayLink = nil
                self?.lastTimestamp = 0
                self?.accumulatedTime = 0
                self?.frameCount = 0
            }
        }

        @objc private func tick(_ link: CADisplayLink) {
            guard lastTimestamp > 0 else {
                lastTimestamp = link.timestamp
                return
            }
            let delta = link.timestamp - lastTimestamp
            lastTimestamp = link.timestamp
            accumulatedTime += delta
            frameCount += 1

            guard accumulatedTime >= sampleInterval else { return }

            let fps = Double(frameCount) / accumulatedTime
            accumulatedTime = 0
            frameCount = 0

            guard fps < dropThreshold else { return }

            let store = eventStore
            let captured = fps
            let threshold = dropThreshold
            Task {
                await store.append(AppVitalsEvent(
                    category: .performance,
                    level: .warning,
                    message: String(format: "Frame drop: %.1f FPS", captured),
                    metadata: [
                        "fps": String(format: "%.1f", captured),
                        "threshold": String(format: "%.0f", threshold),
                    ]
                ))
            }
        }
    }

#else

    /// Stub for platforms without UIKit — FPS monitoring is a no-op on macOS.
    public final class FrameRateMonitor: @unchecked Sendable {
        public init(dropThreshold: Double = 50.0, eventStore: EventStore) {}
        public func start() {}
        public func stop() {}
    }

#endif
