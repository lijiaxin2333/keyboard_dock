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
        KeyboardPanelContainer(
            viewModel: viewModel,
            backgroundColor: configuration.colors.accessoryBackground,
            accessoryView: { context in
                KeyboardAccessoryView(
                    text: $text,
                    isInputFocused: $isInputFocused,
                    panelItems: panelItems,
                    context: context,
                    configuration: configuration,
                    onSend: onSend
                )
            },
            quickBarView: { _ in
                KeyboardAccessoryQuickBar(backgroundColor: configuration.colors.panelBackground) {
                    quickBarContent()
                }
            },
            panelView: { _, panelId in
                if let item = panelItems.first(where: { $0.id == panelId }) {
                    panelContent(item)
                }
            }
        )
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
