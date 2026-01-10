import Foundation

public extension MentionTrigger {
    enum PlaceholderKind: String, Sendable {
        case user
        case concept
    }

    /// 生成服务端占位符（对齐旧协议）：`@{user_<id>}` / `@{concept_<id>}`
    static func makePlaceholder(kind: PlaceholderKind, id: String) -> String {
        "@{\(kind.rawValue)_\(id)}"
    }

    /// 解析描述字符串为 `RichTextContent`（对齐旧容错规则）：
    /// - 只识别 `@{user_xxx}` / `@{concept_xxx}`（`_` 分隔）
    /// - related 缺失或找不到 name 时：按纯文本保留 `@{...}`（不生成 token）
    /// - 遇到不闭合 `}`：把剩余全部按纯文本处理
    static func decodePlaceholders(
        description: String,
        resolveName: (_ kind: PlaceholderKind, _ id: String) -> String?
    ) -> RichTextContent {
        var runs: [RichTextItem] = []
        runs.reserveCapacity(max(1, description.count / 3))

        var idx = description.startIndex
        while idx < description.endIndex {
            guard let atRange = description[idx...].range(of: "@{") else {
                let rest = String(description[idx...])
                if rest.isEmpty == false { runs.append(.text(rest)) }
                break
            }

            let prefix = String(description[idx..<atRange.lowerBound])
            if prefix.isEmpty == false { runs.append(.text(prefix)) }

            let afterAt = atRange.upperBound
            guard let endBrace = description[afterAt...].firstIndex(of: "}") else {
                let rest = String(description[atRange.lowerBound...])
                if rest.isEmpty == false { runs.append(.text(rest)) }
                idx = description.endIndex
                break
            }

            let raw = String(description[afterAt..<endBrace]) // e.g. "user_123" / "concept_456"
            if let sep = raw.firstIndex(of: "_") {
                let typeRaw = String(raw[..<sep])
                let idRaw = String(raw[raw.index(after: sep)...])
                if let kind = PlaceholderKind(rawValue: typeRaw),
                   let name = resolveName(kind, idRaw) {
                    runs.append(RichTextItem(type: "mention", displayText: "@\(name)", data: idRaw))
                } else {
                    // unknown type / related 缺失：按纯文本保留
                    runs.append(.text("@{\(raw)}"))
                }
            } else {
                // 不符合规范：按纯文本保留
                runs.append(.text("@{\(raw)}"))
            }

            idx = description.index(after: endBrace)
        }

        return RichTextContent(items: runs)
    }
}


