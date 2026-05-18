import AppVitalsCore
import AppVitalsStorage
import Testing

@Test func eventStoreSearchesAndCapsEvents() async {
    let store = EventStore(limit: 2)

    await store.append(AppVitalsEvent(category: .app, level: .info, message: "Launch"))
    await store.append(AppVitalsEvent(category: .custom, level: .warning, message: "Checkout warning"))
    await store.append(AppVitalsEvent(category: .error, level: .error, message: "Payment failed"))

    let all = await store.all()
    let matches = await store.search("payment")

    #expect(all.map(\.message) == ["Checkout warning", "Payment failed"])
    #expect(matches.map(\.message) == ["Payment failed"])
}
