# Testing

AppVitals uses Swift Testing for package tests.

Run everything:

```bash
swift test
```

## Test Observability

AppVitals can record what happens *while your tests run* and produce a report per test.

```swift
try await AppVitals.test(named: "Checkout flow", kind: .integration) {
    await AppVitals.testLog("Tapped Pay")
    try await api.checkout(cart)
}
```

- `AppVitals.test` passes if the body returns, fails (and rethrows) if it throws.
- For assertion-based failures (`#expect`, `XCTAssert`) use `beginTest` / `endTest(_:failure:)` and pass the failure message.
- `endTest` returns a `TestReport` with the timeline, API logs, failure diagnostics, and performance numbers.
- Export with `plainText()`, `jsonData()`, or `write(to:)`, and attach the files in CI (for example `actions/upload-artifact`) or as `XCTAttachment`s.
- Use `AppVitals.testLog` (awaitable) inside async tests; `AppVitals.log(_, category: .test)` is fire-and-forget and may land after `endTest`.
- Network capture needs `AppVitals.trackNetwork()` (or the `.debug` preset). Memory and frame-drop numbers need the matching monitors enabled.
- Data is attributed by time window; run suites serially for clean per-test reports. Event and request stores are bounded, so very chatty tests can push early entries out.
- Inspect runs on a device in the console's **Tests** tab.

## Unit Tests

- Core: value semantics, limits, redaction policy, ring buffer behavior
- Storage: actor append/search/capacity behavior
- Network: JSON formatting, cURL generation, redaction, URLProtocol integration
- AppVitals: facade behavior and runtime wiring
- Test observability: run store lifecycle, report windowing, failure diagnostics, JSON round-trip, and pass/fail via the facade

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
