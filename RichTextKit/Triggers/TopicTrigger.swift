import Foundation
import UIKit

extension TopicItem: SuggestionItem {
    public var displayName: String { name }
}

public struct TopicTrigger: RichTextTrigger, @unchecked Sendable {
    public let triggerCharacter: String = "#"
    public let tokenType: String = "topic"
    public let tokenFormat: String = "#{name}#"
    public let tokenColor: UIColor
    
    public init(
        tokenColor: UIColor = .systemBlue
    ) {
        self.tokenColor = tokenColor
    }
}
