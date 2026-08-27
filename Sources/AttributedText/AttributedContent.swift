import Foundation
import UIKit
import SwiftUI

struct RenderedContentConfiguration: Equatable {
    let attributedText: AttributedString
    let font: UIFont?
    let textCase: Text.Case?
    let textAlignment: NSTextAlignment
    let lineSpacing: CGFloat
}

// 参照ポインタの違いなどで見た目が同じであるのにequalにならない事があるので自前で比較する
final class AttributedTextContent: Equatable {
    let content: NSAttributedString

    init(_ content: NSAttributedString) {
        self.content = content
    }

    static func == (lhs: AttributedTextContent, rhs: AttributedTextContent) -> Bool {
        lhs.content.isEqual(to: rhs.content)
    }
}

extension UITextView {
    var attributedTextContent: AttributedTextContent {
        get { AttributedTextContent(attributedText) }
        set { attributedText = newValue.content }
    }
}
