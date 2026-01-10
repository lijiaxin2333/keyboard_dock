import Foundation

public enum KeyboardFocusControllerFactory {
    public static func createController() -> KeyboardFocusControlling {
        UIKitKeyboardFocusController()
    }
}
