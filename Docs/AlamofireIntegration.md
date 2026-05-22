# Alamofire Integration

AppVitals captures network traffic through URLProtocol, which intercepts requests made by the system's URLSession. Alamofire uses its own `Session` object backed by a custom `URLSessionConfiguration`, so a small amount of setup is required to capture its traffic.

## Option 1 — Inject the URLProtocol into Alamofire's session (recommended)

Use `NetworkTracking.sessionConfiguration()` to build a configuration that includes AppVitals' interceptor, then pass it to your Alamofire `Session`:

```swift
import Alamofire
import AppVitals

extension Session {
    static let monitored: Session = {
        let config = NetworkTracking.sessionConfiguration()
        return Session(configuration: config)
    }()
}
```

Use `Session.monitored` instead of `AF` for all requests you want to capture:

```swift
Session.monitored.request("https://api.example.com/data").responseDecodable(of: MyModel.self) { response in
    ...
}
```

Enable network tracking before making requests:

```swift
AppVitals.start(.current)
AppVitals.trackNetwork()
```

---

## Option 2 — Alamofire EventMonitor

Alamofire's `EventMonitor` protocol gives per-request callbacks. Use this when you need richer breadcrumbs or want to forward Alamofire-specific data (task metrics, retry counts) to AppVitals.

```swift
import Alamofire
import AppVitals

final class AppVitalsEventMonitor: EventMonitor {

    func request(_ request: Request, didCompleteTask task: URLSessionTask, with error: AFError?) {
        guard let httpResponse = task.response as? HTTPURLResponse else { return }
        let statusCode = httpResponse.statusCode
        let url = task.originalRequest?.url?.absoluteString ?? "unknown"

        if let error {
            AppVitals.log(
                "Request failed: \(url) — \(error.localizedDescription)",
                category: .network,
                level: .error,
                metadata: ["url": url, "status": "\(statusCode)"]
            )
        }
    }

    func requestDidFinish(_ request: Request) {
        let url = request.request?.url?.absoluteString ?? "unknown"
        AppVitals.log(
            "Request finished: \(url)",
            category: .network,
            level: .debug,
            metadata: ["url": url]
        )
    }
}
```

Register the monitor when creating your `Session`:

```swift
let session = Session(eventMonitors: [AppVitalsEventMonitor()])
```

---

## Using both options together

Option 1 captures full request/response bodies and appears in the **Network** tab. Option 2 adds breadcrumbs to the **Logs** tab. They complement each other:

```swift
let config = NetworkTracking.sessionConfiguration()
let session = Session(
    configuration: config,
    eventMonitors: [AppVitalsEventMonitor()]
)
```
