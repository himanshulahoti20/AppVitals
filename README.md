# AppVitals

[![Swift Compatibility](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fhimanshulahoti20%2FAppVitals%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/himanshulahoti20/AppVitals)
[![Platform Compatibility](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fhimanshulahoti20%2FAppVitals%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/himanshulahoti20/AppVitals)
[![Sponsor](https://img.shields.io/github/sponsors/himanshulahoti20?label=Sponsor&logo=GitHub)](https://github.com/sponsors/himanshulahoti20)

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
- actor-backed event and network stores
- app, navigation, warning, error, network, and custom timeline events
- SwiftUI debug console with Logs, Network, and Errors tabs
- shake-to-debug view modifier
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

## Modules

- `AppVitalsCore`: models, configuration, redaction policy, ring buffer, crash context contracts
- `AppVitalsStorage`: actor-backed event, network, and crash context stores
- `AppVitalsNetwork`: URLProtocol capture, redaction, body formatting, cURL export
- `AppVitalsUI`: SwiftUI console, search, filters, shake overlay modifier
- `AppVitalsTestingSupport`: mock URL protocol and test factories
- `AppVitals`: umbrella API for simple app integration

## Production Safety

AppVitals defaults to bounded in-memory storage and redacts sensitive headers/query items such as authorization tokens, cookies, API keys, and passwords. Body capture is byte-limited by configuration.

## Documentation

See [Docs/Architecture.md](Docs/Architecture.md), [Docs/Testing.md](Docs/Testing.md), and [Docs/Release.md](Docs/Release.md).

## Sponsorship

AppVitals is free and open source. If it saves you time or helps your team ship better iOS apps, consider [sponsoring development](https://github.com/sponsors/himanshulahoti20).
