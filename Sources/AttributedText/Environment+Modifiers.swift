import SwiftUI
import UIKit

public typealias OnTapTextItemTagAction = @Sendable (String) -> Void

extension EnvironmentValues {
    @Entry
    public var onTapTextItemTagAction: OnTapTextItemTagAction? = nil
}

extension View {
    @ViewBuilder
    public func onTapTextItemTag(_ action: @escaping OnTapTextItemTagAction) -> some View {
        environment(\.onTapTextItemTagAction, action)
    }
}

public typealias OnCopy = @Sendable (AttributedString) -> Void

extension EnvironmentValues {
    @Entry
    public var onCopy: OnCopy? = nil
}

extension View {
    @ViewBuilder
    public func onCopy(_ action: @escaping OnCopy) -> some View {
        environment(\.onCopy, action)
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

public enum TextItemType: Sendable, CaseIterable {
    case link
    case textAttachment
    case tag
}

extension EnvironmentValues {
    @Entry
    public var allowsSelectionTextItems: [TextItemType] = TextItemType.allCases
}

extension View {
    @ViewBuilder
    public func allowsSelectionTextItems(_ types: [TextItemType] = TextItemType.allCases) -> some View {
        environment(\.allowsSelectionTextItems, types)
    }
}
