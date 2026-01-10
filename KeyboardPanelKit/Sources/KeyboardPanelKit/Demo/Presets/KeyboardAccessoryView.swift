import SwiftUI

public struct KeyboardAccessoryView: View {
    @Binding var text: String
    @FocusState.Binding var isInputFocused: Bool
    let panelItems: [KeyboardPanelItem]
    let context: KeyboardPanelContext
    let configuration: KeyboardPanelAccessoryConfiguration
    let onSend: () -> Void
    
    public init(
        text: Binding<String>,
        isInputFocused: FocusState<Bool>.Binding,
        panelItems: [KeyboardPanelItem],
        context: KeyboardPanelContext,
        configuration: KeyboardPanelAccessoryConfiguration = .default,
        onSend: @escaping () -> Void
    ) {
        self._text = text
        self._isInputFocused = isInputFocused
        self.panelItems = panelItems
        self.context = context
        self.configuration = configuration
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
    
    @ViewBuilder
    private var inputField: some View {
        Group {
            if #available(iOS 16.0, *) {
                TextField(configuration.placeholder, text: $text, axis: .vertical)
                    .lineLimit(1...5)
            } else {
                TextField(configuration.placeholder, text: $text)
            }
        }
        .focused($isInputFocused)
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
                    handleItemTap(item)
                } label: {
                    item.icon(for: context.panelState)
                        .font(.system(size: 22))
                        .foregroundColor(configuration.colors.buttonTint)
                        .frame(width: configuration.buttonSize, height: configuration.buttonSize)
                }
            }
        }
    }
    
    private func handleItemTap(_ item: KeyboardPanelItem) {
        if context.currentPanelId == item.id {
            context.requestShowKeyboard()
        } else {
            isInputFocused = false
            context.showPanel(item.id)
        }
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
