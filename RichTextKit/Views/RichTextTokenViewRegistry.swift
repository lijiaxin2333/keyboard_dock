import Foundation
import UIKit

/// View 层 token 渲染注册表（不放在 RichTextConfiguration 里，避免把 SwiftUI ViewBuilder 耦合进“数据配置”）。
/// - 业务通过 RichTextEditorView 参数注入
public struct RichTextTokenViewRegistry {
    private var providers: [String: _AnyTokenViewProvider] = [:]

    public init() {}

    public func view(for item: RichTextItem, font: UIFont) -> RichTextTokenView? {
        providers[item.type]?.view(for: item, font: font)
    }

    public mutating func register(type: String, provider: _AnyTokenViewProvider) {
        providers[type] = provider
    }

    /// 注册带强类型 payload 解码的 token view provider（适合多 type 场景逐个注册）。
    public mutating func registerTyped<Payload: Codable & Sendable>(
        type: String,
        decoder: JSONDecoder = JSONDecoder(),
        viewBuilder: @escaping (_ item: RichTextItem, _ payload: Payload, _ font: UIFont) -> RichTextTokenView?
    ) {
        register(
            type: type,
            provider: _AnyTokenViewProvider(
                view: { item, font in
                    guard let payload: Payload = item.decodePayload(Payload.self, decoder: decoder) else {
                        return nil
                    }
                    return viewBuilder(item, payload, font)
                }
            )
        )
    }

    // MARK: - Convenience

    public static func typed<Payload: Codable & Sendable>(
        type: String,
        decoder: JSONDecoder = JSONDecoder(),
        viewBuilder: @escaping (_ item: RichTextItem, _ payload: Payload, _ font: UIFont) -> RichTextTokenView?
    ) -> RichTextTokenViewRegistry {
        var registry = RichTextTokenViewRegistry()
        registry.register(
            type: type,
            provider: _AnyTokenViewProvider(
                view: { item, font in
                    if let payload: Payload = item.decodePayload(Payload.self, decoder: decoder) {
                        return viewBuilder(item, payload, font)
                    }
                    return nil
                }
            )
        )
        return registry
    }
}

public struct _AnyTokenViewProvider {
    private let _view: (_ item: RichTextItem, _ font: UIFont) -> RichTextTokenView?

    public init(view: @escaping (_ item: RichTextItem, _ font: UIFont) -> RichTextTokenView?) {
        self._view = view
    }

    public func view(for item: RichTextItem, font: UIFont) -> RichTextTokenView? {
        _view(item, font)
    }
}
