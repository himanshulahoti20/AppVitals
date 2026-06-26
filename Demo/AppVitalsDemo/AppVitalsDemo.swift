import AppVitals
import SwiftUI

@main
struct AppVitalsDemoApp: App {
    init() {
        AppVitals.start(.debug)
    }

    var body: some Scene {
        WindowGroup {
            DemoRootView()
                .appVitalsDebugOverlay(stores: AppVitals.stores, showFloatingBubble: true)
        }
    }
}

struct DemoRootView: View {
    @State private var products: [String] = []
    @State private var isLoadingProducts = false
    @State private var isLoadingSlowRequest = false

    var body: some View {
        NavigationStack {
            List {
                Section("AppVitals") {
                    Label("Debug preset enables network, shake, FPS, and slow request tracking.", systemImage: "checkmark.seal")
                    Label("Open the console to inspect Logs, Network, Errors, and Timeline.", systemImage: "clock.arrow.circlepath")
                }

                Section("Generate Activity") {
                    Button {
                        Task { await loadProducts() }
                    } label: {
                        Label(isLoadingProducts ? "Loading Products..." : "Load Products", systemImage: "arrow.down.circle")
                    }
                    .disabled(isLoadingProducts)

                    Button {
                        Task { await loadSlowRequest() }
                    } label: {
                        Label(isLoadingSlowRequest ? "Running Slow Request..." : "Run Slow Request", systemImage: "tortoise")
                    }
                    .disabled(isLoadingSlowRequest)

                    Button {
                        simulateFrameDrop()
                    } label: {
                        Label("Simulate Frame Drop", systemImage: "speedometer")
                    }
                }

                if !products.isEmpty {
                    Section("Products") {
                        ForEach(products, id: \.self) { product in
                            Text(product)
                        }
                    }
                }
            }
            .navigationTitle("AppVitals Demo")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        AppVitals.openConsole()
                    } label: {
                        Label("Debug Console", systemImage: "ladybug")
                    }
                }
            }
            .onAppear {
                AppVitals.screen("Products")
                AppVitals.log("Products appeared", category: .navigation)
            }
            .task {
                AppVitals.markStartupComplete()
            }
        }
    }

    private func loadProducts() async {
        guard !isLoadingProducts else { return }
        isLoadingProducts = true
        defer { isLoadingProducts = false }

        AppVitals.log("Loading products")
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/posts") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            products = try JSONDecoder().decode([Post].self, from: data).prefix(10).map(\.title)
            AppVitals.log("Loaded \(products.count) products", category: .network)
        } catch {
            AppVitals.log(error.localizedDescription, category: .error, level: .error)
        }
    }

    private func loadSlowRequest() async {
        guard !isLoadingSlowRequest else { return }
        isLoadingSlowRequest = true
        defer { isLoadingSlowRequest = false }

        AppVitals.log("Starting slow request demo", category: .performance)
        guard let url = URL(string: "https://httpbin.org/delay/4") else { return }
        do {
            _ = try await URLSession.shared.data(from: url)
            AppVitals.log("Slow request demo completed", category: .network)
        } catch {
            AppVitals.log(error.localizedDescription, category: .error, level: .error)
        }
    }

    private func simulateFrameDrop() {
        AppVitals.log("Simulating frame drop", category: .performance, level: .warning)
        let end = Date().addingTimeInterval(0.35)
        while Date() < end {
            _ = UUID().uuidString.hashValue
        }
    }
}

private struct Post: Decodable {
    let title: String
}
