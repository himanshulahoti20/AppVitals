import AppVitalsCore
import AppVitalsStorage
import Testing

@Test func runStoreTracksStatusAndCapsRuns() async throws {
    let store = TestRunStore(limit: 2)
    let first = await store.begin(name: "a", kind: .unit)
    let second = await store.begin(name: "b", kind: .widget)
    let third = await store.begin(name: "c", kind: .integration)

    #expect(await store.all().map(\.name) == ["b", "c"])
    #expect(await store.run(first.id) == nil)

    let passed = try #require(await store.finish(second.id))
    #expect(passed.status == .passed)
    let failed = try #require(await store.finish(third.id, failure: "boom"))
    #expect(failed.status == .failed)
    #expect(failed.failureMessage == "boom")
    #expect(failed.endedAt != nil)
}
