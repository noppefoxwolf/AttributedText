import Testing
import UIKit

@testable import AttributedText

@Suite
struct AttributedTextContentTests {
    @Test
    func defaultLineBreakStrategyMatchesSwiftUIText() {
        let content = NSAttributedString("Text")

        let result = content.applyingDefaultLineBreakStrategy()
        let paragraphStyle = result.attribute(.paragraphStyle, at: 0, effectiveRange: nil)
            as? NSParagraphStyle

        #expect(paragraphStyle?.lineBreakStrategy == .standard)
    }

    @Test
    func defaultForegroundColorIsAppliedOnlyToUncoloredText() {
        let content = NSMutableAttributedString(string: "Default Red")
        content.addAttribute(.foregroundColor, value: UIColor.systemRed, range: NSRange(location: 8, length: 3))

        let result = content.applyingDefaultForegroundColor(.label)

        #expect(result.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor == .label)
        #expect(result.attribute(.foregroundColor, at: 8, effectiveRange: nil) as? UIColor == .systemRed)
    }

    @Test
    func resolvedAttributesMatchThePreviousTransformationChain() {
        let content = NSMutableAttributedString(string: "Default Red")
        content.addAttribute(.foregroundColor, value: UIColor.systemRed, range: NSRange(location: 8, length: 3))
        content.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 18), range: NSRange(location: 8, length: 3))

        let expected = content
            .applyingDefaultFont(.systemFont(ofSize: 17))
            .applyingDefaultForegroundColor(.label)
            .applyingTextAlignment(.center)
            .applyingLineSpacing(4)
            .applyingDefaultLineBreakStrategy()
        let actual = content.applyingResolvedTextAttributes(
            defaultFont: .systemFont(ofSize: 17),
            defaultForegroundColor: .label,
            textAlignment: .center,
            lineSpacing: 4
        )

        #expect(actual.isEqual(to: expected))
    }
}
