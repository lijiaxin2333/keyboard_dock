import SwiftUI

public struct KeyboardPanelContainer<
    AccessoryView: View,
    QuickBarView: View,
    PanelView: View
>: View {
    @ObservedObject var viewModel: KeyboardPanelViewModel
    
    let backgroundColor: Color
    let accessoryView: (KeyboardPanelContext) -> AccessoryView
    let quickBarView: (KeyboardPanelContext) -> QuickBarView
    let panelView: (KeyboardPanelContext, String) -> PanelView
    
    public init(
        viewModel: KeyboardPanelViewModel,
        backgroundColor: Color = Color(uiColor: .systemGray6),
        @ViewBuilder accessoryView: @escaping (KeyboardPanelContext) -> AccessoryView,
        @ViewBuilder quickBarView: @escaping (KeyboardPanelContext) -> QuickBarView,
        @ViewBuilder panelView: @escaping (KeyboardPanelContext, String) -> PanelView
    ) {
        self.viewModel = viewModel
        self.backgroundColor = backgroundColor
        self.accessoryView = accessoryView
        self.quickBarView = quickBarView
        self.panelView = panelView
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let bottomInset = geometry.safeAreaInsets.bottom
            let context = makeContext(bottomInset: bottomInset)
            
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                
                VStack(spacing: 0) {
                    accessoryView(context)
                    
                    if shouldShowQuickBar {
                        quickBarView(context)
                    }
                    
                    panelContainer(context: context, bottomInset: bottomInset)
                }
                .background(backgroundColor)
            }
            .environment(\.keyboardPanelContext, context)
            .onAppear {
                viewModel.bottomSafeAreaHeight = bottomInset
                viewModel.startMonitoring()
            }
            .onChange(of: geometry.safeAreaInsets.bottom) { newValue in
                viewModel.bottomSafeAreaHeight = newValue
            }
        }
        .onDisappear {
            viewModel.stopMonitoring()
        }
    }
    
    private var shouldShowQuickBar: Bool {
        viewModel.panelState.isKeyboard || viewModel.panelState.isPanel || viewModel.isTransitioning
    }
    
    private func makeContext(bottomInset: CGFloat) -> KeyboardPanelContext {
        KeyboardPanelContext(
            panelState: viewModel.panelState,
            keyboardHeight: viewModel.keyboardHeight,
            panelDisplayHeight: max(0, viewModel.lastKnownKeyboardHeight - bottomInset),
            isTransitioning: viewModel.isTransitioning,
            bottomSafeAreaHeight: bottomInset,
            showPanel: { panelId in
                viewModel.showPanel(panelId)
            },
            showKeyboard: {
                viewModel.showKeyboard()
            },
            requestShowKeyboard: {
                viewModel.requestShowKeyboard()
            },
            dismiss: {
                viewModel.dismiss()
            }
        )
    }
    
    @ViewBuilder
    private func panelContainer(context: KeyboardPanelContext, bottomInset: CGFloat) -> some View {
        let displayHeight = context.panelDisplayHeight
        
        ZStack {
            switch viewModel.panelState {
            case .keyboard:
                if viewModel.keyboardHeight > 0 {
                    Color.clear
                        .frame(height: max(0, viewModel.keyboardHeight - bottomInset))
                } else if viewModel.isTransitioning {
                    backgroundColor
                        .frame(height: displayHeight)
                }
            case .panel(let panelId):
                panelView(context, panelId)
                    .frame(height: displayHeight)
                    .background(backgroundColor)
                    .transition(.identity)
            case .none:
                if bottomInset > 0 {
                    Color.clear
                        .frame(height: bottomInset)
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.panelState)
    }
}

extension KeyboardPanelContainer where QuickBarView == EmptyView {
    public init(
        viewModel: KeyboardPanelViewModel,
        backgroundColor: Color = Color(uiColor: .systemGray6),
        @ViewBuilder accessoryView: @escaping (KeyboardPanelContext) -> AccessoryView,
        @ViewBuilder panelView: @escaping (KeyboardPanelContext, String) -> PanelView
    ) {
        self.init(
            viewModel: viewModel,
            backgroundColor: backgroundColor,
            accessoryView: accessoryView,
            quickBarView: { _ in EmptyView() },
            panelView: panelView
        )
    }
}

extension KeyboardPanelContainer where QuickBarView == EmptyView, PanelView == EmptyView {
    public init(
        viewModel: KeyboardPanelViewModel,
        backgroundColor: Color = Color(uiColor: .systemGray6),
        @ViewBuilder accessoryView: @escaping (KeyboardPanelContext) -> AccessoryView
    ) {
        self.init(
            viewModel: viewModel,
            backgroundColor: backgroundColor,
            accessoryView: accessoryView,
            quickBarView: { _ in EmptyView() },
            panelView: { _, _ in EmptyView() }
        )
    }
}
