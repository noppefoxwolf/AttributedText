import UIKit

@MainActor
final class Cache: Sendable {
    static let shared = Cache()
    private var storage: [Key: CGSize] = [:]

    struct Key: Hashable, Sendable {
        let attributedString: AttributedString
        let targetSize: CGSize
    }

    func set(_ key: Key, size: CGSize) {
        storage[key] = size
    }

    func get(_ key: Key) -> CGSize? {
        storage[key]
    }
}
