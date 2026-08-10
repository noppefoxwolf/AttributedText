public import SwiftUI
import UIKit
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
        uiView.delegate = context.coordinator
        uiView.isEditable = false
        uiView.isSelectable = false
        uiView.isScrollEnabled = false
        uiView.contentInset = .zero
        uiView.backgroundColor = .clear
        uiView.dataDetectorTypes = []

        // Remove Insets
        uiView.textContainer.lineFragmentPadding = 0
        uiView.textContainerInset = .zero

        // Disabled
        uiView.allowsEditingTextAttributes = true
        uiView.showsVerticalScrollIndicator = false
        uiView.showsHorizontalScrollIndicator = false

        context.coordinator.openURLAction = context.environment.openURL
        context.coordinator.textItemTagAction = context.environment.onTapTextItemTagAction

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
            &uiView.textAlignment,
            newValue: context.environment.multilineTextAlignment.textAlignment
        )
        modify(
            &uiView.attributedTextContent,
            newValue: AttributedTextContent(NSAttributedString(attributedText))
        )

        modify(
            &uiView.extraActions,
            newValue: context.environment.extraActions
        )

        modify(
            &uiView.allowsSelectionTextItems,
            newValue: context.environment.allowsSelectionTextItems
        )

        modify(
            &uiView.isSelectable,
            newValue: !context.environment.allowsSelectionTextItems.isEmpty
        )

        let copyAction = context.environment.onCopy
        if copyAction.isEmpty {
            uiView.onCopy = nil
        } else {
            uiView.onCopy = { selectedText in
                copyAction(AttributedString(selectedText))
            }
        }

        if context.environment.allowsSelectionTextItems != TextItemType.allCases {
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
        }
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
        guard let proposedWidth = proposal.width,
            proposedWidth.isNormal
        else {
            return .zero
        }

        let roundedWidth = proposedWidth.rounded(.towardZero)
        guard roundedWidth > 0 else {
            return .zero
        }

        let targetSize = CGSize(
            width: roundedWidth,
            height: UIView.noIntrinsicMetric
        )

        let key = Cache.Key(attributedString: attributedText, targetSize: targetSize)
        if let cache = Cache.shared.get(key) {
            return cache
        }
        let sizeThatFits = uiView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .required
        )
        Cache.shared.set(key, size: sizeThatFits)
        return sizeThatFits
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }
}
