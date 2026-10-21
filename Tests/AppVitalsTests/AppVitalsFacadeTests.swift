import AppVitals
import Testing

@Test func facadeLogsEvents() async throws {
    AppVitals.start()
    AppVitals.log("User tapped checkout")

    try await Task.sleep(for: .milliseconds(100))
    let events = await AppVitals.stores.events.search("checkout")

    #expect(events.contains { $0.message == "User tapped checkout" })
}

private struct StepFailed: Error {}

@Test func facadeTestObservabilityCapturesPassingAndFailingRuns() async throws {
    AppVitals.start()

    await AppVitals.test(named: "passing widget test", kind: .widget) {
        await AppVitals.testLog("tapped button")
    }
    let id = await AppVitals.beginTest(named: "failing integration test")
    await AppVitals.testLog("loading profile", level: .error)
    let report = try #require(await AppVitals.endTest(id, failure: "profile missing"))

    #expect(report.run.status == .failed)
    #expect(report.events.contains { $0.message == "loading profile" })
    #expect(report.events.contains { $0.message.hasPrefix("Test failed") })
    #expect(report.plainText().contains("profile missing"))

    await #expect(throws: StepFailed.self) {
        try await AppVitals.test(named: "throwing test") { throw StepFailed() }
    }
    let runs = await AppVitals.stores.testRuns.all()
    #expect(runs.first { $0.name == "passing widget test" }?.status == .passed)
    #expect(runs.first { $0.name == "throwing test" }?.status == .failed)
}
