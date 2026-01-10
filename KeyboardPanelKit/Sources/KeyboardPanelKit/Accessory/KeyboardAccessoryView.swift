import SwiftUI

public struct KeyboardAccessoryView: View {
    @Binding var text: String
    @FocusState.Binding var isInputFocused: Bool
    let panelItems: [KeyboardPanelItem]
    let currentPanelState: KeyboardPanelState
    let configuration: KeyboardPanelAccessoryConfiguration
    let onPanelItemTap: (KeyboardPanelItem) -> Void
    let onSend: () -> Void
    
    public init(
        text: Binding<String>,
        isInputFocused: FocusState<Bool>.Binding,
        panelItems: [KeyboardPanelItem],
        currentPanelState: KeyboardPanelState,
        configuration: KeyboardPanelAccessoryConfiguration = .default,
        onPanelItemTap: @escaping (KeyboardPanelItem) -> Void,
        onSend: @escaping () -> Void
    ) {
        self._text = text
        self._isInputFocused = isInputFocused
        self.panelItems = panelItems
        self.currentPanelState = currentPanelState
        self.configuration = configuration
        self.onPanelItemTap = onPanelItemTap
        self.onSend = onSend
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            inputRow
        }
        .background(configuration.colors.accessoryBackground)
    }
    
    private var inputRow: some View {
        HStack(spacing: configuration.spacing) {
            inputField
            toolButtons
            sendButton
        }
        .padding(.horizontal, configuration.horizontalPadding)
        .padding(.vertical, configuration.verticalPadding)
    }
    
    private var inputField: some View {
        TextField(configuration.placeholder, text: $text, axis: .vertical)
            .focused($isInputFocused)
            .lineLimit(1...5)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(configuration.colors.inputBackground)
            .foregroundColor(configuration.colors.inputText)
            .clipShape(RoundedRectangle(cornerRadius: configuration.inputCornerRadius))
    }
    
    private var toolButtons: some View {
        HStack(spacing: configuration.spacing) {
            ForEach(panelItems) { item in
                Button {
                    onPanelItemTap(item)
                } label: {
                    itemIcon(for: item)
                        .font(.system(size: 22))
                        .foregroundColor(configuration.colors.buttonTint)
                        .frame(width: configuration.buttonSize, height: configuration.buttonSize)
                }
            }
        }
    }
    
    private func itemIcon(for item: KeyboardPanelItem) -> Image {
        if currentPanelState.currentPanelId == item.id,
           let selectedIcon = item.selectedIcon {
            return selectedIcon
        }
        return item.icon
    }
    
    private var sendButton: some View {
        Button(action: onSend) {
            Text(configuration.sendButtonTitle)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(configuration.colors.sendButtonForeground)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(configuration.colors.sendButtonBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

public struct KeyboardAccessoryQuickBar<Content: View>: View {
    let content: Content
    let backgroundColor: Color
    
    public init(
        backgroundColor: Color = Color(uiColor: .systemGray6),
        @ViewBuilder content: () -> Content
    ) {
        self.backgroundColor = backgroundColor
        self.content = content()
    }
    
    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                content
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(backgroundColor)
    }
}
