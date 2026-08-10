import Testing
import UIKit

@testable import AttributedText

@Suite
struct AttributedTextContentTests {
    @Test
    func identicalAttributesAreEqual() {
        var lhs = AttributedString("Same text")
        lhs.font = UIFont.systemFont(ofSize: 17)
        lhs.foregroundColor = .label

        var rhs = AttributedString("Same text")
        rhs.font = UIFont.systemFont(ofSize: 17)
        rhs.foregroundColor = .label

        #expect(AttributedTextContent(NSAttributedString(lhs)) == AttributedTextContent(NSAttributedString(rhs)))
    }

    @Test
    func differentFontsAreNotEqualWhenTheStringIsTheSame() {
        var regular = AttributedString("Same text")
        regular.font = UIFont.systemFont(ofSize: 17)

        var large = AttributedString("Same text")
        large.font = UIFont.systemFont(ofSize: 24)

        #expect(AttributedTextContent(NSAttributedString(regular)) != AttributedTextContent(NSAttributedString(large)))
    }

    @Test
    func differentColorsAreNotEqualWhenTheStringIsTheSame() {
        var red = AttributedString("Same text")
        red.foregroundColor = .systemRed

        var blue = AttributedString("Same text")
        blue.foregroundColor = .systemBlue

        #expect(AttributedTextContent(NSAttributedString(red)) != AttributedTextContent(NSAttributedString(blue)))
    }

    @Test
    func defaultLineBreakStrategyMatchesSwiftUIText() {
        let content = NSAttributedString("Text")

        let result = content.applyingDefaultLineBreakStrategy()
        let paragraphStyle = result.attribute(.paragraphStyle, at: 0, effectiveRange: nil)
            as? NSParagraphStyle

        #expect(paragraphStyle?.lineBreakStrategy == .standard)
    }
}
