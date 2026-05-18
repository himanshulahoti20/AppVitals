import AppVitalsStorage
import SwiftUI

public extension View {
    func appVitalsDebugOverlay(stores: AppVitalsStores, isEnabled: Bool = true) -> some View {
        modifier(AppVitalsDebugOverlayModifier(stores: stores, isEnabled: isEnabled))
    }
}

private struct AppVitalsDebugOverlayModifier: ViewModifier {
    let stores: AppVitalsStores
    let isEnabled: Bool
    @State private var isPresented = false

    func body(content: Content) -> some View {
        let shakeEnabled = isEnabled && stores.sharedState.isShakeToDebugEnabled
        content
            .background(ShakeDetector {
                guard shakeEnabled else { return }
                isPresented = true
            })
            .sheet(isPresented: $isPresented) {
                AppVitalsConsoleView(stores: stores)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
    }
}

#if canImport(UIKit)
    import UIKit

    private struct ShakeDetector: UIViewControllerRepresentable {
        let onShake: () -> Void

        func makeUIViewController(context: Context) -> ShakeViewController {
            let controller = ShakeViewController()
            controller.onShake = onShake
            return controller
        }

        func updateUIViewController(_ uiViewController: ShakeViewController, context: Context) {
            uiViewController.onShake = onShake
        }
    }

    private final class ShakeViewController: UIViewController {
        var onShake: (() -> Void)?

        override var canBecomeFirstResponder: Bool {
            true
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            becomeFirstResponder()
        }

        override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
            guard motion == .motionShake else { return }
            onShake?()
        }
    }
#else
    private struct ShakeDetector: View {
        let onShake: () -> Void

        var body: some View {
            Color.clear
        }
    }
#endif
