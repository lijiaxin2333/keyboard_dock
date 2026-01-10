import SwiftUI
import KeyboardPanelKit

struct ContentView: View {
    @StateObject private var viewModel = KeyboardPanelViewModel()
    @State private var text = ""
    @State private var messages: [String] = ["欢迎使用 KeyboardPanelKit!", "点击输入框弹出键盘", "点击表情按钮切换表情面板"]
    @State private var recentEmojis: [String] = ["😊", "😂"]
    @FocusState private var isInputFocused: Bool
    
    private let quickEmojis = ["😮", "😢", "😂", "😭", "🥰", "😍", "😊", "🥹", "😘", "😎"]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                messageList
                
                KeyboardPanelContainer(
                    viewModel: viewModel,
                    backgroundColor: Color(white: 0.15),
                    accessoryView: { context in
                        customToolbar(context: context)
                    },
                    quickBarView: { context in
                        if context.isKeyboardVisible || context.isPanelVisible {
                            quickEmojiBar
                        }
                    },
                    panelView: { context, panelId in
                        panelContentView(for: panelId)
                    }
                )
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
            
            toolButton(context: context, panelId: "at", icon: "at")
            toolButton(context: context, panelId: "emoji", icon: "face.smiling", selectedIcon: "keyboard")
            toolButton(context: context, panelId: "photo", icon: "photo")
            toolButton(context: context, panelId: "voice", icon: "mic")
            toolButton(context: context, panelId: "more", icon: "plus.circle")
            
            Button(action: sendMessage) {
                Text("发送")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(red: 0.55, green: 0.2, blue: 0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(white: 0.15))
    }
    
    private func toolButton(context: KeyboardPanelContext, panelId: String, icon: String, selectedIcon: String? = nil) -> some View {
        Button {
            if context.currentPanelId == panelId {
                context.requestShowKeyboard()
            } else {
                isInputFocused = false
                context.showPanel(panelId)
            }
        } label: {
            let isSelected = context.currentPanelId == panelId
            Image(systemName: isSelected && selectedIcon != nil ? selectedIcon! : icon)
                .font(.system(size: 22))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
        }
    }
    
    private var quickEmojiBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(quickEmojis, id: \.self) { emoji in
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
    private func panelContentView(for panelId: String) -> some View {
        switch panelId {
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
            placeholderPanel(for: panelId)
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
}

#Preview {
    ContentView()
}
