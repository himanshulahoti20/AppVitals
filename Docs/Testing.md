# Testing

AppVitals uses Swift Testing for package tests.

Run everything:

```bash
swift test
```

## Unit Tests

- Core: value semantics, limits, redaction policy, ring buffer behavior
- Storage: actor append/search/capacity behavior
- Network: JSON formatting, cURL generation, redaction, URLProtocol integration
- AppVitals: facade behavior and runtime wiring

## Async Patterns

Storage APIs are actor-isolated, so tests should use `await` directly:

```swift
await store.append(event)
let events = await store.all()
#expect(events.count == 1)
```

For facade APIs that intentionally fire-and-forget onto tasks, allow a tiny async hop before asserting.

## Integration Testing

Use `MockURLProtocol` from `AppVitalsTestingSupport` to test URLSession integrations without hitting the network.

## UI Testing

Recommended app-level UI tests:

- root view presents console when shake is simulated or a debug affordance toggles it
- search filters logs and requests
- network detail shows request, response, and cURL sections
- dark mode snapshots for compact and regular width

## Performance Testing

Recommended benchmarks:

- append 10,000 events into a store capped at 500
- capture 1,000 network transactions with 256 KB body limits
- measure console refresh latency with full stores
- verify URLProtocol callback path does not block the main thread

## Memory Leak Testing

Recommended checks:

- repeated presentation/dismissal of `AppVitalsConsoleView`
- repeated URLSession capture cycles
- large response bodies over the configured body limit
- root view modifier lifecycle during navigation changes
