import Foundation
import SwiftUI

extension EnvironmentValues {
    @Entry
    public var lineBreakMode: NSLineBreakMode? = nil
}

extension View {
    @ViewBuilder
    public func lineBreakMode(_ mode: NSLineBreakMode?) -> some View {
        environment(\.lineBreakMode, mode)
    }
}

extension EnvironmentValues {
    @Entry
    public var uiFont: UIFont =  .preferredFont(forTextStyle: .body)
}

extension View {
    @ViewBuilder
    public func uiFont(_ font: UIFont) -> some View {
        environment(\.uiFont, font)
    }
}

extension EnvironmentValues {
    @Entry
    public var lineFragmentPadding: Double? = nil
}

extension View {
    @ViewBuilder
    func lineFragmentPadding(_ lineFragmentPadding: Double?) -> some View {
        environment(\.lineFragmentPadding, lineFragmentPadding)
    }
}

extension EnvironmentValues {
    @Entry
    public var uiforegroundColor: UIColor = .label
}

extension View {
    @ViewBuilder
    public func uiforegroundColor(_ uiforegroundColor: UIColor) -> some View {
        environment(\.uiforegroundColor, uiforegroundColor)
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

public typealias OnCopy = (AttributedString) -> Void

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
    public var onTapTextItemTagAction: OnTapTextItemTagAction? = nil
}

extension View {
    @ViewBuilder
    public func onTapTextItemTag(_ action: @escaping @Sendable (String) -> Void) -> some View {
        environment(\.onTapTextItemTagAction, OnTapTextItemTagAction(action: action))
    }
}

public struct OnTapTextItemTagAction: Sendable {
    let action: @Sendable (String) -> Void
    
    func callAsFunction(_ textItemTag: String) {
        action(textItemTag)
    }
}
