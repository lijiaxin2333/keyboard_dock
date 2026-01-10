import Foundation
import UIKit

public protocol SuggestionItem: Identifiable, Equatable, Sendable {
    var id: String { get }
    var displayName: String { get }
}

public protocol RichTextTrigger: Sendable {
    var triggerCharacter: String { get }
    var tokenType: String { get }
    var tokenFormat: String { get }
    var tokenColor: UIColor { get }
    var tokenFont: UIFont? { get }
    
    func formatTokenText(item: any SuggestionItem) -> String
}

public extension RichTextTrigger {
    var tokenFont: UIFont? { nil }

    func formatTokenText(item: any SuggestionItem) -> String {
        tokenFormat.replacingOccurrences(of: "{name}", with: item.displayName)
    }
}
