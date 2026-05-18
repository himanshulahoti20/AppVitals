import AppVitalsCore
import Foundation

public enum CURLGenerator {
    public static func makeCommand(for request: NetworkRequestSnapshot) -> String {
        var components = ["curl"]
        components.append("-X \(shellEscape(request.method))")

        for header in request.headers.sorted(by: { $0.key < $1.key }) {
            components.append("-H \(shellEscape("\(header.key): \(header.value)"))")
        }

        if let body = request.body, !body.isEmpty {
            let bodyString = String(data: body, encoding: .utf8) ?? body.base64EncodedString()
            components.append("--data-raw \(shellEscape(bodyString))")
        }

        components.append(shellEscape(request.url.absoluteString))
        return components.joined(separator: " ")
    }

    private static func shellEscape(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }
}
