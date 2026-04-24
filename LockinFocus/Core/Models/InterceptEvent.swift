import Foundation

/// Extension ↔ Main app 계약:
/// - Extension (ShieldActionExtensionHandler) 은 raw `[[String:Any]]` 로 enqueue.
///   Extension 쪽 문자열 리터럴: `"returned"` / `"intercept_requested"` (snake_case).
/// - Main app 은 `UserDefaultsPersistenceStore.drainInterceptQueue` 에서
///   snake_case / camelCase 양쪽을 `EventType.interceptRequested` 로 매핑한다.
/// - enum rawValue 는 Codable 경로(`codableInterceptQueue`) 용이라 camelCase 유지.
///   **rawValue 를 snake_case 로 바꾸면 기존 Codable 저장값이 디코딩 실패하므로 금지.**
struct InterceptEvent: Codable, Equatable, Identifiable {
    /// rawValue 는 camelCase. Extension 의 snake_case 문자열은 drain 시 수동 매핑.
    /// 회귀 방지: InterceptEventTests 의 `testRawValueStability_*` 가 두 경로를 모두 고정.
    enum EventType: String, Codable {
        case returned
        case interceptRequested
    }

    enum SubjectKind: String, Codable {
        case application
        case category
        case webDomain
    }

    let id: UUID
    let timestamp: Date
    let type: EventType
    let subjectKind: SubjectKind

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        type: EventType,
        subjectKind: SubjectKind
    ) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.subjectKind = subjectKind
    }
}
