import AppVitalsCore
import AppVitalsStorage
import SwiftUI

public extension View {
    func appVitalsDebugOverlay(
        stores: AppVitalsStores,
        isEnabled: Bool = true,
        showFloatingBubble: Bool = false
    ) -> some View {
        modifier(AppVitalsDebugOverlayModifier(
            stores: stores,
            isEnabled: isEnabled,
            showFloatingBubble: showFloatingBubble
        ))
    }
}

private struct AppVitalsDebugOverlayModifier: ViewModifier {
    let stores: AppVitalsStores
    let isEnabled: Bool
    let showFloatingBubble: Bool
    @State private var isPresented = false

    func body(content: Content) -> some View {
        let shakeEnabled = isEnabled && stores.sharedState.isShakeToDebugEnabled
        content
            .background(ShakeDetector {
                guard shakeEnabled else { return }
                isPresented = true
            })
            .overlay {
                if isEnabled, showFloatingBubble {
                    FloatingDebugBubble(isPresented: $isPresented)
                }
            }
            .sheet(isPresented: $isPresented) {
                AppVitalsConsoleView(stores: stores)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .onReceive(NotificationCenter.default.publisher(for: AppVitalsNotification.openConsole)) { _ in
                guard isEnabled else { return }
                isPresented = true
            }
    }
}

private struct FloatingDebugBubble: View {
    @Binding var isPresented: Bool
    @State private var position: CGSize = .zero
    @State private var dragStart: CGSize = .zero

    var body: some View {
        Button {
            isPresented = true
        } label: {
            Image(systemName: "ladybug.fill")
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(Color.accentColor, in: Circle())
                .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
        }
        .offset(position)
        .gesture(
            DragGesture(minimumDistance: 4)
                .onChanged { value in
                    position = CGSize(
                        width: dragStart.width + value.translation.width,
                        height: dragStart.height + value.translation.height
                    )
                }
                .onEnded { _ in
                    dragStart = position
                }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .padding(24)
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
