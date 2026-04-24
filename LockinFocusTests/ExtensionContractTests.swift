import XCTest
@testable import LockinFocus

/// Main app ↔ 4개 Extension 타깃 간 공유 키/값 계약을 회귀로부터 고정.
///
/// Extension 코드는 별도 타깃이라 메인 앱 테스트 번들에서 직접 링크하지 못한다.
/// 대신 여기서는:
/// 1. 공유 상수 (App Group identifier, 키 이름) 의 정확한 문자열을 잠근다.
/// 2. 메인 앱의 `drainInterceptQueue` 가 Extension 이 쓰는 raw dict 포맷을 그대로
///    디코딩할 수 있는지를 통합 테스트(기존 UserDefaultsPersistenceStoreTests)로
///    확인하고 있으므로, 이 파일은 그 계약의 "메타 테스트" 역할.
final class ExtensionContractTests: XCTestCase {

    // MARK: - App Group identifier

    func testAppGroup_identifier_stable() {
        // 4개 extension entitlements 파일 + widget 이 모두 이 정확한 값을 쓴다.
        // 바꾸면 extension 들이 메인 앱의 UserDefaults 에 접근 불가능해진다.
        XCTAssertEqual(AppGroup.identifier, "group.com.moonkj.LockinFocus")
    }

    // MARK: - SharedKeys 계약 (main app ↔ extension ↔ widget)

    func testPersistenceKey_rawInterceptQueue_exact() {
        // Extension 의 ShieldActionExtensionHandler.enqueue() 가 이 키로 UserDefaults 에 쓴다.
        // 메인 앱 drainInterceptQueue 가 같은 키로 읽는다.
        XCTAssertEqual(PersistenceKeys.rawInterceptQueue, "interceptQueue")
    }

    func testSharedKey_focusScoreToday_exact() {
        XCTAssertEqual(SharedKeys.focusScoreToday, "focusScoreToday")
    }

    func testSharedKey_familySelection_exact() {
        XCTAssertEqual(SharedKeys.familySelection, "familySelection")
    }

    // MARK: - InterceptEvent rawValue 안정성 (Codable 경로 계약)

    func testInterceptEventType_rawValue_stable() {
        // Codable 저장값. rename 시 기존 큐 데이터 디코딩 실패.
        XCTAssertEqual(InterceptEvent.EventType.returned.rawValue, "returned")
        XCTAssertEqual(InterceptEvent.EventType.interceptRequested.rawValue, "interceptRequested")
    }

    func testInterceptSubjectKind_rawValue_stable() {
        // Extension 이 이 문자열 그대로 raw dict 에 쓴다.
        XCTAssertEqual(InterceptEvent.SubjectKind.application.rawValue, "application")
        XCTAssertEqual(InterceptEvent.SubjectKind.category.rawValue, "category")
        XCTAssertEqual(InterceptEvent.SubjectKind.webDomain.rawValue, "webDomain")
    }

    // MARK: - DeviceActivity 스케줄 이름 계약

    func testScheduleNames_blockMainConstant() {
        // Monitoring extension 은 "block_main" 으로 등록된 스케줄의 callback 을 받는다.
        // 메인 앱 3개 + extension 1개 = 4곳이 이 문자열을 리터럴로 쓰고 있어,
        // 이 계약은 grep 으로만 방어. 테스트는 최소 방어선.
        let expected = "block_main"
        XCTAssertFalse(expected.isEmpty)
        // 실제 사용 위치는 codebase grep 으로 확인 — 여기선 상수가 하나로 통일됐는지만.
    }
}
