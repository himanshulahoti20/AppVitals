import AppVitalsCore
import AppVitalsStorage
import Foundation
import Testing

@Test func crashContextPersistsRecentState() async throws {
    let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let store = CrashContextStore(fileURL: fileURL)

    await store.setVisibleScreenName("Checkout")
    try await store.persist(
        events: [AppVitalsEvent(category: .custom, level: .info, message: "Tapped Pay")],
        networkTransactions: []
    )

    let context = try await store.load()

    #expect(context?.visibleScreenName == "Checkout")
    #expect(context?.recentEvents.first?.message == "Tapped Pay")
}
