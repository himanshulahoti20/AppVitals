import AppVitalsCore
import Foundation

public actor CrashContextStore {
    private let fileURL: URL
    private var visibleScreenName: String?

    public init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
                ?? FileManager.default.temporaryDirectory
            self.fileURL = directory.appendingPathComponent("AppVitalsCrashContext.json")
        }
    }

    public func setVisibleScreenName(_ screenName: String?) {
        visibleScreenName = screenName
    }

    public func persist(events: [AppVitalsEvent], networkTransactions: [NetworkTransaction]) throws {
        let context = CrashContext(
            visibleScreenName: visibleScreenName,
            recentEvents: events,
            recentNetworkTransactions: networkTransactions
        )
        let data = try JSONEncoder.appVitals.encode(context)
        try data.write(to: fileURL, options: [.atomic])
    }

    public func load() throws -> CrashContext? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder.appVitals.decode(CrashContext.self, from: data)
    }
}

private extension JSONEncoder {
    static var appVitals: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension JSONDecoder {
    static var appVitals: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
