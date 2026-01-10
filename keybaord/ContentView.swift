import SwiftUI
import KeyboardPanelKit

struct ContentView: View {
    @StateObject private var viewModel = KeyboardPanelViewModel()
    @State private var text = ""
    @State private var messages: [String] = ["欢迎使用 KeyboardPanelKit!", "点击输入框弹出键盘", "点击表情按钮切换表情面板"]
    @State private var recentEmojis: [String] = ["😊", "😂"]
    
    private let quickEmojis = ["😮", "😢", "😂", "😭", "🥰", "😍", "😊", "🥹", "😘", "😎"]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
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
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
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

#Preview {
    ContentView()
}
