import Foundation

public struct MentionItem: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    
    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

public struct TopicItem: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let count: Int
    
    public init(id: String, name: String, count: Int = 0) {
        self.id = id
        self.name = name
        self.count = count
    }
}


