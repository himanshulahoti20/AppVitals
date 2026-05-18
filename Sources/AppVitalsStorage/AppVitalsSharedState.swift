/// Mutable configuration flags that the UI layer reads synchronously.
/// Written once at app startup (before any SwiftUI view renders) and read
/// on the main thread — @unchecked Sendable is safe for this access pattern.
public final class AppVitalsSharedState: @unchecked Sendable {
    public var isShakeToDebugEnabled: Bool = false
    public init() {}
}
