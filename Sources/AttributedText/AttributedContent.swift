import Foundation
import UIKit
import SwiftUI

struct RenderedContentConfiguration: Equatable {
    let attributedText: AttributedString
    let font: UIFont?
    let textCase: Text.Case?
    let textAlignment: NSTextAlignment
    let lineSpacing: CGFloat
}
