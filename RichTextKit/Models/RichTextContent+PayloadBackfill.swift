import Foundation

public extension RichTextContent {
    /// 通用能力：为某类 token（按 `type`）补齐缺失的 `payload`。
    /// - Use case: 服务端/草稿只回传 `type + data(id) + displayText`，业务希望 token view 渲染时能拿到更多字段（avatar/isLocked/...）。
    
    func backfillPayload(
        forType type: String,
        payloadByData: [String: String]
    ) -> RichTextContent {
        guard items.isEmpty == false else { return self }
        var changed = false
        let newItems: [RichTextItem] = items.map { item in
            guard item.type == type else { return item }
            if let payload = item.payload, payload.isEmpty == false { return item }
            guard let payload = payloadByData[item.data], payload.isEmpty == false else { return item }
            changed = true
            var newItem = item
            newItem.payload = payload
            return newItem
        }
        return changed ? RichTextContent(items: newItems) : self
    }

    /// 通用能力：为某类 token（按 `type`）补齐缺失的 `payload`（`Codable` 自动编码成 JSON 字符串）。
    func backfillPayload<Payload: Codable>(
        forType type: String,
        payloadByData: [String: Payload],
        encoder: JSONEncoder = JSONEncoder()
    ) -> RichTextContent {
        let payloadByDataJSON: [String: String] = payloadByData.compactMapValues { payload in
            RichTextItem.encodePayload(payload, encoder: encoder)
        }
        return backfillPayload(forType: type, payloadByData: payloadByDataJSON)
    }
}


