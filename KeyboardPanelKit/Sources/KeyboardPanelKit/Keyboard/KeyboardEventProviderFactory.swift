import Foundation

public enum KeyboardEventProviderFactory {
    public static func createProvider() -> KeyboardEventProviding {
        UIKitKeyboardEventProvider()
    }
}
