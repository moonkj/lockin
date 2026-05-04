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

    // MARK: - Array / Dictionary JSON helpers (친구 sync 용)

    func testStringArray_setThenGet_roundTrip() {
        let arr = ["F1", "F2", "F3"]
        ICloudKeyValueStore.setStringArray(arr, for: testKey)
        XCTAssertEqual(ICloudKeyValueStore.stringArray(for: testKey), arr)
    }

    func testStringArray_empty_treatedAsRemoval() {
        ICloudKeyValueStore.setStringArray(["F1"], for: testKey)
        ICloudKeyValueStore.setStringArray([], for: testKey)
        XCTAssertNil(ICloudKeyValueStore.stringArray(for: testKey))
    }

    func testStringArray_nil_removes() {
        ICloudKeyValueStore.setStringArray(["F1"], for: testKey)
        ICloudKeyValueStore.setStringArray(nil, for: testKey)
        XCTAssertNil(ICloudKeyValueStore.stringArray(for: testKey))
    }

    func testStringArray_invalidJSON_returnsNil() {
        // 다른 코드가 KV 에 raw string 으로 set 했을 때 array 디코드는 nil 반환.
        ICloudKeyValueStore.set("not-a-json-array", for: testKey)
        XCTAssertNil(ICloudKeyValueStore.stringArray(for: testKey))
    }

    func testStringDictionary_setThenGet_roundTrip() {
        let dict = ["F1": "친구하나", "F2": "친구둘"]
        ICloudKeyValueStore.setStringDictionary(dict, for: testKey)
        XCTAssertEqual(ICloudKeyValueStore.stringDictionary(for: testKey), dict)
    }

    func testStringDictionary_empty_treatedAsRemoval() {
        ICloudKeyValueStore.setStringDictionary(["F1": "이름"], for: testKey)
        ICloudKeyValueStore.setStringDictionary([:], for: testKey)
        XCTAssertNil(ICloudKeyValueStore.stringDictionary(for: testKey))
    }

    func testSynchronize_doesNotCrash() {
        _ = ICloudKeyValueStore.synchronize()
    }
}
