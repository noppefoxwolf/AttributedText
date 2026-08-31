public import SwiftUI
public import AttributedTextView
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
        uiView.adjustsFontForContentSizeCategory = true
        uiView.textColor = .label

        return uiView
    }

    public func updateUIView(_ uiView: AttributedTextView, context: Context) {
        let environment = context.environment
        context.coordinator.openURLAction = environment.openURL
        context.coordinator.textItemTagAction = environment.onTapTextItemTagAction

        modify(
            &uiView.textContainer.maximumNumberOfLines,
            newValue: environment.lineLimit ?? 0
        )
        if AttributedString(uiView.attributedText) != attributedText {
            uiView.attributedText = NSAttributedString(attributedText)
        }

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
            uiView.onCopy = { selectedAttributedText in
                copyAction(AttributedString(selectedAttributedText))
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

        let key = Cache.Key(
            attributedString: attributedText,
            targetSize: targetSize,
            maximumNumberOfLines: context.environment.lineLimit ?? 0
        )
        if let cache = Cache.shared.get(key) {
            return cache
        }
        let sizeThatFits = uiView.sizeThatFits(
            CGSize(width: roundedWidth, height: .greatestFiniteMagnitude)
        )
        Cache.shared.set(key, size: sizeThatFits)
        return sizeThatFits
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }
}
