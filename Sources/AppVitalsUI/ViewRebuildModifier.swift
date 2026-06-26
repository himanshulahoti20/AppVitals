import AppVitalsStorage
import SwiftUI

// MARK: - Public API

public extension View {
    /// Counts every SwiftUI body re-evaluation for this view and records it in `store`.
    /// Use `AppVitals.stores.memory` as the store, or pass any `MemoryStore` instance.
    func trackRebuilds(_ name: String, store: MemoryStore) -> some View {
        modifier(RebuildTrackingModifier(name: name, store: store))
    }
}

// MARK: - ViewModifier

public struct RebuildTrackingModifier: ViewModifier {
    let name: String
    let store: MemoryStore

    /// Reference-typed counter: mutating `count` does not change the @State value
    /// (the reference itself stays the same), so SwiftUI does not trigger another render.
    @State private var box = RebuildCounterBox()

    public func body(content: Content) -> some View {
        // nextRebuildID() is evaluated as an argument (outside the result builder's
        // expression pipeline), so the Void mutation doesn't conflict with @ViewBuilder.
        content.task(id: nextRebuildID()) {
            await store.viewRebuilt(name)
        }
    }

    private func nextRebuildID() -> Int {
        box.count += 1
        return box.count
    }
}

// MARK: - Helpers

@MainActor
private final class RebuildCounterBox {
    var count = 0
}
