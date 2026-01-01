import SwiftUI
import AttributedText

@main
struct App: SwiftUI.App {
    var body: some Scene {
        WindowGroup {
            NavigationView {
                List {
                    AttributedText("Hello, World!!")
                    AttributedText("in List")
                    VStack {
                        AttributedText("Hello, World!!")
                        AttributedText("in VStack")
                    }
                    HStack {
                        AttributedText("Hello, World!!")
                        AttributedText("in HStack")
                    }
                    
                    AttributedText(attributedString)
                    
                    AttributedText(nsAttributedString)
                }.navigationTitle("DAWNText")
            }
        }
    }
    
    var attributedString: AttributedString {
        var attributedString = try! AttributedString(
            markdown: """
            **Markdown** is *easy* syntax.
            [Link to Apple](https://apple.com)
            """,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )
        attributedString.font = UIFont.preferredFont(forTextStyle: .body)
        attributedString.foregroundColor = UIColor.label
        return attributedString
    }
    
    var nsAttributedString: AttributedString {
        let attachment = NSTextAttachment(image: .actions)
        let nsAttributedString = NSMutableAttributedString(attachment: attachment)
        nsAttributedString.append(NSAttributedString("is image."))
        var attributedString = AttributedString(nsAttributedString)
        attributedString.font = UIFont.preferredFont(forTextStyle: .body)
        attributedString.foregroundColor = UIColor.label
        return attributedString
    }
}
