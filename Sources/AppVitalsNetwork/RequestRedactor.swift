import AppVitalsCore
import Foundation

public struct RequestRedactor: Sendable {
    private let policy: RedactionPolicy

    public init(policy: RedactionPolicy) {
        self.policy = policy
    }

    public func redact(_ request: URLRequest, maxBodyBytes: Int) -> NetworkRequestSnapshot? {
        guard let originalURL = request.url else { return nil }
        let url = redactURL(originalURL)
        let headers = redactHeaders(request.allHTTPHeaderFields ?? [:])
        return NetworkRequestSnapshot(
            method: request.httpMethod ?? "GET",
            url: url,
            headers: headers,
            body: NetworkBodyFormatter.limited(request.httpBody, maxBytes: maxBodyBytes)
        )
    }

    public func redact(response: HTTPURLResponse, body: Data?, maxBodyBytes: Int) -> NetworkResponseSnapshot {
        NetworkResponseSnapshot(
            statusCode: response.statusCode,
            headers: redactHeaders(response.allHeaderFields.reduce(into: [:]) { result, pair in
                if let key = pair.key as? String {
                    result[key] = "\(pair.value)"
                }
            }),
            body: NetworkBodyFormatter.limited(body, maxBytes: maxBodyBytes)
        )
    }

    private func redactHeaders(_ headers: [String: String]) -> [String: String] {
        headers.reduce(into: [:]) { result, pair in
            result[pair.key] = policy.redactedHeaderNames.contains(pair.key.lowercased()) ? "<redacted>" : pair.value
        }
    }

    private func redactURL(_ url: URL) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let items = components.queryItems
        else {
            return url
        }

        components.queryItems = items.map { item in
            policy.redactedQueryItemNames.contains(item.name.lowercased())
                ? URLQueryItem(name: item.name, value: "<redacted>")
                : item
        }
        return components.url ?? url
    }
}
