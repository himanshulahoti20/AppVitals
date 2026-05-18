# Architecture

AppVitals is intentionally modular. The package should be easy to adopt as a single umbrella import while still letting advanced teams depend on only the pieces they need.

## Dependency Boundaries

```text
AppVitals
├── AppVitalsCore
├── AppVitalsStorage -> AppVitalsCore
├── AppVitalsNetwork -> AppVitalsCore, AppVitalsStorage
├── AppVitalsUI -> AppVitalsCore, AppVitalsStorage, AppVitalsNetwork
└── AppVitalsTestingSupport -> AppVitalsCore, AppVitalsStorage, AppVitalsNetwork
```

`AppVitalsCore` has no dependency on storage, networking, or UI. Public data contracts live there so every other target can share stable types without cycles.

## Public API

The default developer experience is deliberately tiny:

```swift
AppVitals.start()
AppVitals.trackNetwork()
AppVitals.enableShakeToDebug()
AppVitals.log("User tapped checkout")
AppVitals.screen("Checkout")
```

Advanced teams can directly instantiate `EventStore`, `NetworkTransactionStore`, `CrashContextStore`, `AppVitalsConsoleView`, or use `NetworkTracking.sessionConfiguration()`.

## Storage

`EventStore` and `NetworkTransactionStore` are actors wrapping bounded `RingBuffer` values. Reads and writes are serialized, non-blocking for callers, and safe under concurrent app and network activity.

## Networking

`AppVitalsURLProtocol` intercepts HTTP(S) URLSession traffic. It records request snapshots before forwarding the request and records response/error snapshots after completion. It marks forwarded requests with an internal property to avoid recursion.

Current support is URLSession-first. Alamofire support should be layered through an adapter target or extension that forwards request/response snapshots into `NetworkTransactionStore` without changing core storage contracts.

## UI

`AppVitalsConsoleView` is SwiftUI-first and backed by an Observation model. It presents:

- Logs
- Network
- Errors

The root app can attach `.appVitalsDebugOverlay(stores:)` to enable shake presentation. The modifier keeps UIKit-specific shake detection isolated behind `UIViewControllerRepresentable`.

## Crash Context

Apps should call:

```swift
AppVitals.screen("Checkout")
AppVitals.persistCrashContext()
```

The crash context store writes recent logs, recent requests, and visible screen name as JSON using atomic file writes. Future work can add signal-safe breadcrumbs and integration adapters for crash reporters.

## Naming Conventions

- Public model types use `AppVitals` or domain-specific prefixes where ambiguity is likely.
- Storage actors end in `Store`.
- Snapshot models are immutable value types and conform to `Codable`, `Equatable`, and `Sendable`.
- UI types end in `View`, `Modifier`, or `Model`.
