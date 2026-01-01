public import UIKit
public import SwiftUI
import os

public struct AttributedText: UIViewRepresentable {
    let attributedText: AttributedString

    let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: #file
    )

    public init(_ attributedText: AttributedString) {
        self.attributedText = attributedText
    }

    public func makeUIView(context: Context) -> AttributedTextView {
        let uiView = AttributedTextView()
        uiView.isEditable = false
        uiView.isSelectable = false
        uiView.isScrollEnabled = false
        uiView.contentInset = .zero
        uiView.backgroundColor = .clear
        uiView.dataDetectorTypes = []

        // Remove Insets
        uiView.textContainer.lineFragmentPadding = 0
        uiView.textContainerInset = .zero

        uiView.allowsEditingTextAttributes = true
        uiView.showsVerticalScrollIndicator = false
        uiView.showsHorizontalScrollIndicator = false

        context.coordinator.openURLAction = context.environment.openURL
        context.coordinator.textItemTagAction = context.environment.onTapTextItemTagAction

        for subview in uiView.subviews {
            if "\(type(of: subview))" != "_UITextContainerView" {
                subview.removeFromSuperview()
            }
        }
        for gestureRecognizer in uiView.gestureRecognizers ?? [] {
            if gestureRecognizer.name != "UITextInteractionNameLinkTap" {
                uiView.removeGestureRecognizer(gestureRecognizer)
            }
        }

        return uiView
    }

    public func updateUIView(_ uiView: AttributedTextView, context: Context) {
        // SwiftUI.Text compatibility
        modify(
            &uiView.textContainer.maximumNumberOfLines,
            newValue: context.environment.lineLimit ?? 0
        )
        modify(
            &uiView.textContainer.lineBreakMode,
            newValue: context.environment.truncationMode.lineBreakMode
        )

        modify(
            &uiView.attributedText,
            newValue: NSAttributedString(attributedText)
        )
    }

    func modify<T: Equatable>(_ value: inout T, newValue: T) {
        if value != newValue {
            value = newValue
        }
    }

    public func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView: AttributedTextView,
        context: Context
    ) -> CGSize? {
        var targetSize = CGSize(
            width: (proposal.width ?? UIView.noIntrinsicMetric).rounded(.towardZero),
            height: UIView.noIntrinsicMetric
        )

        if !targetSize.width.isNormal {
            targetSize.width = 0
        }

        let key = Cache.Key(attributedString: attributedText, targetSize: targetSize)
        if let cache = Cache.shared.get(key) {
            logger.info("Cache hit!: \(key.attributedString.hashValue) \(key.targetSize.width) \(key.targetSize.height)")
            return cache
        }
        let sizeThatFits = uiView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .required
        )
        Cache.shared.set(key, size: sizeThatFits)

        logger
            .info(
                "Cache miss: \(key.attributedString.hashValue) \(key.targetSize.width) \(key.targetSize.height) > \(sizeThatFits.width)x\(sizeThatFits.height)"
            )
        return sizeThatFits
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }
}
