import AttributedText
import SwiftUI
import UIKit

@main
struct App: SwiftUI.App {
    var body: some Scene {
        WindowGroup {
            ComparisonView()
        }
    }
}

private struct ComparisonView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("SwiftUI.Text と AttributedText の描画比較")
                        .font(.headline)
                        .padding(.horizontal)

                    Text("同じ入力・同じ modifier を上下に並べています。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    comparison("Default", swiftUI: {
                        Text("Hello, World!!")
                    }, attributedText: {
                        AttributedText(AttributedString("Hello, World!!"))
                    })

                    comparison("Font", swiftUI: {
                        Text("Title 2 / Bold")
                            .font(.title2)
                            .bold()
                    }, attributedText: {
                        AttributedText(titleAttributedString)
                    })

                    comparison("Markdown attributes", swiftUI: {
                        Text(markdown)
                    }, attributedText: {
                        AttributedText(markdown)
                    })

                    comparison("lineLimit", swiftUI: {
                        Text(longText)
                            .lineLimit(1)
                    }, attributedText: {
                        AttributedText(AttributedString(longText))
                            .lineLimit(1)
                    })

                    comparison("Attachment", swiftUI: {
                        Text("Attachment is not supported by plain SwiftUI.Text")
                            .font(.footnote)
                    }, attributedText: {
                        AttributedText(imageAttributedString)
                    })
                }
                .padding(.vertical)
            }
            .navigationTitle("Text Comparison")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private func comparison<SwiftUIView: View, AttributedUIView: View>(
        _ title: String,
        @ViewBuilder swiftUI: () -> SwiftUIView,
        @ViewBuilder attributedText: () -> AttributedUIView
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.semibold))

            sample("SwiftUI.Text", content: { swiftUI() })
            sample("AttributedText", content: { attributedText() })
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
    }

    @ViewBuilder
    private func sample<Content: View>(_ title: String, @ViewBuilder content: () -> Content)
        -> some View
    {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var markdown: AttributedString {
        var value = try! AttributedString(
            markdown: "**Markdown** is *easy* syntax. [Link](https://apple.com)",
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )
        value.font = UIFont.preferredFont(forTextStyle: .body)
        value.foregroundColor = UIColor.label
        return value
    }

    private var imageAttributedString: AttributedString {
        let attachment = NSTextAttachment(image: .actions)
        let value = NSMutableAttributedString(attachment: attachment)
        value.append(NSAttributedString(" Image attachment"))
        var attributedString = AttributedString(value)
        attributedString.font = UIFont.preferredFont(forTextStyle: .body)
        attributedString.foregroundColor = UIColor.label
        return attributedString
    }

    private var titleAttributedString: AttributedString {
        var attributedString = AttributedString("Title 2 / Bold")
        attributedString.font = UIFont.systemFont(
            ofSize: UIFont.preferredFont(forTextStyle: .title2).pointSize,
            weight: .bold
        )
        return attributedString
    }

    private let multilineText = "The quick brown fox jumps over the lazy dog.\n日本語の表示も比較します。"
    private let longText = "This is a long text used to compare tail truncation behavior in both views."
}
