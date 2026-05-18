import AppVitalsCore
import AppVitalsStorage
import Foundation

public final class AppVitalsURLProtocol: URLProtocol, @unchecked Sendable {
    private static let handledKey = "AppVitalsURLProtocolHandled"
    private static let state = URLProtocolState()
    /// One session shared across all intercepts — avoids the overhead of creating
    /// a new URLSession per request and exhausting file descriptors under load.
    private static let forwardingSession: URLSession = {
        let config = URLSessionConfiguration.default
        // Do NOT register our URLProtocol here — the handledKey property on
        // forwarded requests is the recursion guard, but a clean config is safer.
        config.protocolClasses = config.protocolClasses?.filter { $0 != AppVitalsURLProtocol.self }
        return URLSession(configuration: config)
    }()

    private var dataTask: URLSessionDataTask?
    private var response: HTTPURLResponse?
    private var responseBody = Data()
    private var startedAt = Date()
    private var requestSnapshot: NetworkRequestSnapshot?

    public static func configure(store: NetworkTransactionStore, configuration: AppVitalsConfiguration) {
        Task {
            await state.configure(store: store, configuration: configuration)
        }
    }

    override public class func canInit(with request: URLRequest) -> Bool {
        guard URLProtocol.property(forKey: handledKey, in: request) == nil else { return false }
        return request.url?.scheme?.hasPrefix("http") == true
    }

    override public class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override public func startLoading() {
        startedAt = Date()

        Task {
            let snapshot = await Self.state.snapshot(for: request)
            await MainActor.run {
                self.requestSnapshot = snapshot
                self.startTask()
            }
        }
    }

    override public func stopLoading() {
        dataTask?.cancel()
        dataTask = nil
    }

    private func startTask() {
        let mutableRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest
        guard let mutableRequest else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        URLProtocol.setProperty(true, forKey: Self.handledKey, in: mutableRequest)
        dataTask = Self.forwardingSession.dataTask(with: mutableRequest as URLRequest) { [weak self] data, response, error in
            guard let self else { return }
            if let response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            if let data {
                responseBody.append(data)
                client?.urlProtocol(self, didLoad: data)
            }
            if let error {
                client?.urlProtocol(self, didFailWithError: error)
            } else {
                client?.urlProtocolDidFinishLoading(self)
            }
            finish(response: response, error: error)
        }
        dataTask?.resume()
    }

    private func finish(response: URLResponse?, error: Error?) {
        let completedAt = Date()
        let requestSnapshot = requestSnapshot
        let httpResponse = response as? HTTPURLResponse
        let statusCode = httpResponse?.statusCode
        let headers = httpResponse?.allHeaderFields.reduce(into: [String: String]()) { result, pair in
            if let key = pair.key as? String {
                result[key] = "\(pair.value)"
            }
        }
        let responseBody = Data(responseBody)
        let startedAt = startedAt
        let payload = URLProtocolCompletionPayload(
            request: requestSnapshot,
            statusCode: statusCode,
            headers: headers,
            body: responseBody,
            startedAt: startedAt,
            completedAt: completedAt,
            errorDescription: error?.localizedDescription
        )
        let state = Self.state
        Task.detached { @Sendable [payload, state] in
            await state.record(
                request: payload.request,
                statusCode: payload.statusCode,
                headers: payload.headers,
                body: payload.body,
                startedAt: payload.startedAt,
                completedAt: payload.completedAt,
                errorDescription: payload.errorDescription
            )
        }
    }
}

private struct URLProtocolCompletionPayload {
    var request: NetworkRequestSnapshot?
    var statusCode: Int?
    var headers: [String: String]?
    var body: Data
    var startedAt: Date
    var completedAt: Date
    var errorDescription: String?
}

private actor URLProtocolState {
    private var store: NetworkTransactionStore?
    private var configuration: AppVitalsConfiguration = .production

    func configure(store: NetworkTransactionStore, configuration: AppVitalsConfiguration) {
        self.store = store
        self.configuration = configuration
    }

    func snapshot(for request: URLRequest) -> NetworkRequestSnapshot? {
        guard configuration.isEnabled, configuration.isNetworkTrackingEnabled else { return nil }
        return RequestRedactor(policy: configuration.redactionPolicy)
            .redact(request, maxBodyBytes: configuration.limits.maxBodyBytes)
    }

    func record(
        request: NetworkRequestSnapshot?,
        statusCode: Int?,
        headers: [String: String]?,
        body: Data,
        startedAt: Date,
        completedAt: Date,
        errorDescription: String?
    ) async {
        guard let store, let request else { return }
        let responseSnapshot = statusCode.map {
            NetworkResponseSnapshot(
                statusCode: $0,
                headers: redactHeaders(headers ?? [:], policy: configuration.redactionPolicy),
                body: NetworkBodyFormatter.limited(body, maxBytes: configuration.limits.maxBodyBytes)
            )
        }
        await store.append(NetworkTransaction(
            startedAt: startedAt,
            completedAt: completedAt,
            request: request,
            response: responseSnapshot,
            errorDescription: errorDescription
        ))
    }

    private func redactHeaders(_ headers: [String: String], policy: RedactionPolicy) -> [String: String] {
        headers.reduce(into: [:]) { result, pair in
            result[pair.key] = policy.redactedHeaderNames.contains(pair.key.lowercased()) ? "<redacted>" : pair.value
        }
    }
}
