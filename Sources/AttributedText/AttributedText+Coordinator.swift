public import SwiftUI
import UIKit

extension AttributedText {
    public final class Coordinator: NSObject, UITextViewDelegate {
        var openURLAction: OpenURLAction? = nil
        var textItemTagAction = OnTapTextItemTagAction()

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
                guard !textItemTagAction.isEmpty else { return nil }
                return UIAction(handler: { [textItemTagAction] _ in textItemTagAction(textItemTag) })
            @unknown default:
                return nil
            }
        }
    }
}
