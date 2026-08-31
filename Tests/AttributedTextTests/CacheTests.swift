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
            textAlignment: .left
        )
        let size = CGSize(width: 123, height: 45)

        #expect(cache.get(key) == nil)
        cache.set(key, size: size)
        #expect(cache.get(key) == size)
    }

    @Test
    func cacheEvictsTheLeastRecentlyUsedValueAtCapacity() {
        let cache = Cache(capacity: 2)
        let first = key(for: "First")
        let second = key(for: "Second")
        let third = key(for: "Third")

        cache.set(first, size: CGSize(width: 1, height: 1))
        cache.set(second, size: CGSize(width: 2, height: 2))
        _ = cache.get(first)
        cache.set(third, size: CGSize(width: 3, height: 3))

        #expect(cache.get(first) != nil)
        #expect(cache.get(second) == nil)
        #expect(cache.get(third) != nil)
    }

    private func key(for text: String) -> Cache.Key {
        Cache.Key(
            attributedString: AttributedString(text),
            targetSize: CGSize(width: 200, height: UIView.noIntrinsicMetric),
            font: .body,
            maximumNumberOfLines: 0,
            lineBreakMode: .byWordWrapping,
            textAlignment: .left
        )
    }
}
