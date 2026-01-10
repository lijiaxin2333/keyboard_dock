import Foundation
import Combine

#if canImport(RichTextKit)
import RichTextKit

@MainActor
public final class RichTextInputBridgeAdapter: KeyboardPanelTokenInputBridge {
    public typealias TokenItem = any SuggestionItem
    public typealias TriggerType = RichTextTrigger
    
    public let viewModel: RichTextEditorViewModel
    private var cancellables = Set<AnyCancellable>()
    
    public var onContentChanged: ((String) -> Void)?
    public var onTriggerChanged: ((RichTextTrigger?, String) -> Void)?
    
    public var plainText: String {
        viewModel.content.plainText
    }
    
    public var isEmpty: Bool {
        viewModel.content.items.isEmpty
    }
    
    public var activeTrigger: RichTextTrigger? {
        viewModel.activeTrigger
    }
    
    public var searchKeyword: String {
        viewModel.searchKeyword
    }
    
    public init(viewModel: RichTextEditorViewModel) {
        self.viewModel = viewModel
        setupBindings()
    }
    
    private func setupBindings() {
        viewModel.$content
            .receive(on: DispatchQueue.main)
            .sink { [weak self] content in
                self?.onContentChanged?(content.plainText)
            }
            .store(in: &cancellables)
        
        Publishers.CombineLatest(
            viewModel.$activeTrigger,
            viewModel.$searchKeyword
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] trigger, keyword in
            self?.onTriggerChanged?(trigger, keyword)
        }
        .store(in: &cancellables)
    }
    
    public func insertText(_ text: String) {
    }
    
    public func insertToken(_ item: any SuggestionItem, trigger: RichTextTrigger) {
        viewModel.insertToken(item: item, trigger: trigger)
    }
    
    public func clearContent() {
        viewModel.clearContent()
    }
    
    public func dismissSuggestionPanel() {
        viewModel.dismissSuggestionPanel()
    }
}
#endif
