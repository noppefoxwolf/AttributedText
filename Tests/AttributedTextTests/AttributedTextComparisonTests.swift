import Testing
import UIKit

@testable import AttributedText

@Suite
@MainActor
struct AttributedTextComparisonTests {
    @Test
    func equalAttributedStringsDoNotNeedAnUpdate() {
        let current = NSAttributedString(string: "Same text")
        let updated = NSAttributedString(string: "Same text")

        #expect(!AttributedText.needsTextUpdate(current: current, updated: updated))
    }

    @Test
    func differentCharactersNeedAnUpdate() {
        let current = NSAttributedString(string: "Old text")
        let updated = NSAttributedString(string: "New text")

        #expect(AttributedText.needsTextUpdate(current: current, updated: updated))
    }

    @Test
    func differentAttributesNeedAnUpdate() {
        let current = NSAttributedString(
            string: "Text",
            attributes: [.foregroundColor: UIColor.red]
        )
        let updated = NSAttributedString(
            string: "Text",
            attributes: [.foregroundColor: UIColor.blue]
        )

        #expect(AttributedText.needsTextUpdate(current: current, updated: updated))
    }

    @Test
    func theSameAttachmentInstanceIsEqual() {
        let attachment = NSTextAttachment()
        let current = NSAttributedString(attachment: attachment)
        let updated = NSAttributedString(attachment: attachment)

        #expect(!AttributedText.needsTextUpdate(current: current, updated: updated))
    }

    @Test
    func distinctAttachmentInstancesAreNotEqualEvenWhenTheirBoundsMatch() {
        let currentAttachment = NSTextAttachment()
        currentAttachment.bounds = CGRect(x: 0, y: 0, width: 10, height: 10)
        let updatedAttachment = NSTextAttachment()
        updatedAttachment.bounds = currentAttachment.bounds
        let current = NSAttributedString(attachment: currentAttachment)
        let updated = NSAttributedString(attachment: updatedAttachment)

        #expect(AttributedText.needsTextUpdate(current: current, updated: updated))
    }

    @Test
    func mutatingTheSharedAttachmentInstanceDoesNotMakeItsAttributeUnequal() {
        let attachment = NSTextAttachment()
        let current = NSAttributedString(attachment: attachment)
        attachment.bounds = CGRect(x: 0, y: 0, width: 10, height: 10)
        let updated = NSAttributedString(attachment: attachment)

        #expect(!AttributedText.needsTextUpdate(current: current, updated: updated))
    }

    @Test
    func missingCurrentTextNeedsAnUpdate() {
        let updated = NSAttributedString(string: "Text")

        #expect(AttributedText.needsTextUpdate(current: nil, updated: updated))
    }
}
