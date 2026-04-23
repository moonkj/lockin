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
}
