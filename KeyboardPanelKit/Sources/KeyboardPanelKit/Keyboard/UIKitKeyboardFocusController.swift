import UIKit

public final class UIKitKeyboardFocusController: KeyboardFocusControlling {
    public init() {}
    
    public func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    public func activateKeyboard() {}
}
