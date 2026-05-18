import AppVitals
import SwiftUI

@main
struct AppVitalsDemoApp: App {
    init() {
        AppVitals.start()
        AppVitals.trackNetwork()
        AppVitals.enableShakeToDebug()
    }

    var body: some Scene {
        WindowGroup {
            DemoRootView()
                .appVitalsDebugOverlay(stores: AppVitals.stores)
        }
    }
}

struct DemoRootView: View {
    @State private var products: [String] = []
    @State private var isConsolePresented = false

    var body: some View {
        NavigationStack {
            List(products, id: \.self) { product in
                Text(product)
            }
            .navigationTitle("AppVitals Demo")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        isConsolePresented = true
                    } label: {
                        Label("Debug Console", systemImage: "ladybug")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Load") {
                        Task { await loadProducts() }
                    }
                }
            }
            .sheet(isPresented: $isConsolePresented) {
                AppVitalsConsoleView(stores: AppVitals.stores)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .onAppear {
                AppVitals.screen("Products")
                AppVitals.log("Products appeared", category: .navigation)
            }
        }
    }

    private func loadProducts() async {
        AppVitals.log("Loading products")
        do {
            let url = URL(string: "https://jsonplaceholder.typicode.com/posts")!
            let (data, _) = try await URLSession.shared.data(from: url)
            products = try JSONDecoder().decode([Post].self, from: data).prefix(10).map(\.title)
            AppVitals.log("Loaded \(products.count) products", category: .network)
        } catch {
            AppVitals.log(error.localizedDescription, category: .error, level: .error)
        }
    }
}

private struct Post: Decodable {
    let title: String
}
