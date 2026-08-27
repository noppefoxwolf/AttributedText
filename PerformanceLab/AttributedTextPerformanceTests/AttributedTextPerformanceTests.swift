import AttributedText
import SwiftUI
import XCTest

final class AttributedTextPerformanceTests: XCTestCase {
    @MainActor
    func testInitialLayoutPerformance() {
        measure(metrics: [XCTClockMetric(), XCTCPUMetric(), XCTMemoryMetric()]) {
            let host = UIHostingController(rootView: benchmarkView(contentTick: 0, parentUpdateTick: 0))
            let window = attach(host)
            XCTAssertGreaterThan(host.view.bounds.height, 0)
            withExtendedLifetime(window) {}
        }
    }

    @MainActor
    func testRepeatedContentUpdatePerformance() {
        let host = UIHostingController(rootView: benchmarkView(contentTick: 0, parentUpdateTick: 0))
        host.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        measure(metrics: [XCTClockMetric(), XCTCPUMetric(), XCTMemoryMetric()]) {
            host.rootView = benchmarkView(
                contentTick: Int.random(in: 1...Int.max),
                parentUpdateTick: 0
            )
            host.view.setNeedsLayout()
            host.view.layoutIfNeeded()
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
    }

    @MainActor
    func testRepeatedUnchangedContentUpdatePerformance() {
        let host = UIHostingController(rootView: benchmarkView(contentTick: 0, parentUpdateTick: 0))
        host.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        measure(metrics: [XCTClockMetric(), XCTCPUMetric(), XCTMemoryMetric()]) {
            host.rootView = benchmarkView(
                contentTick: 0,
                parentUpdateTick: Int.random(in: 1...Int.max)
            )
            host.view.setNeedsLayout()
            host.view.layoutIfNeeded()
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
    }

    @MainActor
    func testLayoutRegression() throws {
        let host = UIHostingController(rootView: benchmarkView(contentTick: 0, parentUpdateTick: 0))
        let window = attach(host)

        let textViews = descendants(of: host.view).compactMap { $0 as? UITextView }
        XCTAssertGreaterThan(textViews.count, 0, "The benchmark did not render any UITextView instances")
        let snapshot = LayoutSnapshot(
            width: host.view.bounds.width,
            textViewCount: textViews.count,
            textViewHeights: textViews.prefix(10).map { ($0.bounds.height * 10).rounded() / 10 }
        )
        try LayoutBaseline.verify(snapshot)
        withExtendedLifetime(window) {}
    }

    @MainActor
    private func benchmarkView(contentTick: Int, parentUpdateTick: Int) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                ForEach(0..<200, id: \.self) { index in
                    AttributedText(self.message(index: index, tick: contentTick))
                        .font(.body)
                        .lineSpacing(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(16)
        }
        .accessibilityValue(parentUpdateTick.formatted())
    }

    @MainActor
    private func descendants(of view: UIView) -> [UIView] {
        [view] + view.subviews.flatMap(descendants(of:))
    }

    @MainActor
    private func attach<Content: View>(_ host: UIHostingController<Content>) -> UIWindow {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = host
        window.isHidden = false
        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()
        RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        return window
    }

    private func message(index: Int, tick: Int) -> AttributedString {
        var message = AttributedString(
            "Row \(index) / revision \(tick): AttributedText renders mixed English and 日本語 text. " +
            "This deliberately long line exercises wrapping, paragraph attributes, and repeated layout."
        )
        message.foregroundColor = .label
        return message
    }
}

private struct LayoutSnapshot: Codable, Equatable {
    let width: CGFloat
    let textViewCount: Int
    let textViewHeights: [CGFloat]
}

private enum LayoutBaseline {
    static func verify(_ actual: LayoutSnapshot) throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "PerformanceBaselines/layout.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        if ProcessInfo.processInfo.environment["UPDATE_LAYOUT_BASELINE"] == "1" {
            try encoder.encode(actual).write(to: url, options: .atomic)
            return
        }

        let expected = try JSONDecoder().decode(LayoutSnapshot.self, from: Data(contentsOf: url))
        // A fresh clone contains this sentinel. Subsequent runs are strict unless the
        // baseline is deliberately regenerated with UPDATE_LAYOUT_BASELINE=1.
        if expected.textViewCount == 0 && expected.textViewHeights.isEmpty {
            try encoder.encode(actual).write(to: url, options: .atomic)
            return
        }
        XCTAssertEqual(actual.textViewCount, expected.textViewCount, "UITextView count changed")
        XCTAssertEqual(actual.textViewHeights, expected.textViewHeights, "Text layout heights changed")
        XCTAssertEqual(actual.width, expected.width, accuracy: 0.1)
    }
}
