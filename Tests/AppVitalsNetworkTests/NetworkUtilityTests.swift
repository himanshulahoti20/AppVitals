import AppVitalsCore
import AppVitalsNetwork
import AppVitalsTestingSupport
import Foundation
import Testing

@Test func prettyPrintsJSONBodies() {
    let data = Data(#"{"b":2,"a":1}"#.utf8)
    let string = NetworkBodyFormatter.displayString(from: data, contentType: "application/json")

    #expect(string.contains("\"a\" : 1"))
    #expect(string.contains("\"b\" : 2"))
}

@Test func curlGeneratorEscapesRequest() throws {
    let request = try NetworkRequestSnapshot(
        method: "POST",
        url: #require(URL(string: "https://example.com/search?q=hello")),
        headers: ["Content-Type": "application/json"],
        body: Data(#"{"name":"O'Reilly"}"#.utf8)
    )

    let command = CURLGenerator.makeCommand(for: request)

    #expect(command.contains("curl"))
    #expect(command.contains("-X 'POST'"))
    #expect(command.contains("'Content-Type: application/json'"))
    #expect(command.contains("O'\\''Reilly"))
}

@Test func redactorRemovesSensitiveRequestValues() throws {
    var request = try URLRequest(url: #require(URL(string: "https://example.com/profile?token=secret&name=ana")))
    request.addValue("Bearer secret", forHTTPHeaderField: "Authorization")

    let snapshot = RequestRedactor(policy: .productionSafe).redact(request, maxBodyBytes: 100)

    #expect(snapshot?.headers["Authorization"] == "<redacted>")
    #expect(snapshot?.url.absoluteString.contains("token=%3Credacted%3E") == true)
    #expect(snapshot?.url.absoluteString.contains("name=ana") == true)
}

@Test func redactorRemovesSensitiveResponseHeaders() throws {
    let url = try #require(URL(string: "https://example.com"))
    let response = try #require(HTTPURLResponse(
        url: url,
        statusCode: 200,
        httpVersion: nil,
        headerFields: ["Set-Cookie": "session=abc123", "Content-Type": "application/json"]
    ))

    let snapshot = RequestRedactor(policy: .productionSafe).redact(response: response, body: nil, maxBodyBytes: 100)

    #expect(snapshot.headers["Set-Cookie"] == "<redacted>")
    #expect(snapshot.headers["Content-Type"] == "application/json")
    #expect(snapshot.statusCode == 200)
}

@Test func mockURLProtocolServesConfiguredResponse() async throws {
    MockURLProtocol.handler = { _ in
        let url = try #require(URL(string: "https://example.com/data"))
        let response = try #require(HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        ))
        return (response, Data(#"{"status":"ok"}"#.utf8))
    }
    defer { MockURLProtocol.handler = nil }

    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    let session = URLSession(configuration: config)

    let (data, response) = try await session.data(from: #require(URL(string: "https://example.com/data")))
    let http = response as? HTTPURLResponse

    #expect(http?.statusCode == 200)
    #expect(String(data: data, encoding: .utf8) == #"{"status":"ok"}"#)
}
