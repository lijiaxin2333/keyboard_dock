import SwiftUI

public struct KeyboardPanelContainer<AccessoryView: View, PanelView: View>: View {
    @ObservedObject var viewModel: KeyboardPanelViewModel
    
    let accessoryView: (KeyboardPanelContext) -> AccessoryView
    let panelView: (KeyboardPanelContext, String) -> PanelView
    let contextBuilder: ((KeyboardPanelContext) -> KeyboardPanelContext)?
    
    public init(
        viewModel: KeyboardPanelViewModel,
        contextBuilder: ((KeyboardPanelContext) -> KeyboardPanelContext)? = nil,
        @ViewBuilder accessoryView: @escaping (KeyboardPanelContext) -> AccessoryView,
        @ViewBuilder panelView: @escaping (KeyboardPanelContext, String) -> PanelView
    ) {
        self.viewModel = viewModel
        self.contextBuilder = contextBuilder
        self.accessoryView = accessoryView
        self.panelView = panelView
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let bottomInset = geometry.safeAreaInsets.bottom
            let baseContext = makeBaseContext(bottomInset: bottomInset)
            let context = contextBuilder?(baseContext) ?? baseContext
            
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                
                VStack(spacing: 0) {
                    accessoryView(context)
                    panelContainer(context: context, bottomInset: bottomInset)
                }
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
    
    private func makeBaseContext(bottomInset: CGFloat) -> KeyboardPanelContext {
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
        
        switch viewModel.panelState {
        case .keyboard:
            if viewModel.keyboardHeight > 0 {
                Color.clear
                    .frame(height: max(0, viewModel.keyboardHeight - bottomInset))
            } else if viewModel.isTransitioning {
                Color.clear
                    .frame(height: displayHeight)
            }
        case .panel(let panelId):
            panelView(context, panelId)
                .frame(height: displayHeight)
        case .none:
            if bottomInset > 0 {
                Color.clear
                    .frame(height: bottomInset)
            }
        }
    }
}

extension KeyboardPanelContainer where PanelView == EmptyView {
    public init(
        viewModel: KeyboardPanelViewModel,
        contextBuilder: ((KeyboardPanelContext) -> KeyboardPanelContext)? = nil,
        @ViewBuilder accessoryView: @escaping (KeyboardPanelContext) -> AccessoryView
    ) {
        self.init(
            viewModel: viewModel,
            contextBuilder: contextBuilder,
            accessoryView: accessoryView,
            panelView: { _, _ in EmptyView() }
        )
    }
}
