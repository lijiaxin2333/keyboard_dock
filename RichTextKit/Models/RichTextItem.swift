import Foundation

public struct RichTextItem: Identifiable, Equatable, Codable {
    public let id: String
    public let type: String
    public let displayText: String
    /// 业务主键（推荐只放 id，用于回写/去重/定位）
    public let data: String
    /// 业务扩展数据（推荐放 JSON 字符串；用于自定义 token view / 点击回调等）
    public var payload: String?
    
    public init(
        id: String = UUID().uuidString,
        type: String,
        displayText: String,
        data: String,
        payload: String? = nil
    ) {
        self.id = id
        self.type = type
        self.displayText = displayText
        self.data = data
        self.payload = payload
    }
    
    public static func text(_ content: String) -> RichTextItem {
        RichTextItem(type: "text", displayText: content, data: content, payload: nil)
    }
    
    public static func mention(id: String, name: String) -> RichTextItem {
        RichTextItem(type: "mention", displayText: "@\(name)", data: id, payload: nil)
    }
    
    public static func topic(id: String, name: String) -> RichTextItem {
        RichTextItem(type: "topic", displayText: "#\(name)#", data: id, payload: nil)
    }
    
    public var isMention: Bool { type == "mention" }
    public var isTopic: Bool { type == "topic" }
    public var isText: Bool { type == "text" }
}

public extension RichTextItem {
    func decodePayload<T: Decodable>(
        _ type: T.Type,
        decoder: JSONDecoder = JSONDecoder()
    ) -> T? {
        guard let payload, let data = payload.data(using: .utf8) else { return nil }
        return try? decoder.decode(T.self, from: data)
    }
    
    static func encodePayload<T: Encodable>(
        _ value: T,
        encoder: JSONEncoder = JSONEncoder()
    ) -> String? {
        guard let data = try? encoder.encode(value) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
