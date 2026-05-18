import Foundation

public enum NetworkBodyFormatter {
    public static func displayString(from data: Data?, contentType: String? = nil) -> String {
        guard let data, !data.isEmpty else { return "" }
        if let string = prettyJSON(from: data, contentType: contentType) {
            return string
        }
        return String(data: data, encoding: .utf8) ?? "<\(data.count) bytes>"
    }

    private static func prettyJSON(from data: Data, contentType: String?) -> String? {
        guard isJSON(contentType: contentType) else { return nil }
        guard let object = try? JSONSerialization.jsonObject(with: data) else { return nil }
        guard let pretty = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]) else { return nil }
        return String(data: pretty, encoding: .utf8)
    }

    public static func limited(_ data: Data?, maxBytes: Int) -> Data? {
        guard let data else { return nil }
        guard maxBytes > 0 else { return nil }
        return data.count > maxBytes ? data.prefix(maxBytes) : data
    }

    private static func isJSON(contentType: String?) -> Bool {
        contentType?.localizedCaseInsensitiveContains("json") == true
    }
}
