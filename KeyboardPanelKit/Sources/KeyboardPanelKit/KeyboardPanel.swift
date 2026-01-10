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
            
            if viewModel.panelState.isKeyboard || viewModel.panelState.isPanel {
                KeyboardAccessoryQuickBar(backgroundColor: configuration.colors.panelBackground) {
                    quickBarContent()
                }
            }
            
            panelContainer
        }
        .onChange(of: isInputFocused) { focused in
            if focused && !viewModel.panelState.isKeyboard {
                viewModel.showKeyboard()
            }
        }
        .onAppear {
            viewModel.startMonitoring()
        }
        .onDisappear {
            viewModel.stopMonitoring()
        }
    }
    
    @ViewBuilder
    private var panelContainer: some View {
        switch viewModel.panelState {
        case .keyboard:
            Color.clear
                .frame(height: viewModel.keyboardHeight)
        case .panel(let item):
            panelContent(item)
                .frame(height: viewModel.lastKnownKeyboardHeight)
                .background(configuration.colors.panelBackground)
        case .none:
            EmptyView()
        }
    }
    
    private func handlePanelItemTap(_ item: KeyboardPanelItem) {
        if viewModel.panelState.currentPanelId == item.id {
            isInputFocused = true
            viewModel.showKeyboard()
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
