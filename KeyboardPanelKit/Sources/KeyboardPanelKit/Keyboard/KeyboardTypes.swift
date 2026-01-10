import Foundation
import CoreGraphics

public struct KeyboardInfo: Equatable, Sendable {
    public let height: CGFloat
    public let animationDuration: TimeInterval
    public let animationCurve: UInt
    
    public init(height: CGFloat, animationDuration: TimeInterval, animationCurve: UInt) {
        self.height = height
        self.animationDuration = animationDuration
        self.animationCurve = animationCurve
    }
    
    public static let zero = KeyboardInfo(height: 0, animationDuration: 0.25, animationCurve: 7)
}

public enum KeyboardState: Equatable, Sendable {
    case hidden
    case showing(KeyboardInfo)
    case shown(KeyboardInfo)
    case hiding(KeyboardInfo)
    
    public var isVisible: Bool {
        switch self {
        case .hidden, .hiding:
            return false
        case .showing, .shown:
            return true
        }
    }
    
    public var height: CGFloat {
        switch self {
        case .hidden:
            return 0
        case .showing(let info), .shown(let info), .hiding(let info):
            return info.height
        }
    }
    
    public var animationDuration: TimeInterval {
        switch self {
        case .hidden:
            return 0.25
        case .showing(let info), .shown(let info), .hiding(let info):
            return info.animationDuration
        }
    }
    
    public var animationCurve: UInt {
        switch self {
        case .hidden:
            return 7
        case .showing(let info), .shown(let info), .hiding(let info):
            return info.animationCurve
        }
    }
}
