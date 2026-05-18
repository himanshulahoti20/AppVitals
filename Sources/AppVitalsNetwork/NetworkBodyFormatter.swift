import Foundation

public enum NetworkBodyFormatter {
    public static func displayString(from data: Data?, contentType: String? = nil) -> String {
        guard let data, !data.isEmpty else { return "" }

        if isJSON(contentType: contentType),
           let object = try? JSONSerialization.jsonObject(with: data),
           let pretty = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
           let string = String(data: pretty, encoding: .utf8) {
            return string
        }

        return String(data: data, encoding: .utf8) ?? "<\(data.count) bytes>"
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
