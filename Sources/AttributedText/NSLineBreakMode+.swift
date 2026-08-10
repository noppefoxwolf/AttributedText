import SwiftUI
import UIKit

extension Text.TruncationMode {
    var lineBreakMode: NSLineBreakMode {
        switch self {
        case .head:
            .byTruncatingHead
        case .middle:
            .byTruncatingMiddle
        case .tail:
            .byTruncatingTail
        @unknown default:
            .byTruncatingTail
        }
    }
}
