import Foundation
import SwiftUI

public struct TextViewSizeCacheKey: Sendable, Hashable {
    let width: Double
    let attributedStringHashValue: Int
    let numberOfLines: Int
}

public struct TextViewSizeCacheValue: Sendable {
    let width: Double
    let height: Double
}

public typealias TextViewSizeCache = AnyCache<TextViewSizeCacheKey, TextViewSizeCacheValue>

extension EnvironmentValues {
    @Entry
    public var textViewSizeCache: TextViewSizeCache = TextViewSizeCache(base: OnMemoryCache())
}
