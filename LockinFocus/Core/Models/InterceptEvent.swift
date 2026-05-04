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
    /// Extension (`ShieldActionExtension`) 이 큐에 적재할 시점에 이미 +5 점수를 부여했음을
    /// 표시. 메인 앱은 InterceptView 의 "돌아가기" 핸들러에서 이 플래그가 true 면
    /// `awardReturnPoint()` 를 호출하지 않아 이중 지급을 막는다. 메인 앱 자체가 만든
    /// 이벤트 (`InterceptEvent(type: .returned, ...)`) 는 기본 false → 메인 앱 경로는
    /// 종전과 동일하게 점수 적용.
    let alreadyScored: Bool

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        type: EventType,
        subjectKind: SubjectKind,
        alreadyScored: Bool = false
    ) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.subjectKind = subjectKind
        self.alreadyScored = alreadyScored
    }

    /// 새 필드 `alreadyScored` 추가에 대한 forward-compat: 이전 버전이 쓴 codable 큐엔 이
    /// 키가 없을 수 있으므로 누락 시 false 로 폴백. 새 빌드 → 이전 빌드 시나리오는 발생하지
    /// 않지만 (App Store 업데이트는 단방향), 동일 빌드의 큐 누적도 안전하게 디코딩됨.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(UUID.self, forKey: .id)
        self.timestamp = try c.decode(Date.self, forKey: .timestamp)
        self.type = try c.decode(EventType.self, forKey: .type)
        self.subjectKind = try c.decode(SubjectKind.self, forKey: .subjectKind)
        self.alreadyScored = try c.decodeIfPresent(Bool.self, forKey: .alreadyScored) ?? false
    }
}
