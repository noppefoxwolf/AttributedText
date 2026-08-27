import SwiftUI
import UIKit

extension NSAttributedString {
    /// Applies the UIKit attributes that back SwiftUI.Text modifiers in one mutable copy.
    /// The individual helpers remain available for focused transformations and tests.
    func applyingResolvedTextAttributes(
        defaultFont: UIFont?,
        defaultForegroundColor: UIColor?,
        textAlignment: NSTextAlignment,
        lineSpacing: CGFloat
    ) -> NSAttributedString {
        guard length > 0 else { return self }

        let result = NSMutableAttributedString(attributedString: self)
        let range = NSRange(location: 0, length: result.length)
        result.applyingDefaultAttribute(.font, value: defaultFont, in: range)
        result.applyingDefaultAttribute(.foregroundColor, value: defaultForegroundColor, in: range)

        let paragraphStyle = (result.attribute(.paragraphStyle, at: 0, effectiveRange: nil)
            as? NSParagraphStyle)?.mutableCopy() as? NSMutableParagraphStyle
            ?? NSMutableParagraphStyle()
        paragraphStyle.alignment = textAlignment
        if lineSpacing != 0 {
            paragraphStyle.lineSpacing = lineSpacing
        }
        paragraphStyle.lineBreakStrategy = .standard
        result.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
        return result
    }

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

    /// SwiftUI.Text uses the standard line-break strategy by default. UIKit's
    /// paragraph styles default to `.none`, so apply the SwiftUI-compatible
    /// strategy to every paragraph before handing the content to UITextView.
    func applyingDefaultLineBreakStrategy() -> NSAttributedString {
        guard length > 0 else { return self }

        let result = NSMutableAttributedString(attributedString: self)
        let range = NSRange(location: 0, length: result.length)
        result.enumerateAttribute(.paragraphStyle, in: range) { value, range, _ in
            let paragraphStyle = (value as? NSParagraphStyle)?.mutableCopy()
                as? NSMutableParagraphStyle ?? NSMutableParagraphStyle()
            paragraphStyle.lineBreakStrategy = .standard
            result.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
        }
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

    func applyingDefaultForegroundColor(_ color: UIColor?) -> NSAttributedString {
        guard let color, length > 0 else { return self }

        let result = NSMutableAttributedString(attributedString: self)
        let range = NSRange(location: 0, length: result.length)
        var missingColorRanges: [NSRange] = []
        result.enumerateAttribute(.foregroundColor, in: range) { value, range, _ in
            if value == nil {
                missingColorRanges.append(range)
            }
        }
        for range in missingColorRanges {
            result.addAttribute(.foregroundColor, value: color, range: range)
        }
        return result
    }
}

private extension NSMutableAttributedString {
    func applyingDefaultAttribute(_ key: NSAttributedString.Key, value: Any?, in range: NSRange) {
        guard let value else { return }

        var missingRanges: [NSRange] = []
        enumerateAttribute(key, in: range) { existingValue, range, _ in
            if existingValue == nil {
                missingRanges.append(range)
            }
        }
        for missingRange in missingRanges {
            addAttribute(key, value: value, range: missingRange)
        }
    }
}
