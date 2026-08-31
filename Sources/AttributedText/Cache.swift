import UIKit

@MainActor
final class Cache: Sendable {
    static let shared = Cache()
    private let capacity: Int
    private var storage: [Key: CGSize] = [:]
    private var leastRecentlyUsedKeys: [Key] = []

    init(capacity: Int = 1_024) {
        self.capacity = max(1, capacity)
    }

    struct Key: Hashable, Sendable {
        let attributedString: AttributedString
        let targetSize: CGSize
        let maximumNumberOfLines: Int
    }

    func set(_ key: Key, size: CGSize) {
        if storage[key] == nil, storage.count == capacity, let oldestKey = leastRecentlyUsedKeys.first {
            storage[oldestKey] = nil
            leastRecentlyUsedKeys.removeFirst()
        }
        storage[key] = size
        touch(key)
    }

    func get(_ key: Key) -> CGSize? {
        guard let size = storage[key] else { return nil }
        touch(key)
        return size
    }

    private func touch(_ key: Key) {
        if let index = leastRecentlyUsedKeys.firstIndex(of: key) {
            leastRecentlyUsedKeys.remove(at: index)
        }
        leastRecentlyUsedKeys.append(key)
    }
}
