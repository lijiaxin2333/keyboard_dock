import SwiftUI
import Combine

@MainActor
public final class KeyboardPanelViewModel: ObservableObject {
    @Published public var panelState: KeyboardPanelState = .none
    @Published public var keyboardHeight: CGFloat = 0
    @Published public private(set) var lastKnownKeyboardHeight: CGFloat = 336
    @Published public var isKeyboardVisible: Bool = false
    @Published public private(set) var isTransitioning: Bool = false
    
    private let keyboardEventProvider: KeyboardEventProviding
    private let focusController: KeyboardFocusControlling
    private var cancellables = Set<AnyCancellable>()
    private var pendingKeyboardShow: Bool = false
    private var previousPanelId: String?
    
    public var bottomSafeAreaHeight: CGFloat = 0
    
    public var panelDisplayHeight: CGFloat {
        max(0, lastKnownKeyboardHeight - bottomSafeAreaHeight)
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
            if panelState.isKeyboard && !pendingKeyboardShow {
                panelState = .none
                isTransitioning = false
            }
        case .showing(let info):
            keyboardHeight = info.height
            isKeyboardVisible = true
            if info.height > 0 {
                lastKnownKeyboardHeight = info.height
            }
            if pendingKeyboardShow || isTransitioning {
                pendingKeyboardShow = false
                panelState = .keyboard
            } else if !panelState.isPanel && panelState != .keyboard {
                panelState = .keyboard
            }
        case .shown(let info):
            keyboardHeight = info.height
            isKeyboardVisible = true
            if info.height > 0 {
                lastKnownKeyboardHeight = info.height
            }
            panelState = .keyboard
            isTransitioning = false
            pendingKeyboardShow = false
            previousPanelId = nil
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
    
    public func togglePanel(_ panelId: String) {
        if panelState.currentPanelId == panelId {
            requestShowKeyboard()
        } else {
            showPanel(panelId)
        }
    }
    
    public func togglePanel(_ item: KeyboardPanelItem) {
        togglePanel(item.id)
    }
    
    public func showPanel(_ panelId: String) {
        focusController.dismissKeyboard()
        previousPanelId = nil
        withAnimation(.easeInOut(duration: animationDuration)) {
            panelState = .panel(panelId)
        }
    }
    
    public func showPanel(_ item: KeyboardPanelItem) {
        showPanel(item.id)
    }
    
    public func requestShowKeyboard() {
        if let currentId = panelState.currentPanelId {
            previousPanelId = currentId
        }
        pendingKeyboardShow = true
        isTransitioning = true
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
