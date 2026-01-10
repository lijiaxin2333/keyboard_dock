import Foundation
import Combine

public protocol KeyboardEventProviding: AnyObject {
    var keyboardStatePublisher: AnyPublisher<KeyboardState, Never> { get }
    var currentState: KeyboardState { get }
    var lastKnownHeight: CGFloat { get }
    func startMonitoring()
    func stopMonitoring()
}
