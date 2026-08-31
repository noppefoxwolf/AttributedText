public import SwiftUI
public import AttributedTextView
import UIKit

public struct OnTapTextItemTagAction: Sendable {
    private let action: (@MainActor @Sendable (String) -> Void)?

    public init(action: (@MainActor @Sendable (String) -> Void)? = nil) {
        self.action = action
    }

    @MainActor
    public func callAsFunction(_ textItemTag: String) {
        action?(textItemTag)
    }

    var isEmpty: Bool {
        action == nil
    }
}

extension EnvironmentValues {
    @Entry
    public var onTapTextItemTagAction = OnTapTextItemTagAction()
}

extension View {
    @ViewBuilder
    public func onTapTextItemTag(
        _ action: @escaping @MainActor @Sendable (String) -> Void
    ) -> some View {
        environment(\.onTapTextItemTagAction, OnTapTextItemTagAction(action: action))
    }
}

public struct OnCopy: Sendable {
    private let action: (@Sendable (AttributedString) -> Void)?

    public init(action: (@Sendable (AttributedString) -> Void)? = nil) {
        self.action = action
    }

    public func callAsFunction(_ attributedString: AttributedString) {
        action?(attributedString)
    }

    var isEmpty: Bool {
        action == nil
    }
}

extension EnvironmentValues {
    @Entry
    public var onCopy = OnCopy()
}

extension View {
    @ViewBuilder
    public func onCopy(_ action: @escaping @Sendable (AttributedString) -> Void) -> some View {
        environment(\.onCopy, OnCopy(action: action))
    }
}

extension EnvironmentValues {
    @Entry
    public var extraActions: [UIAction] = []
}

extension View {
    @ViewBuilder
    public func extraActions(_ extraActions: [UIAction]) -> some View {
        environment(\.extraActions, extraActions)
    }
}

extension EnvironmentValues {
    @Entry
    public var allowsSelectionTextItems: [TextItemType] = TextItemType.allCases
}

extension View {
    @ViewBuilder
    public func allowsSelectionTextItems(_ types: [TextItemType] = TextItemType.allCases)
        -> some View
    {
        environment(\.allowsSelectionTextItems, types)
    }
}
