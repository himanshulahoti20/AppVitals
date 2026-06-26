# Changelog

All notable changes to AppVitals are documented here.

## [1.3.0]

### Added

- **Memory usage monitoring** — `MemoryMonitor` polls resident memory every 5 seconds using `mach_task_basic_info` and stores snapshots in the new `MemoryStore`. Enable via `AppVitalsConfiguration.isMemoryMonitoringEnabled` or the `.debug` preset.
- **Memory spike warnings** — a `.performance` warning event is logged automatically when memory grows by more than `memorySpikeThresholdMB` (default 50 MB) between samples.
- **Object lifecycle tracking** — `AppVitals.trackLifetime(named:)` returns a `LifecycleToken`; store it as a property on any class. When the owning object deinits the token deinits too, recording the disposal. Created vs. disposed counts and live instance count are shown in the console.
- **Stream / listener monitoring** — `AppVitals.trackStream(named:)` returns a `StreamToken`. Nil the token to record the stream closing. Active stream counts are shown in the Memory tab.
- **View rebuild analysis** — `.trackRebuilds(_:store:)` view modifier counts every SwiftUI body re-evaluation for the decorated view without causing re-render loops. High-frequency views are highlighted in orange/red. Call `AppVitals.countRebuild(_:)` for manual tracking.
- **Memory tab in the debug console** — fifth tab in `AppVitalsConsoleView` showing a live memory chart, object lifecycle table, active streams, and view rebuild frequency sorted by count.
- **`MemoryStore` actor** — new `AppVitalsStorage` type holding memory snapshots (`RingBuffer`, capacity 60), object stats, stream counts, and view rebuild counters. Accessible via `AppVitals.stores.memory`.
- **Export** — the share button on the Memory tab exports a plain-text summary of current usage, object stats, streams, and rebuild counts.
- **`AppVitalsPerformance.LifecycleToken` and `StreamToken`** — public `Sendable` types available directly from the `AppVitalsPerformance` module for use without the umbrella.

### Changed

- `AppVitalsConfiguration.debug` preset now enables `isMemoryMonitoringEnabled: true`.
- `AppVitalsStores` gains a `memory: MemoryStore` property (default-initialised, fully backward compatible).
- `AppVitalsConsoleModel.refresh()` now concurrently fetches memory snapshots, object stats, stream stats, and view rebuild stats alongside events and network transactions.

## [1.2.0]

### Added

- **FPS monitor & frame drop detection** — `AppVitals.trackPerformance()` starts a `CADisplayLink`-based monitor that logs a `.performance` warning whenever the frame rate drops below the configured threshold (default 50 FPS). Configure via `AppVitalsConfiguration.isFPSMonitoringEnabled` and `fpsDropThreshold`.
- **Startup performance tracking** — `AppVitals.markStartupComplete()` logs the elapsed time from `start()` to the call site as a `.performance` event.
- **Slow request warnings** — any network request that exceeds `AppVitalsConfiguration.slowRequestThreshold` (default 3 s when using `.debug`) is automatically logged as a `.performance` warning with URL, method, duration, and status code.
- **API latency chart** — compact bar chart at the top of the Network tab showing the last 20 requests colour-coded by duration (blue <1 s, orange 1–3 s, red >3 s).
- **Timeline tab** — fourth tab in the console merging log events and network transactions into a single newest-first activity feed.
- **Request grouping** — "Group by Host" option in the network filter menu organises requests into collapsible host sections.
- **Advanced network filters** — filter by HTTP method (GET, POST, PUT, PATCH, DELETE), status class (2xx / 3xx / 4xx / 5xx / Failed), and "Slow Requests Only (>2 s)".
- **`AppVitalsPerformance` module** — new standalone target exposing `FrameRateMonitor` for direct use without the umbrella module.
- **`.performance` event category** — new `AppVitalsEventCategory.performance` case for FPS drops, startup time, and slow request events.
- **Alamofire integration guide** — see `Docs/AlamofireIntegration.md` for URLProtocol injection and `EventMonitor` approaches.

### Changed

- `AppVitalsConfiguration.debug` preset now enables `slowRequestThreshold: 3.0` and `isFPSMonitoringEnabled: true`.
- `NetworkTracking.installGlobalURLProtocol` gains an optional `eventStore` parameter (default `nil`, fully backward compatible) used for slow request warnings.
- Duration column in the Network tab highlights values above 2 s in orange.
- Network detail view now shows request duration in the Response section.

## [1.0.1]

### Added

- **Floating debug bubble** — draggable persistent `ladybug` button that overlays the app and taps open the console. Enabled via `appVitalsDebugOverlay(stores:showFloatingBubble:)`.
- **Quick open inspector** — `AppVitals.openConsole()` programmatically presents the console from anywhere in the app without a gesture.
- **Environment-aware configuration** — `.debug` preset enables all diagnostic features; `.current` automatically selects `.debug` in DEBUG builds and `.production` in release builds.
- **Log export** — share button in the console toolbar exports the current tab (Logs, Network, or Errors) as a plain-text file via the system share sheet.
- **Crash reporter integration** — `AppVitalsCrashReporter` protocol bridges AppVitals events to Firebase Crashlytics, Sentry, or any custom backend. Error-level events trigger `recordNonFatal`; every event adds a breadcrumb; screen transitions update scope context. Pass reporters to `AppVitals.start(_:crashReporters:)`. See `Docs/CrashReporterIntegration.md` for copy-paste implementations.

### Changed

- `appVitalsDebugOverlay(stores:isEnabled:)` gains a new `showFloatingBubble: Bool` parameter (default `false`, non-breaking).

## [1.0.0]

- Initial release: URLSession inspection, actor-backed event and network stores, SwiftUI debug console with Logs / Network / Errors tabs, shake-to-debug overlay, crash context persistence, cURL export, and sensitive data redaction.
