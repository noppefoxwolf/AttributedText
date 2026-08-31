import AttributedText
import SwiftUI
import UIKit

@main
struct AttributedTextPerformanceApp: App {
    var body: some Scene {
        WindowGroup {
            PerformanceScene()
        }
    }
}

private struct PerformanceScene: View {
    @State private var parentUpdateTick = 0

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                ForEach(0..<200, id: \.self) { index in
                    AttributedText(PerformanceFixtures.message(index: index))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier("performance.row.\(index)")
                }
            }
            .padding(16)
        }
        .accessibilityIdentifier("performance.scroll")
        .accessibilityValue(parentUpdateTick.formatted())
        .task {
            guard ProcessInfo.processInfo.arguments.contains("-performanceScenario") else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(250))
                parentUpdateTick &+= 1
            }
        }
    }
}

enum PerformanceFixtures {
    static func message(index: Int, tick: Int = 0) -> AttributedString {
        var message = AttributedString(
            "Row \(index) / revision \(tick): AttributedText renders mixed English and 日本語 text. " +
            "This deliberately long line exercises wrapping and repeated layout."
        )
        message.font = UIFont.preferredFont(forTextStyle: .body)
        message.foregroundColor = .label
        return message
    }
}
