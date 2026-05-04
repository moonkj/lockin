import XCTest
@testable import LockinFocus

/// `InterceptEvent` 의 Codable 안정성과 enum rawValue 계약을 고정한다.
///
/// **중요**: 여기서 검증하는 rawValue 문자열은 `ShieldActionExtensionHandler` 의
/// `enqueue(type:subjectKind:)` 가 App Group `UserDefaults` 에 쓰는 문자열과
/// 같은 값이다. 이 rawValue 를 변경하면 Extension ↔ 메인 앱 큐 호환성이
/// 깨져 H1 회귀가 재발한다. **절대 변경 금지** (Debugger Report H1 참조).
final class InterceptEventTests: XCTestCase {

    // JSON 직렬화 왕복 안정성. Codable 준수 여부 회귀 감지.
    func testCodableRoundTrip() throws {
        let event = InterceptEvent(
            timestamp: Date(timeIntervalSince1970: 1_714_000_000),
            type: .interceptRequested,
            subjectKind: .application
        )

        let data = try JSONEncoder().encode(event)
        let decoded = try JSONDecoder().decode(InterceptEvent.self, from: data)

        XCTAssertEqual(decoded.type, .interceptRequested)
        XCTAssertEqual(decoded.subjectKind, .application)
        XCTAssertEqual(decoded.timestamp.timeIntervalSince1970, 1_714_000_000, accuracy: 0.001)
    }

    // Extension 이 문자열로 쓰는 raw value 가 우리 enum 값과 일치해야 한다.
    // 여기서 변경이 발생하면 Extension ↔ 앱 스키마 불일치 → 큐 drain 실패.
    func testRawValueStability_EventType() {
        XCTAssertEqual(InterceptEvent.EventType.returned.rawValue, "returned")
        XCTAssertEqual(InterceptEvent.EventType.interceptRequested.rawValue, "interceptRequested")
    }

    func testRawValueStability_SubjectKind() {
        XCTAssertEqual(InterceptEvent.SubjectKind.application.rawValue, "application")
        XCTAssertEqual(InterceptEvent.SubjectKind.category.rawValue, "category")
        XCTAssertEqual(InterceptEvent.SubjectKind.webDomain.rawValue, "webDomain")
    }

    // Extension 은 `"intercept_requested"` 와 `"interceptRequested"` 두 문자열을
    // 모두 사용할 수 있다. 둘 다 `.interceptRequested` 로 매핑되도록
    // UserDefaultsPersistenceStore.mapType 이 유지되는지 간접 검증(계약 명시).
    // (실제 매핑 테스트는 UserDefaultsPersistenceStoreTests.swift 의 raw drain 에서 수행.)
    func testEventType_interceptRequested_exists() {
        // rawValue 를 컴파일 타임에 고정.
        let fromRaw = InterceptEvent.EventType(rawValue: "interceptRequested")
        XCTAssertEqual(fromRaw, .interceptRequested)
    }

    /// alreadyScored 는 hybrid 점수 (Extension 즉시 +5) 이후 추가된 필드. 이전 빌드가 쓴
    /// codable 큐엔 키가 누락되어 있을 수 있으므로 init(from:) 에서 decodeIfPresent 폴백.
    /// 본 테스트는 그 forward-compat 동작을 fixate.
    func testCodable_decodeWithoutAlreadyScoredField_fallsBackToFalse() throws {
        let legacyJSON = """
        {
            "id": "00000000-0000-0000-0000-000000000001",
            "timestamp": 770000000,
            "type": "returned",
            "subjectKind": "application"
        }
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(InterceptEvent.self, from: legacyJSON)
        XCTAssertEqual(decoded.type, .returned)
        XCTAssertEqual(decoded.subjectKind, .application)
        XCTAssertFalse(decoded.alreadyScored, "키 누락 시 false 폴백")
    }

    /// 신규 빌드가 쓴 큐는 alreadyScored=true 를 정확히 보존.
    func testCodable_alreadyScoredTrue_preservedRoundTrip() throws {
        let original = InterceptEvent(
            type: .returned,
            subjectKind: .application,
            alreadyScored: true
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(InterceptEvent.self, from: data)
        XCTAssertTrue(decoded.alreadyScored)
    }
}
