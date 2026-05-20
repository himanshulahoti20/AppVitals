# Crash Reporter Integration

AppVitals forwards events to external crash-reporting SDKs through the `AppVitalsCrashReporter` protocol. No additional package dependencies are required — implement the protocol against whichever SDK you already have set up.

## How it works

| AppVitals action | Protocol method called |
|---|---|
| Any `AppVitals.log(...)` call | `addBreadcrumb` |
| `AppVitals.log(..., level: .error)` or `category: .error` | `addBreadcrumb` + `recordNonFatal` |
| `AppVitals.screen("Name")` | `setScreenContext` |

Only `recordNonFatal` is required. The other three methods have no-op defaults so you only override what your SDK supports.

---

## Firebase Crashlytics

Add the `FirebaseCrashlytics` package to your app target, then paste this struct anywhere in your app:

```swift
import AppVitals
import FirebaseCrashlytics

struct AppVitalsFirebaseReporter: AppVitalsCrashReporter {

    func recordNonFatal(message: String, metadata: [String: String]) {
        let error = NSError(
            domain: "AppVitals",
            code: -1,
            userInfo: metadata.merging([NSLocalizedDescriptionKey: message]) { $1 }
        )
        Crashlytics.crashlytics().record(error: error)
    }

    func addBreadcrumb(message: String, category: String, level: AppVitalsLogLevel, metadata: [String: String]) {
        Crashlytics.crashlytics().log("[\(level.rawValue.uppercased())] [\(category)] \(message)")
    }

    func setScreenContext(_ screenName: String?) {
        Crashlytics.crashlytics().setCustomValue(screenName ?? "", forKey: "av_screen")
    }

    func setExtraContext(key: String, value: String) {
        Crashlytics.crashlytics().setCustomValue(value, forKey: key)
    }
}
```

Register it at startup:

```swift
AppVitals.start(.current, crashReporters: [AppVitalsFirebaseReporter()])
```

---

## Sentry

Add the `Sentry` package to your app target, then paste this struct anywhere in your app:

```swift
import AppVitals
import Sentry

struct AppVitalsSentryReporter: AppVitalsCrashReporter {

    func recordNonFatal(message: String, metadata: [String: String]) {
        let event = Event(level: .error)
        event.message = SentryMessage(formatted: message)
        event.extra = metadata as [String: Any]
        SentrySDK.capture(event: event)
    }

    func addBreadcrumb(message: String, category: String, level: AppVitalsLogLevel, metadata: [String: String]) {
        let crumb = Breadcrumb()
        crumb.message = message
        crumb.category = category
        crumb.level = sentryLevel(from: level)
        crumb.data = metadata
        SentrySDK.addBreadcrumb(crumb)
    }

    func setScreenContext(_ screenName: String?) {
        SentrySDK.configureScope { scope in
            if let name = screenName {
                scope.setTag(value: name, key: "av_screen")
            } else {
                scope.removeTag(key: "av_screen")
            }
        }
    }

    func setExtraContext(key: String, value: String) {
        SentrySDK.configureScope { scope in
            scope.setExtra(value: value, key: key)
        }
    }

    private func sentryLevel(from level: AppVitalsLogLevel) -> SentryLevel {
        switch level {
        case .debug:   return .debug
        case .info:    return .info
        case .warning: return .warning
        case .error:   return .error
        }
    }
}
```

Register it at startup:

```swift
AppVitals.start(.current, crashReporters: [AppVitalsSentryReporter()])
```

---

## Both SDKs at once

```swift
AppVitals.start(
    .current,
    crashReporters: [
        AppVitalsFirebaseReporter(),
        AppVitalsSentryReporter()
    ]
)
```

---

## Writing a custom reporter

Any type that conforms to `AppVitalsCrashReporter` and is `Sendable` works — struct or class.

```swift
struct MyReporter: AppVitalsCrashReporter {
    func recordNonFatal(message: String, metadata: [String: String]) {
        // forward to your backend
    }
}
```
