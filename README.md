# AttributedText

`AttributedText` is a SwiftUI component that renders an `AttributedString` with an appearance close to SwiftUI's `Text`. It is built on top of `UITextView`, so it also supports rich text features such as links, text selection, and `NSTextAttachment`.

<p>
  <img src="https://github.com/noppefoxwolf/AttributedText/blob/main/.github/Screenshot1.png" width="300" alt="AttributedText example">
  <img src="https://github.com/noppefoxwolf/AttributedText/blob/main/.github/Screenshot2.jpeg" width="300" alt="AttributedText example">
</p>

## Requirements

- iOS 17.0+
- Swift 6.2+
- Xcode 26+

## Installation

Add the following URL to your project using Swift Package Manager:

```text
https://github.com/noppefoxwolf/AttributedText.git
```

## Usage

```swift
import AttributedText
import SwiftUI

struct ContentView: View {
    var body: some View {
        AttributedText(message)
            .font(.body)
            .lineLimit(3)
            .truncationMode(.tail)
            .multilineTextAlignment(.leading)
    }

    private var message: AttributedString {
        var value = try! AttributedString(
            markdown: "**AttributedText** supports [links](https://apple.com)."
        )
        value.foregroundColor = .label
        return value
    }
}
```

For plain text, you can also use an `AttributedString` string literal:

```swift
AttributedText(AttributedString("Hello, World!"))
```

## SwiftUI.Text-compatible modifiers

The following SwiftUI text modifiers are supported:

- `font(_:)`
- `bold()`
- `lineLimit(_:)`
- `truncationMode(_:)`
- `multilineTextAlignment(_:)`

When `lineLimit` is not specified, text wraps across multiple lines. `truncationMode` is applied when used together with `lineLimit`.
`lineSpacing(_:)` and `textCase(_:)` are not applied because they require modifying the rendered `AttributedString`.

## Rich text and selection

Attributes in an `AttributedString` and `NSTextAttachment` values are preserved when rendered.

```swift
let attachment = NSTextAttachment(image: UIImage(systemName: "star")!)
let value = AttributedString(NSAttributedString(attachment: attachment))

AttributedText(value)
    .allowsSelectionTextItems([.link, .textAttachment])
```

The following text item types can be enabled for selection:

- `.link`
- `.textAttachment`
- `.tag`

## Actions

You can configure link and tag taps, copy handling, and additional edit menu actions.

```swift
AttributedText(message)
    .onTapTextItemTag { tag in
        print("Tapped tag: \(tag)")
    }
    .onCopy { copiedText in
        print(copiedText)
    }
    .extraActions([
        UIAction(title: "Custom Action") { _ in
            // Handle the action.
        }
    ])
```

Links are handled through SwiftUI's `openURL` environment value.

## Example

`Example.swiftpm` contains a comparison screen that displays SwiftUI `Text` and `AttributedText` with the same modifiers side by side.

```bash
open Example.swiftpm
```

## Test

```bash
xcodebuild -scheme AttributedText \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=27.0' \
  test
```

## Performance and layout regression checks

`PerformanceLab/AttributedTextPerformance.xcodeproj` is a standalone iOS app and
XCTest target that renders 200 dynamic rich-text rows. It records clock, CPU, and
memory metrics for first layout and content updates, and checks the visible
`UITextView` count and heights against `PerformanceBaselines/layout.json`.

Run the complete XCTest plus Instruments Time Profiler workflow with a signed,
connected iPhone. The command retains the simulator XCTest metrics and records
the Time Profiler trace on the iPhone. Provide the device name shown by
`xcrun xctrace list devices`:

```bash
PERFORMANCE_INSTRUMENTS_DEVICE_NAME='My iPhone' Scripts/run-performance.sh
```

Set `INSTRUMENTS_DURATION=30` (or `30s`) to change the recording duration.

It stores the `.xcresult`, XCTest metric JSON, `.trace`, and the Instruments table
of contents under `PerformanceResults/`. It fails if Instruments cannot export a
complete trace, so CI cannot mistake a partial recording for a pass.

Compare two exported XCTest metric files with a 10% regression threshold (or pass
another threshold as the third argument):

```bash
Scripts/compare-performance.py baseline/xctest-metrics.json candidate/xctest-metrics.json 10
```

After an intentional visual/layout change, regenerate the layout baseline on a
simulator before committing it:

```bash
UPDATE_LAYOUT_BASELINE=1 xcodebuild test \
  -project PerformanceLab/AttributedTextPerformance.xcodeproj \
  -scheme AttributedTextPerformance \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## License

MIT
