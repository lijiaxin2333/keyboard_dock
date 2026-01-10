import SwiftUI

public struct EmojiCategory: Identifiable, Equatable {
    public let id: String
    public let icon: Image
    public let emojis: [String]
    
    public init(id: String, icon: Image, emojis: [String]) {
        self.id = id
        self.icon = icon
        self.emojis = emojis
    }
}

public struct EmojiPanelView: View {
    @State private var selectedCategoryId: String
    let categories: [EmojiCategory]
    let recentEmojis: [String]
    let onEmojiSelect: (String) -> Void
    let backgroundColor: Color
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 8)
    
    public init(
        categories: [EmojiCategory] = EmojiPanelView.defaultCategories,
        recentEmojis: [String] = [],
        backgroundColor: Color = Color(white: 0.15),
        onEmojiSelect: @escaping (String) -> Void = { _ in }
    ) {
        self.categories = categories
        self.recentEmojis = recentEmojis
        self.backgroundColor = backgroundColor
        self.onEmojiSelect = onEmojiSelect
        self._selectedCategoryId = State(initialValue: categories.first?.id ?? "")
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            categoryBar
            emojiGrid
        }
        .background(backgroundColor)
    }
    
    private var categoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(categories) { category in
                    Button {
                        selectedCategoryId = category.id
                    } label: {
                        category.icon
                            .font(.system(size: 24))
                            .foregroundColor(selectedCategoryId == category.id ? .white : .gray)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(white: 0.12))
    }
    
    private var emojiGrid: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !recentEmojis.isEmpty {
                    emojiSection(title: "最近使用", emojis: recentEmojis)
                }
                
                if let category = categories.first(where: { $0.id == selectedCategoryId }) {
                    emojiSection(title: category.id, emojis: category.emojis)
                }
            }
            .padding(16)
        }
    }
    
    private func emojiSection(title: String, emojis: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(emojis, id: \.self) { emoji in
                    Button {
                        onEmojiSelect(emoji)
                    } label: {
                        Text(emoji)
                            .font(.system(size: 28))
                    }
                }
            }
        }
    }
    
    public static let defaultCategories: [EmojiCategory] = [
        EmojiCategory(
            id: "小红薯表情",
            icon: Image(systemName: "face.smiling"),
            emojis: ["😀", "😃", "😄", "😁", "😆", "😅", "🤣", "😂",
                     "🙂", "🙃", "😉", "😊", "😇", "🥰", "😍", "🤩",
                     "😘", "😗", "☺️", "😚", "😙", "🥲", "😋", "😛",
                     "😜", "🤪", "😝", "🤑", "🤗", "🤭", "🤫", "🤔",
                     "🤐", "🤨", "😐", "😑", "😶", "😏", "😒", "🙄",
                     "😬", "😮‍💨", "🤥", "😌", "😔", "😪", "🤤", "😴"]
        ),
        EmojiCategory(
            id: "手势",
            icon: Image(systemName: "hand.wave"),
            emojis: ["👋", "🤚", "🖐️", "✋", "🖖", "👌", "🤌", "🤏",
                     "✌️", "🤞", "🤟", "🤘", "🤙", "👈", "👉", "👆",
                     "🖕", "👇", "☝️", "👍", "👎", "✊", "👊", "🤛",
                     "🤜", "👏", "🙌", "👐", "🤲", "🤝", "🙏", "✍️"]
        ),
        EmojiCategory(
            id: "爱心",
            icon: Image(systemName: "heart"),
            emojis: ["❤️", "🧡", "💛", "💚", "💙", "💜", "🖤", "🤍",
                     "🤎", "💔", "❣️", "💕", "💞", "💓", "💗", "💖",
                     "💘", "💝", "💟", "♥️", "💌", "💋", "👄", "🫦"]
        )
    ]
}
