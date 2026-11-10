import UIKit

@MainActor
final class Cache: Sendable {
    static let shared = Cache()
    private let capacity: Int
    private var storage: [Key: Entry] = [:]
    private var oldest: Entry?
    private var newest: Entry?

    init(capacity: Int = 1_024) {
        self.capacity = max(1, capacity)
    }

    struct Key: Hashable, Sendable {
        let attributedString: AttributedString
        let targetSize: CGSize
        let maximumNumberOfLines: Int
    }

    private final class Entry {
        let key: Key
        var size: CGSize
        weak var previous: Entry?
        var next: Entry?

        init(key: Key, size: CGSize) {
            self.key = key
            self.size = size
        }
    }

    func set(_ key: Key, size: CGSize) {
        if let entry = storage[key] {
            entry.size = size
            touch(entry)
            return
        }
        if storage.count == capacity, let entry = oldest {
            storage.removeValue(forKey: entry.key)
            oldest = entry.next
            oldest?.previous = nil
            if newest === entry { newest = nil }
            entry.next = nil
        }
        let entry = Entry(key: key, size: size)
        storage[key] = entry
        append(entry)
    }

    func get(_ key: Key) -> CGSize? {
        guard let entry = storage[key] else { return nil }
        touch(entry)
        return entry.size
    }

    private func touch(_ entry: Entry) {
        guard newest !== entry else { return }
        if let previous = entry.previous {
            previous.next = entry.next
        } else {
            oldest = entry.next
        }
        entry.next?.previous = entry.previous
        entry.previous = nil
        entry.next = nil
        append(entry)
    }

    private func append(_ entry: Entry) {
        entry.previous = newest
        newest?.next = entry
        if oldest == nil { oldest = entry }
        newest = entry
    }
}
