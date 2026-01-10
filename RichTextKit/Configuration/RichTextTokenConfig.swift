import Foundation
import SwiftUI
import UIKit

/// 业务侧可为每个 type 配置的数据构建器与 SwiftUI 视图
public struct RichTextTokenConfig {
    public typealias DataBuilder = (_ suggestion: any SuggestionItem) -> RichTextItem
    public typealias TapHandler = (_ item: RichTextItem) -> Void

    public let dataBuilder: DataBuilder
    /// 当用户点击该 token 时触发（编辑态与只读态均支持）。
    /// - Note: 若配置了该回调，会优先于 `RichTextEditorView(onTokenTap:)` 的全局回调执行。
    public let onTap: TapHandler?

    public init(
        dataBuilder: @escaping DataBuilder,
        onTap: TapHandler? = nil
    ) {
        self.dataBuilder = dataBuilder
        self.onTap = onTap
    }
}

public extension RichTextTokenConfig {
    /// 方案 A（id + payload 分离）：
    /// 业务侧使用强类型 payload（Codable），不再需要从字典里取值。
    static func typed<Payload: Codable & Sendable>(
        dataBuilder: @escaping (_ suggestion: any SuggestionItem) -> (item: RichTextItem, payload: Payload),
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder(),
        onTap: ((_ item: RichTextItem, _ payload: Payload) -> Void)? = nil
    ) -> RichTextTokenConfig {
        RichTextTokenConfig(
            dataBuilder: { suggestion in
                var (item, payload) = dataBuilder(suggestion)
                item.payload = RichTextItem.encodePayload(payload, encoder: encoder)
                return item
            },
            onTap: onTap.map { handler in
                { item in
                    guard let payload: Payload = item.decodePayload(Payload.self, decoder: decoder) else { return }
                    handler(item, payload)
                }
            }
        )
    }

    /// 业务自定义 Suggestion 类型（强类型）版本：
    /// - 业务可以定义自己的 `Suggestion: SuggestionItem`（包含 avatar/isLocked/...），并在 dataBuilder 里直接使用这些字段；
    /// - 内部仍会将 config 类型擦除成 `any SuggestionItem`，并在运行时做一次 `as? Suggestion` 的安全转换。
    ///
    /// - Parameters:
    ///   - dataBuilder: 使用强类型 Suggestion 构造 token item + 强类型 payload（payload 会自动 encode 到 item.payload）
    ///   - fallback: 当 suggestion 不是目标类型时的兜底策略（例如内置 provider 返回的是 MentionItem/TopicItem）。
    static func typed<Suggestion: SuggestionItem, Payload: Codable & Sendable>(
        suggestionType: Suggestion.Type = Suggestion.self,
        dataBuilder: @escaping (_ suggestion: Suggestion) -> (item: RichTextItem, payload: Payload),
        fallback: @escaping (_ suggestion: any SuggestionItem) -> (item: RichTextItem, payload: Payload),
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder(),
        onTap: ((_ item: RichTextItem, _ payload: Payload) -> Void)? = nil
    ) -> RichTextTokenConfig {
        _ = suggestionType
        return typed(
            dataBuilder: { anySuggestion in
                if let typedSuggestion = anySuggestion as? Suggestion {
                    return dataBuilder(typedSuggestion)
                }
                return fallback(anySuggestion)
            },
            decoder: decoder,
            encoder: encoder,
            onTap: onTap
        )
    }

    /// ✅ 推荐用法：业务不需要传 `suggestionType`，也不需要写 `fallback`。
    ///
    /// - How to use:
    ///   - 在闭包参数上显式标注类型即可：`{ (s: YourSuggestion) in ... }`
    ///   - 若运行时传入的 suggestion 类型不匹配，会触发 `assertionFailure` 并降级为纯文本（避免线上 crash）
    static func typed<Suggestion: SuggestionItem, Payload: Codable & Sendable>(
        dataBuilder: @escaping (_ suggestion: Suggestion) -> (item: RichTextItem, payload: Payload),
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder(),
        onTap: ((_ item: RichTextItem, _ payload: Payload) -> Void)? = nil
    ) -> RichTextTokenConfig {
        RichTextTokenConfig(
            dataBuilder: { anySuggestion in
                guard let typed = anySuggestion as? Suggestion else {
                    assertionFailure("RichTextTokenConfig.typed 配置错误：期望 Suggestion 为 \(Suggestion.self)，实际为 \(type(of: anySuggestion))。请确保 trigger.dataProvider 返回的候选类型与此处一致，或改用带 fallback 的 typed(...)。")
                    return RichTextItem.text(anySuggestion.displayName)
                }
                var (item, payload) = dataBuilder(typed)
                item.payload = RichTextItem.encodePayload(payload, encoder: encoder)
                return item
            },
            onTap: onTap.map { handler in
                { item in
                    guard let payload: Payload = item.decodePayload(Payload.self, decoder: decoder) else { return }
                    handler(item, payload)
                }
            }
        )
    }
}

/// SwiftUI 视图包装
public struct RichTextTokenView {
    public let view: AnyView
    public let size: CGSize?

    public init<V: View>(_ view: V, size: CGSize? = nil) {
        self.view = AnyView(
            view
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: 300, alignment: .leading)
        )
        self.size = size
    }
}
