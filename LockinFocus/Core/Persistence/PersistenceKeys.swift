import Foundation

/// 저장소 키 상수. `AppGroup.swift` 의 `SharedKeys` 와 분리한 이유:
/// Extension 이 `[[String: Any]]` 원시 포맷으로 쓰는 "interceptQueue" 와
/// 메인 앱이 Codable 로 보관하는 큐를 **다른 키** 로 분리 저장하여
/// 디코딩 충돌을 방지한다.
enum PersistenceKeys {
    /// Extension 이 쓰는 원시 큐 (key: `interceptQueue`, value: `[[String: Any]]`).
    /// `ShieldActionExtensionHandler.enqueue` 와 **정확히 일치해야 한다**.
    static let rawInterceptQueue = "interceptQueue"

    /// 메인 앱이 Codable 로 보관하는 누적 큐 (drain 후 남겨두거나 재소비용).
    static let codableInterceptQueue = "interceptQueueCodable"

    /// 스케줄 전체 (`Schedule` Codable).
    static let schedule = "schedule"

    /// 온보딩 완료 플래그.
    static let hasCompletedOnboarding = "hasCompletedOnboarding"

    /// 사용자가 수동으로 활성화한 "지금 집중 중" 플래그.
    /// 스케줄과 독립적으로 동작한다 — 둘 중 하나만 true 여도 shield 가 유지되도록 UI 에서 해석.
    static let isManualFocusActive = "isManualFocusActive"

    /// 지연 해제 점증: 오늘 "그래도 열기" 누른 횟수. 자정에 리셋.
    static let todayUnlockCount = "todayUnlockCount"

    /// 지연 해제 점증: 마지막 기록 날짜(`yyyy-MM-dd`). 날짜가 바뀌면 count 를 리셋.
    static let todayUnlockDateKey = "todayUnlockDate"

    /// 집중 점수 리셋용 날짜 키. focusScoreToday 저장 시 함께 기록.
    static let focusScoreDateKey = "focusScoreDate"

    /// 엄격 모드 활성 여부. ON 시 해제는 Friction 절차(30초+문장+Face ID) 거쳐야 함.
    static let isStrictModeActive = "isStrictModeActive"

    /// 최근 집중 기록(`[DailyFocus]` Codable). 주간 리포트 원천 데이터.
    static let dailyFocusHistory = "dailyFocusHistory"

    /// 주간 리포트 알림 ON/OFF (기본 true).
    static let weeklyReportNotification = "weeklyReportNotification"

    /// 획득한 뱃지 id 목록 (`[String]` 으로 저장, 내부에선 Set 처럼 다룸).
    static let earnedBadges = "earnedBadges"

    /// 누적 집계 (뱃지 판정용).
    static let totalReturnCount = "totalReturnCount"
    static let totalStrictSurvived = "totalStrictSurvived"
}
