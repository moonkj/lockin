import XCTest
@testable import LockinFocus

/// NSUbiquitousKeyValueStore wrapper smoke test.
/// CI / 시뮬레이터 환경에선 iCloud 동기화가 안 일어나지만, set/get/remove round-trip 은 검증 가능.
final class ICloudKeyValueStoreTests: XCTestCase {

    private let testKey = "test.kv.roundtrip"

    override func setUp() {
        super.setUp()
        ICloudKeyValueStore.set(nil, for: testKey)
    }

    override func tearDown() {
        ICloudKeyValueStore.set(nil, for: testKey)
        super.tearDown()
    }

    func testSet_thenGet_roundTrip() {
        ICloudKeyValueStore.set("hello", for: testKey)
        XCTAssertEqual(ICloudKeyValueStore.string(for: testKey), "hello")
    }

    func testSet_nil_removesValue() {
        ICloudKeyValueStore.set("hello", for: testKey)
        ICloudKeyValueStore.set(nil, for: testKey)
        XCTAssertNil(ICloudKeyValueStore.string(for: testKey))
    }

    func testSet_empty_treatedAsRemoval() {
        ICloudKeyValueStore.set("hello", for: testKey)
        ICloudKeyValueStore.set("", for: testKey)
        XCTAssertNil(ICloudKeyValueStore.string(for: testKey))
    }

    func testSynchronize_doesNotCrash() {
        _ = ICloudKeyValueStore.synchronize()
    }
}
