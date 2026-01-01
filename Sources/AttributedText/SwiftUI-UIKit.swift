import SwiftUI
import UIKit

extension NSTextAlignment {
    package init(_ alignment: TextAlignment) {
        switch alignment {
        case .leading:
            self = .left
        case .center:
            self = .center
        case .trailing:
            self = .right
        }
    }
}
