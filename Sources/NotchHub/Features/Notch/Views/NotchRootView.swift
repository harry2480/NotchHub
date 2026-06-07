import SwiftUI

/// Root SwiftUI content hosted inside the notch `NSPanel`. Renders the current
/// ``NotchMode`` and overlays any toast. Holds no domain state of its own.
struct NotchRootView: View {
    let scene: NotchScene

    private var viewModel: NotchViewModel {
        scene.notch
    }

    var body: some View {
        let size = NotchGeometry.size(for: viewModel.mode, on: viewModel.currentScreen)
        return ZStack {
            modeContent
                .frame(width: size.width, height: size.height)

            if let toast = viewModel.toast {
                VStack {
                    Spacer()
                    ToastView(message: toast, onUndo: toast.isUndoable ? { viewModel.undoLastDrop() } : nil)
                        .padding(.bottom, NotchStyle.contentPadding)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(width: size.width, height: size.height)
        .animation(NotchStyle.modeTransition, value: viewModel.mode)
        .animation(NotchStyle.modeTransition, value: viewModel.toast)
    }

    @ViewBuilder
    private var modeContent: some View {
        switch viewModel.mode {
        case .collapsed:
            CollapsedNotchView(status: viewModel.minimalStatus) { viewModel.click() }
        case .dragging:
            DraggingNotchView(hoveredZone: viewModel.dragSession?.hoveredZone)
        case .expanded:
            ExpandedNotchView(scene: scene)
        }
    }
}
