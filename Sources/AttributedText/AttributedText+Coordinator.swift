import UIKit
import SwiftUI

extension AttributedText {
    public final class Coordinator: NSObject, UITextViewDelegate {
        var openURLAction: OpenURLAction? = nil
        var textItemTagAction: ((String) -> Void)? = nil

        public func textView(
            _ textView: UITextView,
            primaryActionFor textItem: UITextItem,
            defaultAction: UIAction
        ) -> UIAction? {
            switch textItem.content {
            case .link(let url):
                return openURLAction.map { action in
                    UIAction(handler: { _ in action(url) })
                }
            case .textAttachment:
                return nil
            case .tag(let textItemTag):
                return textItemTagAction.map { action in
                    UIAction(handler: { _ in action(textItemTag) })
                }
            @unknown default:
                return nil
            }
        }
    }
}
