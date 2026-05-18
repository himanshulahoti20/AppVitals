import AppVitalsCore
import AppVitalsStorage
import Foundation
import Testing

@Test func networkTransactionStoreCapsBeyondLimit() async throws {
    let store = NetworkTransactionStore(limit: 2)

    try await store.append(NetworkTransaction(request: NetworkRequestSnapshot(
        method: "GET",
        url: #require(URL(string: "https://example.com/one"))
    )))
    try await store.append(NetworkTransaction(request: NetworkRequestSnapshot(
        method: "POST",
        url: #require(URL(string: "https://example.com/two"))
    )))
    try await store.append(NetworkTransaction(request: NetworkRequestSnapshot(
        method: "GET",
        url: #require(URL(string: "https://example.com/three"))
    )))

    let all = await store.all()

    #expect(all.count == 2)
    #expect(all[0].request.url.absoluteString.contains("two"))
    #expect(all[1].request.url.absoluteString.contains("three"))
}

@Test func networkTransactionStoreSearchByURL() async throws {
    let store = NetworkTransactionStore(limit: 10)

    try await store.append(NetworkTransaction(request: NetworkRequestSnapshot(
        method: "GET",
        url: #require(URL(string: "https://example.com/products"))
    )))
    try await store.append(NetworkTransaction(
        request: NetworkRequestSnapshot(method: "POST", url: #require(URL(string: "https://example.com/login"))),
        response: NetworkResponseSnapshot(statusCode: 401)
    ))

    let urlMatches = await store.search("products")
    let statusMatches = await store.search("401")
    let noMatches = await store.search("nonexistent")

    #expect(urlMatches.count == 1)
    #expect(urlMatches[0].request.url.absoluteString.contains("products"))
    #expect(statusMatches.count == 1)
    #expect(noMatches.isEmpty)
}

@Test func networkTransactionStoreRemoveAll() async throws {
    let store = NetworkTransactionStore(limit: 5)

    try await store.append(NetworkTransaction(request: NetworkRequestSnapshot(
        method: "GET",
        url: #require(URL(string: "https://example.com"))
    )))
    await store.removeAll()

    let all = await store.all()
    #expect(all.isEmpty)
}
