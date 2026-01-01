import Testing
@testable import AttributedText
import Foundation

@Suite
struct TextViewSizeCacheRetrieverTests {
    @Test
    func noCache() async throws {
        let cache = TextViewSizeCache(base: OnMemoryCache())
        let retriever = TextViewSizeCacheRetriever(cache: cache)
        let key = TextViewSizeCacheKey(
            width: 0,
            attributedStringHashValue: 0,
            fontHashValue: 0,
            numberOfLines: 0
        )
        #expect(retriever.sizeThatFits(key) == nil)
    }
    
    @Test
    func hitCache() async throws {
        let cache = TextViewSizeCache(base: OnMemoryCache())
        let retriever = TextViewSizeCacheRetriever(cache: cache)
        let key = TextViewSizeCacheKey(
            width: 0,
            attributedStringHashValue: 0,
            fontHashValue: 0,
            numberOfLines: 0
        )
        cache[key] = CGSize(width: 123, height: 123)
        #expect(retriever.sizeThatFits(key) == CGSize(width: 123, height: 123))
    }
    
    @Test
    func hitIntrinsicCache() async throws {
        let cache = TextViewSizeCache(base: OnMemoryCache())
        let retriever = TextViewSizeCacheRetriever(cache: cache)
        let intrinsicKey = TextViewSizeCacheKey(
            width: 0,
            attributedStringHashValue: 0,
            fontHashValue: 0,
            numberOfLines: 0
        )
        cache[intrinsicKey] = CGSize(width: 123, height: 123)
        
        let key = TextViewSizeCacheKey(
            width: 200,
            attributedStringHashValue: 0,
            fontHashValue: 0,
            numberOfLines: 0
        )
        #expect(retriever.sizeThatFits(key) == CGSize(width: 123, height: 123))
    }
    
    @Test
    func hitSinglelineIntrinsicCache() async throws {
        let cache = TextViewSizeCache(base: OnMemoryCache())
        let retriever = TextViewSizeCacheRetriever(cache: cache)
        let intrinsicKey = TextViewSizeCacheKey(
            width: 200,
            attributedStringHashValue: 0,
            fontHashValue: 0,
            numberOfLines: 1
        )
        cache[intrinsicKey] = CGSize(width: 123, height: 123)
        
        let key = TextViewSizeCacheKey(
            width: 300,
            attributedStringHashValue: 0,
            fontHashValue: 0,
            numberOfLines: 1
        )
        #expect(retriever.sizeThatFits(key) == CGSize(width: 123, height: 123))
    }
}

