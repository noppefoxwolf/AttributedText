import SwiftUI
import Testing
import UIKit

@testable import AttributedText

@Suite
struct AttributedTextContentTests {
    @Test
    @MainActor
    func attributedStringFontTakesPrecedenceOverSwiftUIFontModifier() {
        var content = AttributedString("Attributed font")
        content.font = UIFont.systemFont(ofSize: 40)

        let sizeWithoutModifier = UIHostingController(
            rootView: Text(content)
        ).sizeThatFits(in: CGSize(width: 1_000, height: 1_000))
        let sizeWithModifier = UIHostingController(
            rootView: Text(content).font(.system(size: 12))
        ).sizeThatFits(in: CGSize(width: 1_000, height: 1_000))

        #expect(sizeWithModifier == sizeWithoutModifier)
    }
}
