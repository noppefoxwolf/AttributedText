import SwiftUI
import UIKit

extension AttributedText {
    func resolvedFont(for font: Font?, in environment: EnvironmentValues) -> UIFont {
        guard let font else {
            return UIFont.preferredFont(forTextStyle: .body)
        }

        if #available(iOS 26.0, *) {
            let resolved = font.resolve(in: environment.fontResolutionContext)
            let descriptor = CTFontCopyFontDescriptor(resolved.ctFont) as UIFontDescriptor
            return UIFont(descriptor: descriptor, size: resolved.pointSize)
        }

        return UIFont.preferredFont(forTextStyle: font.uiTextStyle ?? .body)
    }
}

private extension Font {
    var uiTextStyle: UIFont.TextStyle? {
        switch self {
        case .largeTitle: .largeTitle
        case .title: .title1
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .subheadline: .subheadline
        case .body: .body
        case .callout: .callout
        case .footnote: .footnote
        case .caption: .caption1
        case .caption2: .caption2
        default: nil
        }
    }
}
