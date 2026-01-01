import UIKit
import os

public final class UIKitTextView: UITextView {
    var extraActions: [UIAction] = []
    var allowsSelectionTextItems: [TextItemType] = TextItemType.allCases
    var onCopy: ((NSAttributedString) -> Void)? = nil

    public override func editMenu(for textRange: UITextRange, suggestedActions: [UIMenuElement])
        -> UIMenu?
    {
        var actions = suggestedActions

        if !textRange.isEmpty {
            let customMenu = UIMenu(options: .displayInline, children: extraActions)
            actions.append(customMenu)
        }

        return UIMenu(children: actions)
    }

    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        switch allowsSelectionTextItems {
        case TextItemType.allCases:
            return super.point(inside: point, with: event)
        case []:
            return false
        default:
            // リンク以外のタップを無効
            guard let position = closestPosition(to: point) else {
                return false
            }
            guard
                let range = tokenizer.rangeEnclosingPosition(
                    position,
                    with: .character,
                    inDirection: .layout(.left)
                )
            else {
                return false
            }
            let startIndex = offset(from: beginningOfDocument, to: range.start)
            return allowsSelectionTextItems.map { textItemType in
                switch textItemType {
                case .link:
                    attributedText.attribute(.link, at: startIndex, effectiveRange: nil) != nil
                case .tag:
                    attributedText.attribute(.textItemTag, at: startIndex, effectiveRange: nil) != nil
                case .textAttachment:
                    attributedText.attribute(.attachment, at: startIndex, effectiveRange: nil) != nil
                }
            }.contains(true)
        }
    }
    
    public override func copy(_ sender: Any?) {
        if let onCopy {
            let selectedText = attributedText.attributedSubstring(from: selectedRange)
            onCopy(selectedText)
        } else {
            super.copy(sender)
        }
    }
}
