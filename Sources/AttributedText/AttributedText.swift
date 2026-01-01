import SwiftUI
import UIKit
import os

public struct AttributedText: UIViewRepresentable {
    public init(
        _ attributedString: AttributedString
    ) {
        self.attributedString = attributedString
    }

    let attributedString: AttributedString
    
    let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: #file
    )

    public typealias UIViewType = UIKitTextView

    public func makeUIView(context: Context) -> UIViewType {
        // Setup
        let textView = UIViewType()
        textView.delegate = context.coordinator
        textView.allowsEditingTextAttributes = true
        textView.isEditable = false
        textView.dataDetectorTypes = []
        
        // Layout
        textView.textContainerInset = .zero
        textView.contentInset = .zero
        textView.isScrollEnabled = false
        textView.textContainer.lineFragmentPadding = 0
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        textView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        textView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        
        // Appearance
        textView.backgroundColor = .clear
        textView.showsVerticalScrollIndicator = false
        textView.showsHorizontalScrollIndicator = false

        // https://twitter.com/noppefoxwolf/status/1672849798632976384?s=61&t=cwsZFMcBypoSq1n2DhTXeQ
        context.coordinator.openURLAction = context.environment.openURL
        context.coordinator.textItemTagAction = context.environment.onTapTextItemTagAction
        return textView
    }

    public func updateUIView(_ textView: UIViewType, context: Context) {
        textView.extraActions = context.environment.extraActions

        // FIXME: NSAttributedStringの生成が重い
        textView.attributedText = try! NSAttributedString(
            attributedString,
            including: \.uiKit
        )
        textView.textLayoutManager?.textContainer?.maximumNumberOfLines =
            context.environment.lineLimit ?? 0
        textView.textLayoutManager?.textContainer?.lineBreakMode =
            context.environment.lineBreakMode ?? .byWordWrapping
        textView.textLayoutManager?.textContainer?.lineFragmentPadding =
            context.environment.lineFragmentPadding ?? 0
        textView.allowsSelectionTextItems = context.environment.allowsSelectionTextItems
        textView.isSelectable = !context.environment.allowsSelectionTextItems.isEmpty
        textView.onCopy = context.environment.onCopy.map { action in
            { action(AttributedString($0)) }
        }
        
        if context.environment.allowsSelectionTextItems != TextItemType.allCases {
            // Lightweight hack
            for subview in textView.subviews {
                if "\(type(of: subview))" != "_UITextContainerView" {
                    subview.removeFromSuperview()
                }
            }
            for gestureRecognizer in textView.gestureRecognizers ?? [] {
                if gestureRecognizer.name != "UITextInteractionNameLinkTap" {
                    textView.removeGestureRecognizer(gestureRecognizer)
                }
            }
        }
    }

    public func sizeThatFits(_ proposal: ProposedViewSize, uiView: UIViewType, context: Context)
        -> CGSize?
    {
        // guard zero, infinity and Nan
        guard let proposalWidth = proposal.width, proposalWidth.isNormal else { return .zero }
        func nearestEvenMultiple(of number: Double) -> Double {
            round(number / 2) * 2
        }
        let width = nearestEvenMultiple(of: proposalWidth)
        // workaround: Layout側でキャッシュしてもsizeThatFitsが呼ばれるのでCoordinatorで設定する
        let attributedStringHashValue = attributedString.hashValue
        let numberOfLines = context.environment.lineLimit ?? 0
        let cacheKey = TextViewSizeCacheKey(
            width: width,
            attributedStringHashValue: attributedStringHashValue,
            numberOfLines: numberOfLines
        )
        let retriever = TextViewSizeCacheRetriever(cache: context.environment.textViewSizeCache)
        if let size = retriever.sizeThatFits(cacheKey) {
            return CGSize(width: size.width, height: size.height)
        } else {
            let proposalSize = CGSize(width: width, height: 0)
            let size = uiView.sizeThatFits(proposalSize)
            let value = TextViewSizeCacheValue(width: size.width, height: size.height)
            context.environment.textViewSizeCache[cacheKey] = value
            return size
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    public final class Coordinator: NSObject, UITextViewDelegate {

        var openURLAction: OpenURLAction? = nil
        var textItemTagAction: OnTapTextItemTagAction? = nil

        public func textView(
            _ textView: UITextView,
            primaryActionFor textItem: UITextItem,
            defaultAction: UIAction
        ) -> UIAction? {
            switch textItem.content {
            case .link(let url):
                return openURLAction.map({ action in
                    UIAction(handler: { _ in action(url) })
                })
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
