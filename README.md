# AppVitals

[![CI](https://github.com/himanshulahoti20/AppVitals/actions/workflows/ci.yml/badge.svg)](https://github.com/himanshulahoti20/AppVitals/actions/workflows/ci.yml)
[![Latest Release](https://img.shields.io/github/v/release/himanshulahoti20/AppVitals?sort=semver)](https://github.com/himanshulahoti20/AppVitals/releases)
[![License](https://img.shields.io/github/license/himanshulahoti20/AppVitals)](LICENSE)
[![Swift Package Manager](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![Swift Compatibility](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fhimanshulahoti20%2FAppVitals%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/himanshulahoti20/AppVitals)
[![Platform Compatibility](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fhimanshulahoti20%2FAppVitals%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/himanshulahoti20/AppVitals)


Production debugging toolkit for modern iOS apps.

AppVitals is a lightweight Swift package that gives teams an in-app diagnostics console for logs, network requests, errors, and recent crash context without pulling in an enterprise observability stack.

![AppVitals Debug Console](Demo/Assets/appvitals-demo.gif)

```swift
import AppVitals

@main
struct ExampleApp: App {
    init() {
        AppVitals.start()
        AppVitals.trackNetwork()
        AppVitals.enableShakeToDebug()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .appVitalsDebugOverlay(stores: AppVitals.stores)
        }
    }
}
```

## Features

- URLSession inspection through `URLProtocol`
- request method, URL, headers, request body, response body, status, duration, and error capture
- cURL export and pretty JSON formatting
- actor-backed event, network, and memory stores
- app, navigation, warning, error, network, performance, and custom timeline events
- SwiftUI debug console with Logs, Network, Errors, Timeline, and Memory tabs
- memory usage chart, object lifecycle tracking, stream/listener monitoring, and view rebuild analysis
- shake-to-debug view modifier and floating debug bubble
- crash context persistence for recent logs, requests, and visible screen name
- Swift 6, SwiftUI, Observation, async/await, and Swift Testing

## Install

Add this repository in Xcode:

```text
File > Add Package Dependencies...
```

Then import the umbrella module:

```swift
import AppVitals
```

## Quick Start

```swift
AppVitals.start()
AppVitals.trackNetwork()
AppVitals.log("User tapped checkout")
AppVitals.screen("Checkout")
```

Attach the console to your root view:

```swift
RootView()
    .appVitalsDebugOverlay(stores: AppVitals.stores)
```

For explicit URLSession configurations:

```swift
let configuration = NetworkTracking.sessionConfiguration()
let session = URLSession(configuration: configuration)
```

## Memory Monitoring

Enable memory insights in debug builds:

```swift
// Enabled automatically with the .debug preset:
AppVitals.start(.debug)
```

Track object lifetimes — leaks show as non-zero "alive" counts in the Memory tab:

```swift
class ProductViewModel: ObservableObject {
    private let _lifetime = AppVitals.trackLifetime(named: "ProductViewModel")
}
```

Track active subscriptions or async streams:

```swift
class FeedViewModel {
    private var _feedToken: StreamToken?

    func subscribe() {
        _feedToken = AppVitals.trackStream(named: "FeedStream")
    }
    func unsubscribe() { _feedToken = nil }
}
```

Count SwiftUI view rebuilds automatically:

```swift
ProductListView()
    .trackRebuilds("ProductListView", store: AppVitals.stores.memory)
```

## Modules

- `AppVitalsCore`: models, configuration, redaction policy, ring buffer, crash context contracts, memory snapshot types
- `AppVitalsStorage`: actor-backed event, network, crash context, and memory stores
- `AppVitalsNetwork`: URLProtocol capture, redaction, body formatting, cURL export
- `AppVitalsPerformance`: FPS monitor, memory monitor, lifecycle and stream tokens
- `AppVitalsUI`: SwiftUI console, search, filters, memory tab, shake overlay modifier
- `AppVitalsTestingSupport`: mock URL protocol and test factories
- `AppVitals`: umbrella API for simple app integration

## Production Safety

AppVitals defaults to bounded in-memory storage and redacts sensitive headers/query items such as authorization tokens, cookies, API keys, and passwords. Body capture is byte-limited by configuration.

## Documentation

See [Docs/Architecture.md](Docs/Architecture.md), [Docs/Testing.md](Docs/Testing.md), and [Docs/Release.md](Docs/Release.md).

## Sponsorship

AppVitals is free and open source. If it saves you time or helps your team ship better iOS apps, consider [sponsoring development](https://github.com/sponsors/himanshulahoti20).
