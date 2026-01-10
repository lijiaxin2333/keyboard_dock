import Foundation
import UIKit
import SwiftUI

final class RichTextTokenHostingView: UIView {
    private let hostingController: UIHostingController<AnyView>
    private let intrinsicSize: CGSize
    
    init(hostingController: UIHostingController<AnyView>, intrinsicSize: CGSize) {
        self.hostingController = hostingController
        self.intrinsicSize = intrinsicSize
        super.init(frame: CGRect(origin: .zero, size: intrinsicSize))
        isUserInteractionEnabled = false
        backgroundColor = .clear
        hostingController.view.backgroundColor = .clear
        hostingController.view.frame = bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(hostingController.view)
    }

    convenience init(rootView: AnyView, preferredSize: CGSize?, font: UIFont, intrinsicSize: CGSize?) {
        let hostingController = UIHostingController(rootView: rootView)
        let measured: CGSize
        if let intrinsicSize {
            measured = intrinsicSize
        } else {
            measured = RichTextTokenHostingView.measureSize(hostingController: hostingController, font: font)
        }
        let finalSize = CGSize(
            width: max(preferredSize?.width ?? measured.width, font.lineHeight),
            height: max(preferredSize?.height ?? measured.height, font.lineHeight)
        )
        self.init(hostingController: hostingController, intrinsicSize: finalSize)
    }

    convenience init(rootView: AnyView, preferredSize: CGSize?, font: UIFont) {
        self.init(rootView: rootView, preferredSize: preferredSize, font: font, intrinsicSize: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var intrinsicContentSize: CGSize {
        intrinsicSize
    }
    
    static func measureSize(hostingController: UIHostingController<AnyView>, font: UIFont) -> CGSize {
        let target = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        let measured = hostingController.sizeThatFits(in: target)
        if measured == .zero || measured.width.isNaN || measured.height.isNaN {
            return CGSize(width: font.lineHeight * 2, height: font.lineHeight * 1.2)
        }
        return measured
    }
}

