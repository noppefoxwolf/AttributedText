import SwiftUI
import Testing
import UIKit

@testable import AttributedText

@Suite
@MainActor
struct CacheTests {
    @Test
    func cacheReturnsStoredSize() {
        let cache = Cache()
        let key = Cache.Key(
            attributedString: AttributedString("Text"),
            targetSize: CGSize(width: 200, height: UIView.noIntrinsicMetric),
            font: .body,
            maximumNumberOfLines: 0,
            lineBreakMode: .byWordWrapping,
            textAlignment: .left,
            lineSpacing: 0,
            textCase: nil
        )
        let size = CGSize(width: 123, height: 45)

        #expect(cache.get(key) == nil)
        cache.set(key, size: size)
        #expect(cache.get(key) == size)
    }
}
