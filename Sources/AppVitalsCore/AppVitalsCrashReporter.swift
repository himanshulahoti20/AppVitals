/// Implement this protocol to forward AppVitals events to an external crash-reporting SDK.
///
/// Pass one or more reporters to ``AppVitals/start(_:crashReporters:)``. AppVitals calls
/// ``recordNonFatal(message:metadata:)`` for every error-level event and
/// ``addBreadcrumb(message:category:level:metadata:)`` for every event, giving Sentry-style
/// trail-of-events context. ``setScreenContext(_:)`` is called each time the visible screen changes.
///
/// See `Docs/CrashReporterIntegration.md` for ready-to-use Firebase Crashlytics and Sentry implementations.
public protocol AppVitalsCrashReporter: Sendable {
    /// Called for events whose level is `.error` or whose category is `.error`.
    /// Map this to a non-fatal error report in your SDK.
    func recordNonFatal(message: String, metadata: [String: String])

    /// Called for every logged event. Map this to breadcrumbs, log statements, or custom timeline entries.
    func addBreadcrumb(message: String, category: String, level: AppVitalsLogLevel, metadata: [String: String])

    /// Called whenever the visible screen name changes (including `nil` when a screen is dismissed).
    /// Use this to set a custom key on the active crash report scope.
    func setScreenContext(_ screenName: String?)

    /// Called to attach arbitrary key-value pairs to the crash report scope.
    func setExtraContext(key: String, value: String)
}

public extension AppVitalsCrashReporter {
    func addBreadcrumb(message: String, category: String, level: AppVitalsLogLevel, metadata: [String: String]) {}
    func setScreenContext(_ screenName: String?) {}
    func setExtraContext(key: String, value: String) {}
}
