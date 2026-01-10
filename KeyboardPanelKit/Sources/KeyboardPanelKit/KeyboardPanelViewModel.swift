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
    private var previousPanelItem: KeyboardPanelItem?
    
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
            previousPanelItem = nil
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
            requestShowKeyboard()
        } else {
            showPanel(item)
        }
    }
    
    public func showPanel(_ item: KeyboardPanelItem) {
        focusController.dismissKeyboard()
        previousPanelItem = nil
        withAnimation(.easeInOut(duration: animationDuration)) {
            panelState = .panel(item)
        }
    }
    
    public func requestShowKeyboard() {
        if case .panel(let item) = panelState {
            previousPanelItem = item
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
