import SwiftUI

public struct KeyboardPanelDemoView: View {
    @StateObject private var viewModel = KeyboardPanelViewModel()
    @State private var text = ""
    @State private var messages: [String] = []
    @State private var recentEmojis: [String] = ["😊", "😂"]
    
    private let quickEmojis = ["😮", "😢", "😂", "😭", "🥰", "😍", "😊", "🥹", "😘", "😎"]
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            messageList
            
            KeyboardPanel(
                viewModel: viewModel,
                text: $text,
                panelItems: [.at, .emoji, .photo, .voice, .more],
                configuration: darkConfiguration,
                onSend: sendMessage,
                panelContent: { item in
                    panelContentView(for: item)
                },
                quickBarContent: {
                    quickEmojiBar
                }
            )
        }
        .background(Color.black)
    }
    
    private var messageList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(messages.indices, id: \.self) { index in
                    messageBubble(messages[index])
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func messageBubble(_ message: String) -> some View {
        HStack {
            Spacer()
            Text(message)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(red: 0.55, green: 0.2, blue: 0.2))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    @ViewBuilder
    private func panelContentView(for item: KeyboardPanelItem) -> some View {
        switch item.id {
        case "emoji":
            EmojiPanelView(
                recentEmojis: recentEmojis,
                onEmojiSelect: { emoji in
                    text += emoji
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
            placeholderPanel(for: item)
        }
    }
    
    private var quickEmojiBar: some View {
        ForEach(quickEmojis, id: \.self) { emoji in
            Button {
                text += emoji
            } label: {
                Text(emoji)
                    .font(.system(size: 28))
            }
        }
    }
    
    private var morePanelView: some View {
        let items = [
            ("相册", "photo"),
            ("拍摄", "camera"),
            ("位置", "location"),
            ("文件", "doc")
        ]
        
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
    
    private func placeholderPanel(for item: KeyboardPanelItem) -> some View {
        VStack {
            item.icon
                .font(.system(size: 48))
                .foregroundColor(.gray)
            Text(item.title ?? item.id)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func sendMessage() {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        messages.append(text)
        text = ""
    }
    
    private var darkConfiguration: KeyboardPanelAccessoryConfiguration {
        KeyboardPanelAccessoryConfiguration(
            placeholder: "说点什么...",
            sendButtonTitle: "发送",
            colors: .dark
        )
    }
}

public struct CustomToolbarDemoView: View {
    @StateObject private var viewModel = KeyboardPanelViewModel()
    @State private var text = ""
    @FocusState private var isInputFocused: Bool
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            KeyboardPanelContainer(
                viewModel: viewModel,
                backgroundColor: Color(white: 0.15),
                accessoryView: { context in
                    customToolbar(context: context)
                },
                quickBarView: { context in
                    if context.isKeyboardVisible || context.isPanelVisible {
                        quickBar
                    }
                },
                panelView: { context, panelId in
                    panelContent(for: panelId)
                }
            )
        }
        .background(Color.black)
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
    
    private func customToolbar(context: KeyboardPanelContext) -> some View {
        HStack(spacing: 12) {
            TextField("说点什么...", text: $text, axis: .vertical)
                .focused($isInputFocused)
                .lineLimit(1...5)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(white: 0.25))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            
            Button {
                if context.currentPanelId == "emoji" {
                    context.requestShowKeyboard()
                } else {
                    isInputFocused = false
                    context.showPanel("emoji")
                }
            } label: {
                Image(systemName: context.currentPanelId == "emoji" ? "keyboard" : "face.smiling")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
            }
            
            Button {
                if context.currentPanelId == "more" {
                    context.requestShowKeyboard()
                } else {
                    isInputFocused = false
                    context.showPanel("more")
                }
            } label: {
                Image(systemName: "plus.circle")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(white: 0.15))
    }
    
    private var quickBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(["😀", "😂", "🥰", "😎", "🤔", "👍"], id: \.self) { emoji in
                    Button {
                        text += emoji
                    } label: {
                        Text(emoji)
                            .font(.system(size: 28))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(Color(white: 0.15))
    }
    
    @ViewBuilder
    private func panelContent(for panelId: String) -> some View {
        switch panelId {
        case "emoji":
            EmojiPanelView(onEmojiSelect: { text += $0 })
        case "more":
            morePanelView
        default:
            EmptyView()
        }
    }
    
    private var morePanelView: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 20) {
            ForEach([("相册", "photo"), ("拍摄", "camera")], id: \.0) { item in
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
}
