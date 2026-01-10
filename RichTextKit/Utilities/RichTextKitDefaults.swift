import Foundation
import SwiftUI
import UIKit
import Kingfisher
import Combine

public enum RichTextMentionTokenStyle {
    case textOnly
    case avatarName
}

public struct RichTextKitDefaults {
    public struct Package {
        public let configuration: RichTextConfiguration
        public let editorConfig: RichTextEditorStyle
        public let tokenViewRegistry: RichTextTokenViewRegistry
    }
    
    @MainActor
    public static func mentionTopicPackage(
        font: UIFont = .systemFont(ofSize: 16),
        textColor: UIColor = .label,
        mentionColor: UIColor = .systemBlue,
        topicColor: UIColor = .systemOrange,
        mentionStyle: RichTextMentionTokenStyle = .textOnly,
        characterLimit: RichTextKit.CharacterLimitConfig? = nil,
        keyboardAppearance: UIKeyboardAppearance = .default,
        onTokenTap: ((RichTextItem) -> Void)? = nil
    ) -> Package {
        let config = RichTextConfiguration()
        config.register(MentionTrigger(tokenColor: mentionColor))
        config.register(TopicTrigger(tokenColor: topicColor))
        
        struct MentionPayload: Codable, Sendable {
            let id: String
            let name: String
            let avatar: String?
        }
        struct TopicPayload: Codable, Sendable {
            let id: String
            let name: String
        }
        
        config.registerToken(
            type: "mention",
            config: RichTextTokenConfig.typed(
                dataBuilder: { (s: MentionItem) in
                    let payload = MentionPayload(id: s.id, name: s.name, avatar: nil)
                    let item = RichTextItem(type: "mention", displayText: "@\(s.name)", data: s.id)
                    return (item, payload)
                }
            )
        )
        
        config.registerToken(
            type: "topic",
            config: RichTextTokenConfig.typed(
                dataBuilder: { (s: TopicItem) in
                    let payload = TopicPayload(id: s.id, name: s.name)
                    let item = RichTextItem(type: "topic", displayText: "#\(s.name)#", data: s.id)
                    return (item, payload)
                }
            )
        )
        
        var registry = RichTextTokenViewRegistry()
        switch mentionStyle {
        case .textOnly:
            registry.registerTyped(type: "mention") { (_: RichTextItem, payload: MentionPayload, font: UIFont) in
                RichTextTokenView(
                    Text("@\(payload.name)")
                        .font(.system(size: font.pointSize))
                        .foregroundColor(Color(mentionColor))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                )
            }
        case .avatarName:
            registry.registerTyped(type: "mention") { (_: RichTextItem, payload: MentionPayload, font: UIFont) in
                RichTextTokenView(
                    HStack(spacing: 8) {
                        avatarView(urlString: payload.avatar, lineHeight: font.lineHeight)
                        Text(payload.name)
                            .font(.system(size: font.pointSize))
                            .foregroundColor(Color(mentionColor))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, max(0, (font.lineHeight - font.pointSize) / 2))
                    .background(Color.gray.opacity(0.15))
                    .clipShape(Capsule())
                )
            }
        }
        
        registry.registerTyped(type: "topic") { (_: RichTextItem, payload: TopicPayload, font: UIFont) in
            RichTextTokenView(
                Text("#\(payload.name)#")
                    .font(.system(size: font.pointSize))
                    .foregroundColor(Color(topicColor))
                    .padding(.horizontal, 10)
                    .padding(.vertical, max(0, (font.lineHeight - font.pointSize) / 2))
                    .background(Color.gray.opacity(0.15))
                    .clipShape(Capsule())
            )
        }
        
        let editorConfig = RichTextEditorStyle(
            placeholder: "请输入内容",
            font: font,
            textColor: textColor,
            maxHeight: nil,
            characterLimit: characterLimit,
            keyboardAppearance: keyboardAppearance,
            onTokenTap: onTokenTap
        )
        
        return Package(
            configuration: config,
            editorConfig: editorConfig,
            tokenViewRegistry: registry
        )
    }
    
    @MainActor @ViewBuilder
    public static func avatarView(urlString: String?, lineHeight: CGFloat) -> some View {
        let placeholder = Color.gray.opacity(0.2)
        if let urlString, let url = URL(string: urlString) {
            KFImage.url(url)
                .placeholder { placeholder }
                .resizable()
                .scaledToFill()
                .frame(width: lineHeight, height: lineHeight)
                .clipShape(Circle())
        } else {
            placeholder
                .frame(width: lineHeight, height: lineHeight)
                .clipShape(Circle())
        }
    }
    
    @MainActor
    public static func readOnlyView(
        content: RichTextContent,
        package: Package,
        tokenViewRegistry: RichTextTokenViewRegistry? = nil
    ) -> some View {
        let vm = RichTextEditorViewModel(configuration: package.configuration, editorConfig: package.editorConfig)
        vm.isEditable = false
        vm.setContent(content)
        return RichTextEditorView(
            viewModel: vm,
            tokenViewRegistry: tokenViewRegistry ?? package.tokenViewRegistry
        )
    }
    
    public static func decodeMentionDescription<Payload: Codable & Sendable>(
        description: String,
        nameById: [String: String],
        payloadById: [String: Payload] = [:]
    ) -> RichTextContent {
        let decoded = MentionTrigger.decodePlaceholders(description: description) { _, id in
            nameById[id]
        }
        return decoded.backfillPayload(forType: "mention", payloadByData: payloadById)
    }

    // MARK: - 轻量便捷入口
    @MainActor
    public static func makeEditor(
        isEditing: Binding<Bool>? = nil,
        insertString: Binding<String?> = .constant(nil),
        placeholder: String = "请输入内容",
        font: UIFont = .systemFont(ofSize: 16),
        textColor: UIColor = .label,
        mentionColor: UIColor = .systemBlue,
        topicColor: UIColor = .systemOrange,
        maxHeight: CGFloat? = nil,
        characterLimit: Int? = nil,
        keyboardAppearance: UIKeyboardAppearance = .default,
        onTokenTap: ((RichTextItem) -> Void)? = nil
    ) -> some View {
        let characterLimitConfig = characterLimit.map { maxCount in
            RichTextKit.CharacterLimitConfig(maxCount: maxCount, onExceeded: { _ in })
        }
        let pkg = mentionTopicPackage(
            font: font,
            textColor: textColor,
            mentionColor: mentionColor,
            topicColor: topicColor,
            mentionStyle: .textOnly,
            characterLimit: characterLimitConfig,
            keyboardAppearance: keyboardAppearance,
            onTokenTap: onTokenTap
        )
        let vm = RichTextEditorViewModel(configuration: pkg.configuration, editorConfig: pkg.editorConfig)
        return RichTextEditorView(
            viewModel: vm,
            isEditing: isEditing,
            insertString: insertString,
            tokenViewRegistry: pkg.tokenViewRegistry
        )
    }
}
