import Foundation

public protocol KeyboardFocusControlling: AnyObject {
    func dismissKeyboard()
    func activateKeyboard()
}
