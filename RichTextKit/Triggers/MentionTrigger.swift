import Foundation
import UIKit

extension MentionItem: SuggestionItem {
    public var displayName: String { name }
}

public struct MentionTrigger: RichTextTrigger, @unchecked Sendable {
    public let triggerCharacter: String = "@"
    public let tokenType: String = "mention"
    public let tokenFormat: String = "@{name}"
    public let tokenColor: UIColor
    
    public init(
        tokenColor: UIColor = .systemBlue
    ) {
        self.tokenColor = tokenColor
    }
}
