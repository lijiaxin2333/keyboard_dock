import Foundation
import UIKit
import SwiftUI
import YYText

@MainActor
public final class RichTextAttributedTextRenderer {
    private let sizeCache: NSCache<NSString, NSValue>

    public init() {
        let cache = NSCache<NSString, NSValue>()
        cache.countLimit = 500
        self.sizeCache = cache
    }

    public func render(
        content: RichTextContent,
        configuration: RichTextConfiguration,
        editorConfig: RichTextEditorStyle,
        tokenViewRegistry: RichTextTokenViewRegistry?,
        onTokenTap: @escaping (RichTextItem) -> Void
    ) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let font = editorConfig.font

        for item in content.items {
            if item.isText {
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: editorConfig.textColor
                ]
                result.append(NSAttributedString(string: item.displayText, attributes: attrs))
                continue
            }

            let trigger = configuration.allTriggers.first { $0.tokenType == item.type }
            let tokenColor = trigger?.tokenColor ?? UIColor.systemBlue
            let tokenFont = trigger?.tokenFont

            let tokenAttrStr = makeTokenAttributedString(
                item: item,
                tokenColor: tokenColor,
                tokenFont: tokenFont,
                font: font,
                configuration: configuration,
                tokenViewRegistry: tokenViewRegistry,
            onTokenTap: onTokenTap,
            editorConfig: editorConfig
            )

            result.append(tokenAttrStr)
        }

        return result
    }

    public func tokenAttributedString(
        item: RichTextItem,
        trigger: RichTextTrigger,
        font: UIFont,
        editorConfig: RichTextEditorStyle,
        configuration: RichTextConfiguration,
        tokenViewRegistry: RichTextTokenViewRegistry?,
        onTokenTap: @escaping (RichTextItem) -> Void
    ) -> NSAttributedString {
        makeTokenAttributedString(
            item: item,
            tokenColor: trigger.tokenColor,
            tokenFont: trigger.tokenFont,
            font: font,
            configuration: configuration,
            tokenViewRegistry: tokenViewRegistry,
            onTokenTap: onTokenTap,
            editorConfig: editorConfig
        )
    }

    private func makeTokenAttributedString(
        item: RichTextItem,
        tokenColor: UIColor,
        tokenFont: UIFont?,
        font: UIFont,
        configuration: RichTextConfiguration,
        tokenViewRegistry: RichTextTokenViewRegistry?,
        onTokenTap: @escaping (RichTextItem) -> Void,
        editorConfig: RichTextEditorStyle
    ) -> NSMutableAttributedString {
        let tapAction: YYTextAction? = {
            if editorConfig.useYYTextHighlightTap {
                return { _, _, _, _ in onTokenTap(item) }
            }
            return nil
        }()
        let highlightBackground = UIColor.systemGray.withAlphaComponent(0.18)
        let finalFont = tokenFont ?? font

        if let tokenView = tokenViewRegistry?.view(for: item, font: finalFont) {
            let key = tokenSizeCacheKey(item: item, font: finalFont, preferredSize: tokenView.size)
            let cached = sizeCache.object(forKey: key)?.cgSizeValue
            let hostingController = UIHostingController(rootView: tokenView.view)
            let finalSize: CGSize
            if let cached {
                finalSize = cached
            } else {
                let measured = RichTextTokenHostingView.measureSize(hostingController: hostingController, font: finalFont)
                let computed = CGSize(
                    width: max(tokenView.size?.width ?? measured.width, finalFont.lineHeight),
                    height: max(tokenView.size?.height ?? measured.height, finalFont.lineHeight)
                )
                finalSize = computed
                sizeCache.setObject(NSValue(cgSize: computed), forKey: key)
            }
            let hostingView = RichTextTokenHostingView(
                hostingController: hostingController,
                intrinsicSize: finalSize
            )
            let attachmentSize = finalSize
            let attachment = NSAttributedString.yy_attachmentString(
                withContent: hostingView,
                contentMode: .center,
                attachmentSize: attachmentSize,
                alignTo: finalFont,
                alignment: .center
            )
            var attrs: [NSAttributedString.Key: Any] = [
                .font: finalFont,
                .richTextItemType: item.type,
                .richTextItemId: item.data,
                .richTextItemDisplayText: item.displayText
            ]
            if let payload = item.payload, payload.isEmpty == false {
                attrs[.richTextItemPayload] = payload
            }
            attachment.addAttributes(attrs, range: NSRange(location: 0, length: attachment.length))
            attachment.yy_setTextBinding(
                YYTextBinding(deleteConfirm: true),
                range: NSRange(location: 0, length: attachment.length)
            )
            if let tapAction {
                attachment.yy_setTextHighlight(
                    NSRange(location: 0, length: attachment.length),
                    color: nil,
                    backgroundColor: highlightBackground,
                    tapAction: tapAction
                )
            }
            return attachment
        }

        var attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: tokenColor,
            .font: finalFont,
            .richTextItemType: item.type,
            .richTextItemId: item.data,
            .richTextItemDisplayText: item.displayText
        ]
        if let payload = item.payload, payload.isEmpty == false {
            attrs[.richTextItemPayload] = payload
        }
        let result = NSMutableAttributedString(string: item.displayText, attributes: attrs)
        result.yy_setTextBinding(
            YYTextBinding(deleteConfirm: true),
            range: NSRange(location: 0, length: result.length)
        )
        if let tapAction {
            result.yy_setTextHighlight(
                NSRange(location: 0, length: result.length),
                color: nil,
                backgroundColor: highlightBackground,
                tapAction: tapAction
            )
        }
        return result
    }

    private func tokenSizeCacheKey(item: RichTextItem, font: UIFont, preferredSize: CGSize?) -> NSString {
        let key = "\(item.type)|\(item.data)"
        return key as NSString
    }
}
