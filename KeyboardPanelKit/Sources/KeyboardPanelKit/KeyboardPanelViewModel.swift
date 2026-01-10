import SwiftUI
import Combine

@MainActor
public final class KeyboardPanelViewModel: ObservableObject {
    @Published public var panelState: KeyboardPanelState = .none
    @Published public var keyboardHeight: CGFloat = 0
    @Published public private(set) var lastKnownKeyboardHeight: CGFloat = 336
    @Published public var isKeyboardVisible: Bool = false
    
    private let keyboardEventProvider: KeyboardEventProviding
    private let focusController: KeyboardFocusControlling
    private var cancellables = Set<AnyCancellable>()
    
    public var currentPanelHeight: CGFloat {
        switch panelState {
        case .keyboard:
            return keyboardHeight
        case .panel:
            return lastKnownKeyboardHeight
        case .none:
            return 0
        }
    }
    
    public var animationDuration: TimeInterval {
        0.25
    }
    
    public init(
        keyboardEventProvider: KeyboardEventProviding? = nil,
        focusController: KeyboardFocusControlling? = nil
    ) {
        self.keyboardEventProvider = keyboardEventProvider ?? KeyboardEventProviderFactory.createProvider()
        self.focusController = focusController ?? KeyboardFocusControllerFactory.createController()
        setupBindings()
    }
    
    private func setupBindings() {
        keyboardEventProvider.keyboardStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleKeyboardState(state)
            }
            .store(in: &cancellables)
    }
    
    private func handleKeyboardState(_ state: KeyboardState) {
        switch state {
        case .hidden:
            keyboardHeight = 0
            isKeyboardVisible = false
            if panelState.isKeyboard {
                panelState = .none
            }
        case .showing(let info), .shown(let info):
            keyboardHeight = info.height
            isKeyboardVisible = true
            if info.height > 0 {
                lastKnownKeyboardHeight = info.height
            }
            if panelState != .keyboard && !panelState.isPanel {
                panelState = .keyboard
            }
        case .hiding:
            isKeyboardVisible = false
        }
    }
    
    public func startMonitoring() {
        keyboardEventProvider.startMonitoring()
        lastKnownKeyboardHeight = keyboardEventProvider.lastKnownHeight
    }
    
    public func stopMonitoring() {
        keyboardEventProvider.stopMonitoring()
    }
    
    public func togglePanel(_ item: KeyboardPanelItem) {
        if panelState.currentPanelId == item.id {
            showKeyboard()
        } else {
            showPanel(item)
        }
    }
    
    public func showPanel(_ item: KeyboardPanelItem) {
        focusController.dismissKeyboard()
        withAnimation(.easeInOut(duration: animationDuration)) {
            panelState = .panel(item)
        }
    }
    
    public func showKeyboard() {
        panelState = .keyboard
    }
    
    public func dismiss() {
        focusController.dismissKeyboard()
        withAnimation(.easeInOut(duration: animationDuration)) {
            panelState = .none
        }
    }
}
