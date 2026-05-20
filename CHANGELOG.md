# Changelog

All notable changes to AppVitals are documented here.

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
