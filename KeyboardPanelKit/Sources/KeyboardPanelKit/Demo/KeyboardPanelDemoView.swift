import SwiftUI

public struct KeyboardPanelDemoView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = KeyboardPanelViewModel()
    @State private var text = ""
    @State private var messages: [String] = ["欢迎使用 KeyboardPanelKit!", "这是解耦后的新版本"]
    @State private var recentEmojis: [String] = ["😊", "😂"]
    @FocusState private var isInputFocused: Bool
    
    private let quickEmojis = ["😮", "😢", "😂", "😭", "🥰", "😍", "😊", "🥹", "😘", "😎"]
    private let colors = KeyboardPanelColors.dark
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                messageList
                
                KeyboardPanelContainer(
                    viewModel: viewModel,
                    contextBuilder: { context in
                        var ctx = context
                        ctx.insertText = { self.text += $0 }
                        ctx.clearContent = { self.text = "" }
                        return ctx
                    },
                    accessoryView: { context in
                        accessoryView(context: context)
                    },
                    panelView: { context, panelId in
                        panelContent(for: panelId, context: context)
                    }
                )
            }
            
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 8)
                }
                Spacer()
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
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
    
    private func accessoryView(context: KeyboardPanelContext) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                textField
                    .focused($isInputFocused)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(colors.inputBackground)
                    .foregroundColor(colors.inputText)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                
                toolButtons(context: context)
                
                Button(action: sendMessage) {
                    Text("发送")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(colors.sendButtonForeground)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(colors.sendButtonBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(colors.accessoryBackground)
            
            if context.isKeyboardVisible || context.isPanelVisible {
                quickBar(context: context)
            }
        }
    }
    
    private func toolButtons(context: KeyboardPanelContext) -> some View {
        HStack(spacing: 12) {
            ForEach([KeyboardPanelItem.at, .emoji, .photo, .voice, .more]) { item in
                Button {
                    handleItemTap(item, context: context)
                } label: {
                    item.icon(for: context.panelState)
                        .font(.system(size: 22))
                        .foregroundColor(colors.buttonTint)
                        .frame(width: 32, height: 32)
                }
            }
        }
    }
    
    private func handleItemTap(_ item: KeyboardPanelItem, context: KeyboardPanelContext) {
        if context.currentPanelId == item.id {
            context.requestShowKeyboard()
        } else {
            isInputFocused = false
            context.showPanel(item.id)
        }
    }
    
    private func quickBar(context: KeyboardPanelContext) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(quickEmojis, id: \.self) { emoji in
                    Button {
                        context.insertText?(emoji)
                    } label: {
                        Text(emoji)
                            .font(.system(size: 28))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(colors.panelBackground)
    }
    
    @ViewBuilder
    private func panelContent(for panelId: String, context: KeyboardPanelContext) -> some View {
        Group {
            switch panelId {
            case "emoji":
                EmojiPanelView(
                    recentEmojis: recentEmojis,
                    onEmojiSelect: { emoji in
                        context.insertText?(emoji)
                        if !recentEmojis.contains(emoji) {
                            recentEmojis.insert(emoji, at: 0)
                            if recentEmojis.count > 20 {
                                recentEmojis.removeLast()
                            }
                        }
                    }
                )
            case "more":
                morePanelView
            default:
                placeholderPanel(for: panelId)
            }
        }
        .background(colors.panelBackground)
    }
    
    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(messages.indices, id: \.self) { index in
                        messageBubble(messages[index])
                            .id(index)
                    }
                }
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: messages.count) { _ in
                withAnimation {
                    proxy.scrollTo(messages.count - 1, anchor: .bottom)
                }
            }
        }
    }
    
    private func messageBubble(_ message: String) -> some View {
        HStack {
            Spacer()
            Text(message)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(colors.sendButtonBackground)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    private var morePanelView: some View {
        let items = [("相册", "photo"), ("拍摄", "camera"), ("位置", "location"), ("文件", "doc")]
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 20) {
            ForEach(items, id: \.0) { item in
                VStack(spacing: 8) {
                    Image(systemName: item.1)
                        .font(.system(size: 28))
                        .frame(width: 56, height: 56)
                        .background(Color(white: 0.25))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    Text(item.0)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(20)
        .foregroundColor(.white)
    }
    
    private func placeholderPanel(for panelId: String) -> some View {
        VStack {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            Text(panelId)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func sendMessage() {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        messages.append(text)
        text = ""
    }
    
    @ViewBuilder
    private var textField: some View {
        if #available(iOS 16.0, *) {
            TextField("说点什么...", text: $text, axis: .vertical)
                .lineLimit(1...5)
        } else {
            TextField("说点什么...", text: $text)
        }
    }
}
