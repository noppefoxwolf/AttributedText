import Foundation

public protocol Cache: AnyObject, Sendable {
    associatedtype Key: Sendable & Hashable
    associatedtype Value: Sendable
    
    subscript(key: Key) -> Value? { get set }
    var keys: Set<Key> { get }
}

public final class AnyCache<Key: Sendable & Hashable, Value: Sendable>: Cache, Sendable {
    let keysGetter: @Sendable () -> Set<Key>
    let getter: @Sendable (Key) -> Value?
    let setter: @Sendable (Key, Value?) -> Void
    
    public init<T>(base: T) where T: Cache, T.Key == Key, T.Value == Value {
        keysGetter = { base.keys }
        getter = { base[$0] }
        setter = { base[$0] = $1 }
    }
    
    public var keys: Set<Key> { keysGetter() }
    
    public subscript(key: Key) -> Value? {
        get { getter(key) }
        set { setter(key, newValue) }
    }
}

final class OnMemoryCache<Key: Sendable & Hashable, Value: Sendable>: Cache, @unchecked Sendable {
    var keys: Set<Key> {
        queue.sync {
            Set(cache.keys)
        }
    }
    
    let queue = DispatchQueue(label: "queue", attributes: .concurrent)
    
    var cache: [Key : Value] = [:]
    
    subscript(key: Key) -> Value? {
        get {
            queue.sync {
                cache[key]
            }
        }
        set {
            queue.async(flags: .barrier) {
                self.cache[key] = newValue
            }
        }
    }
}
