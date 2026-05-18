import AppVitals
import Testing

@Test func facadeLogsEvents() async throws {
    AppVitals.start()
    AppVitals.log("User tapped checkout")

    try await Task.sleep(for: .milliseconds(100))
    let events = await AppVitals.stores.events.search("checkout")

    #expect(events.contains { $0.message == "User tapped checkout" })
}
