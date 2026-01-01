import Foundation
import os

struct TextViewSizeCacheRetriever: Sendable {
    let cache: TextViewSizeCache
    let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: #file
    )
    
    func sizeThatFits(_ key: TextViewSizeCacheKey) -> TextViewSizeCacheValue? {
        // 1. 一致する
        if let size = cache[key] {
            return size
        }
        let equalTypographyCacheKeys = cache.keys.filter { $0.isEqualTypography(to: key) }
        let intrinsicContentSizeCacheKey = equalTypographyCacheKeys.first(where: { $0.width == 0 })
        
        // 2. intrinsicContentSizeのキャッシュがある場合、key.widthより小さいなら採用する
        if let intrinsicContentSizeCacheKey, let size = cache[intrinsicContentSizeCacheKey] {
            if size.width.rounded(.down) <= key.width {
                return size
            }
        }
        // 3. 1行の場合、すでにkey.widthより小さいキャッシュがあるなら採用する
        if key.numberOfLines == 1, let nearestCacheKey = equalTypographyCacheKeys.first(where: { $0.width < key.width }) {
            if nearestCacheKey.width <= key.width {
                return cache[nearestCacheKey]
            }
        }
        return nil
    }
}

extension TextViewSizeCacheKey {
    func isEqualTypography(to other: TextViewSizeCacheKey) -> Bool {
        other.attributedStringHashValue == attributedStringHashValue && other.numberOfLines == numberOfLines
    }
}
