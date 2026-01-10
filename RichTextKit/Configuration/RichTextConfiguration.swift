import Foundation
import UIKit

public final class RichTextConfiguration {
    
    private var triggers: [String: RichTextTrigger] = [:]
    private var tokenConfigs: [String: RichTextTokenConfig] = [:]
    
    public init() {}
    
    public func register(_ trigger: RichTextTrigger) {
        triggers[trigger.triggerCharacter] = trigger
    }
    
    public func unregister(triggerCharacter: String) {
        triggers.removeValue(forKey: triggerCharacter)
    }
    
    public func trigger(for character: String) -> RichTextTrigger? {
        triggers[character]
    }
    
    public var allTriggers: [RichTextTrigger] {
        Array(triggers.values)
    }
    
    public var triggerCharacters: Set<String> {
        Set(triggers.keys)
    }
    
    public func isTriggerCharacter(_ character: String) -> Bool {
        triggers.keys.contains(character)
    }
    
    // MARK: - Token customization
    
    public func registerToken(type: String, config: RichTextTokenConfig) {
        tokenConfigs[type] = config
    }
    
    public func unregisterToken(type: String) {
        tokenConfigs.removeValue(forKey: type)
    }
    
    public func tokenConfig(for type: String) -> RichTextTokenConfig? {
        tokenConfigs[type]
    }
}

public extension RichTextConfiguration {
    
    // ✅ 仅保留编辑能力；候选面板/候选数据由业务外部实现与注入
}
