# UIHostingConfiguration reuse in timeline cells

A collection view cell and the SwiftUI hierarchy it hosts have separate lifetimes. While the host survives and SwiftUI preserves a representable's identity, SwiftUI can call `updateUIView` on the existing UIKit view. When a representable begins a new lifetime in that hierarchy, SwiftUI calls `makeCoordinator` and `makeUIView`. [SwiftUI view identity and lifetime](https://developer.apple.com/videos/play/wwdc2021/10022/) · [UIViewRepresentable](https://developer.apple.com/documentation/swiftui/uiviewrepresentable)

## UIKit's content configuration contract

When you assign a compatible configuration to a `UICollectionViewCell`, UIKit can apply it to the existing `contentView`. An incompatible configuration creates a replacement content view. Setting `contentConfiguration` back to `nil` replaces the configured content view with an empty one. The lifetime of the individual SwiftUI views inside a retained host is an implementation detail. [UICollectionViewCell.contentConfiguration](https://developer.apple.com/documentation/uikit/uicollectionviewcell/contentconfiguration-1lcqh)

## Observed on iOS 27.2

[UIKitBehaviorTests](../PerformanceLab/AttributedTextPerformanceTests/UIKitBehaviorTests.swift) uses a `UILabel` wrapped in a `UIViewRepresentable` to track view identity, coordinator identity, and `updateUIView` calls during collection view scrolling.

| Operation | Observed result |
| --- | --- |
| Edit the `@Observable` model for the post that is currently visible | The cell, label, and coordinator kept their identities. `updateUIView` ran and the label showed the edited text. |
| Reassign the same cell to a different post after clearing `contentConfiguration` in `prepareForReuse()` | SwiftUI created a new label and coordinator, and the label showed the new post. |
| Reassign the same cell to a different post with the old configuration still installed at reuse | Assigning the new configuration left the same label and coordinator in place. After a 300 ms wait, the label still showed the previous post and the `updateUIView` count was unchanged. |
| Replace the entire `Post` struct, including its ID, in the cell's `@Observable` model while the cell stays visible | The existing host, label, and coordinator were retained. `updateUIView` ran and displayed the replacement post. |
| Replace that same model's `Post` struct from `cellForItemAt` after UIKit dequeues the cell for a different post | The existing host, label, and coordinator were retained. After 300 ms, the label still showed the previous post and the `updateUIView` count was unchanged. |

The cases that showed stale text are recorded in the XCTest result bundle. Those results describe this simulator run and may vary with the OS or the hosting configuration.

## AttributedText sizing

A separate AttributedText timeline experiment cleared `contentConfiguration` during cell reuse. After scrolling away and returning to the first post, the cell, `UITextView`, and coordinator were different instances. The post returned with the same height. The shared measurement cache recorded two hits during the return, and the measurement count for that post stayed at one.

The [measurement cache](../Sources/AttributedText/AttributedText.swift) is shared across views. That lets a recreated view reuse a measurement when its cache key still matches. The experiment also included SwiftUI Dynamic Type size in the cache key.

## Run the lifecycle tests

Use an installed iOS simulator in the destination argument.

```bash
xcodebuild test \
  -project PerformanceLab/AttributedTextPerformance.xcodeproj \
  -scheme AttributedTextPerformance \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.2' \
  -only-testing:AttributedTextPerformanceTests/UIKitBehaviorTests
```
