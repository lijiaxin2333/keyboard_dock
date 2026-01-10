import UIKit
import Combine

public final class UIKitKeyboardEventProvider: KeyboardEventProviding {
    private let stateSubject = CurrentValueSubject<KeyboardState, Never>(.hidden)
    private var _lastKnownHeight: CGFloat = 0
    
    public var keyboardStatePublisher: AnyPublisher<KeyboardState, Never> {
        stateSubject.eraseToAnyPublisher()
    }
    
    public var currentState: KeyboardState {
        stateSubject.value
    }
    
    public var lastKnownHeight: CGFloat {
        _lastKnownHeight > 0 ? _lastKnownHeight : 336
    }
    
    public init() {}
    
    public func startMonitoring() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardDidShow(_:)),
            name: UIResponder.keyboardDidShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardDidHide(_:)),
            name: UIResponder.keyboardDidHideNotification,
            object: nil
        )
    }
    
    public func stopMonitoring() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        let info = extractKeyboardInfo(from: notification)
        _lastKnownHeight = info.height
        stateSubject.send(.showing(info))
    }
    
    @objc private func keyboardDidShow(_ notification: Notification) {
        let info = extractKeyboardInfo(from: notification)
        _lastKnownHeight = info.height
        stateSubject.send(.shown(info))
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        let info = extractKeyboardInfo(from: notification)
        stateSubject.send(.hiding(info))
    }
    
    @objc private func keyboardDidHide(_ notification: Notification) {
        stateSubject.send(.hidden)
    }
    
    private func extractKeyboardInfo(from notification: Notification) -> KeyboardInfo {
        let userInfo = notification.userInfo
        let endFrame = (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
        let duration = (userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.25
        let curve = (userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue ?? 7
        
        return KeyboardInfo(
            height: endFrame.height,
            animationDuration: duration,
            animationCurve: curve
        )
    }
    
    deinit {
        stopMonitoring()
    }
}
