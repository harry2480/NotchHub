import SwiftUI

/// Root SwiftUI content hosted inside the notch `NSPanel`. Renders the current
/// ``NotchMode`` and overlays any toast. Holds no domain state of its own.
struct NotchRootView: View {
    let viewModel: NotchViewModel

    var body: some View {
        let size = NotchLayout.size(for: viewModel.mode)
        return ZStack {
            modeContent
                .frame(width: size.width, height: size.height)

            if let toast = viewModel.toast {
                VStack {
                    Spacer()
                    ToastView(message: toast, onUndo: toast.isUndoable ? { viewModel.undoLastDrop() } : nil)
                        .padding(.bottom, NotchStyle.contentPadding)
                }
            }
        }
        .frame(width: size.width, height: size.height)
        .animation(.easeInOut(duration: NotchStyle.modeTransitionDuration), value: viewModel.mode)
        .onDrop(of: DropItemLoader.readableTypes, delegate: NotchDropDelegate(viewModel: viewModel))
    }

    @ViewBuilder
    private var modeContent: some View {
        switch viewModel.mode {
        case .collapsed:
            CollapsedNotchView(status: viewModel.minimalStatus)
        case .dragging:
            DraggingNotchView(hoveredZone: viewModel.dragSession?.hoveredZone)
        case .expanded:
            ExpandedNotchView()
        }
    }
}
