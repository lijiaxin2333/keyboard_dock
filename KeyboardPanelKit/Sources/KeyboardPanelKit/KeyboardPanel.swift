import SwiftUI

public struct KeyboardPanel<PanelContent: View, QuickBarContent: View>: View {
    @ObservedObject var viewModel: KeyboardPanelViewModel
    @Binding var text: String
    @FocusState private var isInputFocused: Bool
    
    let panelItems: [KeyboardPanelItem]
    let configuration: KeyboardPanelAccessoryConfiguration
    let onSend: () -> Void
    let panelContent: (KeyboardPanelItem) -> PanelContent
    let quickBarContent: () -> QuickBarContent
    
    public init(
        viewModel: KeyboardPanelViewModel,
        text: Binding<String>,
        panelItems: [KeyboardPanelItem],
        configuration: KeyboardPanelAccessoryConfiguration = .default,
        onSend: @escaping () -> Void,
        @ViewBuilder panelContent: @escaping (KeyboardPanelItem) -> PanelContent,
        @ViewBuilder quickBarContent: @escaping () -> QuickBarContent
    ) {
        self.viewModel = viewModel
        self._text = text
        self.panelItems = panelItems
        self.configuration = configuration
        self.onSend = onSend
        self.panelContent = panelContent
        self.quickBarContent = quickBarContent
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let bottomInset = geometry.safeAreaInsets.bottom
            
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                
                VStack(spacing: 0) {
                    KeyboardAccessoryView(
                        text: $text,
                        isInputFocused: $isInputFocused,
                        panelItems: panelItems,
                        currentPanelState: viewModel.panelState,
                        configuration: configuration,
                        onPanelItemTap: handlePanelItemTap,
                        onSend: onSend
                    )
                    
                    if shouldShowQuickBar {
                        KeyboardAccessoryQuickBar(backgroundColor: configuration.colors.panelBackground) {
                            quickBarContent()
                        }
                    }
                    
                    panelContainer(bottomInset: bottomInset)
                }
                .background(configuration.colors.accessoryBackground)
            }
            .onAppear {
                viewModel.bottomSafeAreaHeight = bottomInset
                viewModel.startMonitoring()
            }
            .onChange(of: geometry.safeAreaInsets.bottom) { newValue in
                viewModel.bottomSafeAreaHeight = newValue
            }
        }
        .onChange(of: isInputFocused) { focused in
            if focused && viewModel.panelState == .none {
                viewModel.showKeyboard()
            }
        }
        .onChange(of: viewModel.isTransitioning) { transitioning in
            if transitioning {
                isInputFocused = true
            }
        }
        .onDisappear {
            viewModel.stopMonitoring()
        }
    }
    
    private var shouldShowQuickBar: Bool {
        viewModel.panelState.isKeyboard || viewModel.panelState.isPanel || viewModel.isTransitioning
    }
    
    @ViewBuilder
    private func panelContainer(bottomInset: CGFloat) -> some View {
        let displayHeight = max(0, viewModel.lastKnownKeyboardHeight - bottomInset)
        
        ZStack {
            switch viewModel.panelState {
            case .keyboard:
                if viewModel.keyboardHeight > 0 {
                    Color.clear
                        .frame(height: max(0, viewModel.keyboardHeight - bottomInset))
                } else if viewModel.isTransitioning {
                    configuration.colors.panelBackground
                        .frame(height: displayHeight)
                }
            case .panel(let item):
                panelContent(item)
                    .frame(height: displayHeight)
                    .background(configuration.colors.panelBackground)
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
    
    private func handlePanelItemTap(_ item: KeyboardPanelItem) {
        if viewModel.panelState.currentPanelId == item.id {
            viewModel.requestShowKeyboard()
        } else {
            isInputFocused = false
            viewModel.showPanel(item)
        }
    }
}

extension KeyboardPanel where QuickBarContent == EmptyView {
    public init(
        viewModel: KeyboardPanelViewModel,
        text: Binding<String>,
        panelItems: [KeyboardPanelItem],
        configuration: KeyboardPanelAccessoryConfiguration = .default,
        onSend: @escaping () -> Void,
        @ViewBuilder panelContent: @escaping (KeyboardPanelItem) -> PanelContent
    ) {
        self.init(
            viewModel: viewModel,
            text: text,
            panelItems: panelItems,
            configuration: configuration,
            onSend: onSend,
            panelContent: panelContent,
            quickBarContent: { EmptyView() }
        )
    }
}
