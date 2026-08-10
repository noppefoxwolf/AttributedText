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
        uiView.adjustsFontForContentSizeCategory = true
        uiView.textColor = .label

        context.coordinator.openURLAction = context.environment.openURL
        context.coordinator.textItemTagAction = context.environment.onTapTextItemTagAction

        return uiView
    }

    public func updateUIView(_ uiView: AttributedTextView, context: Context) {
        let environment = context.environment
        let lineBreakMode = environment.lineLimit == nil
            ? NSLineBreakMode.byWordWrapping
            : environment.truncationMode.lineBreakMode

        // SwiftUI.Text compatibility
        modify(
            &uiView.font,
            newValue: resolvedFont(for: environment.font, in: environment)
        )
        modify(
            &uiView.textContainer.maximumNumberOfLines,
            newValue: environment.lineLimit ?? 0
        )
        modify(
            &uiView.textContainer.lineBreakMode,
            newValue: lineBreakMode
        )
        modify(
            &uiView.textAlignment,
            newValue: environment.multilineTextAlignment.textAlignment
        )
        uiView.textContainer.lineBreakMode = lineBreakMode
        uiView.textContainer.lineFragmentPadding = 0
        uiView.textContainerInset = .zero

        var content = NSAttributedString(attributedText)
        switch environment.textCase {
        case .uppercase:
            content = content.applyingTextCase(.uppercase)
        case .lowercase:
            content = content.applyingTextCase(.lowercase)
        case nil:
            break
        @unknown default:
            break
        }
        content = content.applyingDefaultFont(uiView.font)
        content = content.applyingTextAlignment(environment.multilineTextAlignment.textAlignment)
        content = content.applyingLineSpacing(environment.lineSpacing)
        modify(
            &uiView.attributedTextContent,
            newValue: AttributedTextContent(content)
        )
        uiView.textAlignment = environment.multilineTextAlignment.textAlignment

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

        let key = Cache.Key(
            attributedString: attributedText,
            targetSize: targetSize,
            font: context.environment.font,
            maximumNumberOfLines: context.environment.lineLimit ?? 0,
            lineBreakMode: context.environment.lineLimit == nil
                ? .byWordWrapping
                : context.environment.truncationMode.lineBreakMode,
            textAlignment: context.environment.multilineTextAlignment.textAlignment,
            lineSpacing: context.environment.lineSpacing,
            textCase: context.environment.textCase
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

    private func resolvedFont(for font: Font?, in environment: EnvironmentValues) -> UIFont {
        guard let font else {
            return UIFont.preferredFont(forTextStyle: .body)
        }

        if #available(iOS 26.0, *) {
            let resolved = font.resolve(in: environment.fontResolutionContext)
            let descriptor = CTFontCopyFontDescriptor(resolved.ctFont) as UIFontDescriptor
            return UIFont(descriptor: descriptor, size: resolved.pointSize)
        }

        let textStyle: UIFont.TextStyle?
        switch font {
        case .largeTitle:
            textStyle = .largeTitle
        case .title:
            textStyle = .title1
        case .title2:
            textStyle = .title2
        case .title3:
            textStyle = .title3
        case .headline:
            textStyle = .headline
        case .subheadline:
            textStyle = .subheadline
        case .body:
            textStyle = .body
        case .callout:
            textStyle = .callout
        case .footnote:
            textStyle = .footnote
        case .caption:
            textStyle = .caption1
        case .caption2:
            textStyle = .caption2
        default:
            textStyle = nil
        }

        if let textStyle {
            return UIFont.preferredFont(forTextStyle: textStyle)
        }
        return UIFont.preferredFont(forTextStyle: .body)
    }
}

private extension NSAttributedString {
    func applyingTextCase(_ textCase: Text.Case) -> NSAttributedString {
        let result = NSMutableAttributedString(attributedString: self)
        let transformed: String
        switch textCase {
        case .uppercase:
            transformed = string.uppercased()
        case .lowercase:
            transformed = string.lowercased()
        @unknown default:
            transformed = string
        }
        result.mutableString.setString(transformed)
        return result
    }

    func applyingLineSpacing(_ lineSpacing: CGFloat) -> NSAttributedString {
        guard lineSpacing != 0 else { return self }

        let result = NSMutableAttributedString(attributedString: self)
        let range = NSRange(location: 0, length: result.length)
        result.enumerateAttribute(.paragraphStyle, in: range) { value, range, _ in
            let paragraphStyle = (value as? NSParagraphStyle)?.mutableCopy()
                as? NSMutableParagraphStyle ?? NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = lineSpacing
            result.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
        }
        if result.length > 0, result.attribute(.paragraphStyle, at: 0, effectiveRange: nil) == nil {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = lineSpacing
            result.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
        }
        return result
    }

    func applyingTextAlignment(_ alignment: NSTextAlignment) -> NSAttributedString {
        guard length > 0 else { return self }

        let result = NSMutableAttributedString(attributedString: self)
        let range = NSRange(location: 0, length: result.length)
        let paragraphStyle = (result.attribute(.paragraphStyle, at: 0, effectiveRange: nil)
            as? NSParagraphStyle)?.mutableCopy() as? NSMutableParagraphStyle
            ?? NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        result.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
        return result
    }

    func applyingDefaultFont(_ font: UIFont?) -> NSAttributedString {
        guard let font, length > 0 else { return self }

        let result = NSMutableAttributedString(attributedString: self)
        let range = NSRange(location: 0, length: result.length)
        var missingFontRanges: [NSRange] = []
        result.enumerateAttribute(.font, in: range) { value, range, _ in
            if value == nil {
                missingFontRanges.append(range)
            }
        }
        for range in missingFontRanges {
            result.addAttribute(.font, value: font, range: range)
        }
        return result
    }
}
