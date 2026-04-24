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

    /// 엄격 모드 종료 시각 (TimeInterval, 없으면 비활성).
    /// 이 시각이 지나기 전까지는 어떤 수단으로도 해제 불가.
    static let strictModeEndAt = "strictModeEndAt"

    /// 엄격 모드 시작 시점에 기록된 "시작 시각" — 사용자가 시스템 시간을
    /// 과거로 돌려 강제 만료를 회피하려는 시도를 탐지하는 기준점.
    /// 현재 시각이 start 보다 이전이면 시간이 조작됐다고 판정하고 end 를 그대로 유지.
    static let strictModeStartAt = "strictModeStartAt"

    /// 오늘 수동 집중을 종료한 횟수. 1회차는 더 강한 마찰(문장+비번), 2회차 30초, 3회차+ 60초 대기.
    static let focusEndCountToday = "focusEndCountToday"
    static let focusEndCountDateKey = "focusEndCountDate"

    /// 최근 집중 기록(`[DailyFocus]` Codable). 주간 리포트 원천 데이터.
    static let dailyFocusHistory = "dailyFocusHistory"

    /// 주간 리포트 알림 ON/OFF (기본 true).
    static let weeklyReportNotification = "weeklyReportNotification"

    /// 획득한 뱃지 id 목록 (`[String]` 으로 저장, 내부에선 Set 처럼 다룸).
    static let earnedBadges = "earnedBadges"

    /// 누적 집계 (뱃지 판정용).
    static let totalReturnCount = "totalReturnCount"
    static let totalStrictSurvived = "totalStrictSurvived"
    static let totalFocusSeconds = "totalFocusSeconds"
    static let totalManualFocusStarts = "totalManualFocusStarts"

    /// 점수 규칙 (B) 관련.
    static let lastReturnAt = "lastReturnAt"               // TimeInterval
    static let todayReturnPoints = "todayReturnPoints"     // Int, 자정 리셋
    static let manualFocusStartedAt = "manualFocusStartedAt" // TimeInterval?
    static let lastDailyLoginDate = "lastDailyLoginDate"   // yyyy-MM-dd

    /// 세션 보너스를 가장 최근에 지급한 날짜(`yyyy-MM-dd`). 같은 날 중복 지급 방지.
    /// 또한 앱 force-quit 후 오래된 startedAt 이 살아남아 재기동 시 보너스를 가로채는 exploit 방어.
    static let lastSessionBonusDate = "lastSessionBonusDate"

    /// CloudKit 랭킹용.
    static let nickname = "nickname"
    static let leaderboardUserID = "leaderboardUserID"

    /// 친구 userID 목록 (`[String]`). 그룹 랭킹 필터에 사용.
    static let friendUserIDs = "friendUserIDs"

    /// 친구 닉네임 캐시 (`[String: String]` userID → 최근 본 닉네임). 오프라인에서도 친구 라벨을 보여주기 위한 캐시.
    static let friendNicknameCache = "friendNicknameCache"

    /// 오늘 집중 목표 점수 (기본 80). 사용자가 Settings 에서 조정.
    static let focusGoalScore = "focusGoalScore"

    /// 비밀번호 입력 시 Face ID / Touch ID 로 대체 허용. 기본 off (사용자 opt-in).
    static let useBiometricForPasscode = "useBiometricForPasscode"

    /// 하루 마감 요약 알림 on/off. 기본 off (사용자 opt-in).
    static let dailySummaryNotification = "dailySummaryNotification"
}
