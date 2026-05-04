import Foundation

/// Shield 의 "돌아가기" 누름과 동시에 +5 점수를 즉시 부여하는 헬퍼.
///
/// 메인 앱은 이 점수를 다음 포그라운드 진입 시 InterceptView 시트로 보여만 주고
/// 중복 적립하지 않는다 (큐 이벤트의 `alreadyScored: true` 플래그로 식별).
///
/// **주의**: ShieldActionExtension 은 메인 앱 코드를 공유하지 않는다. 점수 규칙 B
/// (쿨다운 3분 · 하루 한도 40 · 단위 5점 · clamp 100) 의 키와 상수는 메인 앱
/// `UserDefaultsPersistenceStore` 와 1:1 일치해야 한다. 둘 중 한쪽만 변경되면 두 경로의
/// 점수가 어긋나니 변경 시 양쪽 모두 갱신.
///
/// 메인 앱이 다음 진입 시 처리하는 부담을 덜기 위해 자정 이후 첫 호출이면
/// 단순히 `focusScoreToday=0` 으로 시작 (history rollover 는 메인 앱이 별도 처리).
enum ReturnPointAwarder {
    private static let cooldownSeconds: TimeInterval = 3 * 60
    private static let dailyCap: Int = 40
    private static let unitPoint: Int = 5

    /// 메인 앱 `UserDefaultsPersistenceStore` 와 동일.
    private enum Keys {
        static let focusScoreToday = "focusScoreToday"
        static let focusScoreDate = "focusScoreDate"
        static let lastReturnAt = "lastReturnAt"
        static let todayReturnPoints = "todayReturnPoints"
    }

    /// 보상 적용 시도. 적용했으면 true, 쿨다운/한도/자정경계/저장소 미접근 등으로 skip
    /// 했으면 false. false 시 메인 앱이 다음 진입에서 종전 경로 (`awardReturnPoint`) 로
    /// 정상 처리.
    ///
    /// **자정 경계 처리**: storedDate 가 오늘과 다르면 history rollover 가 필요한데
    /// Extension 은 history JSON 인코딩 등 비용 큰 로직을 갖지 않는다. 이 경우 점수
    /// 부여를 skip 해서 메인 앱의 `rolloverFocusScoreIfNewDay()` 가 정상적으로 어제 점수를
    /// history 에 적층한 뒤 메인 앱이 직접 +5 를 부여하도록 한다. 자정 직후 1회 누락은
    /// 사용자 영향이 매우 작고, 어제 점수 손실 위험을 피한다.
    @discardableResult
    static func awardIfEligible(now: Date = Date()) -> Bool {
        guard let defaults = UserDefaults(suiteName: AppGroup.identifier) else { return false }

        let todayString = ISO8601Date.todayString(now: now)
        let storedDate = defaults.string(forKey: Keys.focusScoreDate)

        // 자정 경계 — Extension 은 history rollover 안 함. 메인 앱이 다음 진입 시 처리.
        if let storedDate, storedDate != todayString {
            return false
        }
        // 첫 호출 (storedDate 가 nil) 이면 오늘 첫 점수 시작이므로 즉시 진행.
        if storedDate == nil {
            defaults.set(todayString, forKey: Keys.focusScoreDate)
        }

        // 쿨다운.
        if let lastTs = defaults.object(forKey: Keys.lastReturnAt) as? TimeInterval {
            let last = Date(timeIntervalSince1970: lastTs)
            if now.timeIntervalSince(last) < cooldownSeconds { return false }
        }
        // 하루 한도.
        let today = defaults.integer(forKey: Keys.todayReturnPoints)
        guard today < dailyCap else { return false }

        let awarded = min(unitPoint, dailyCap - today)
        let currentScore = defaults.integer(forKey: Keys.focusScoreToday)
        let nextScore = max(0, min(100, currentScore + awarded))
        defaults.set(nextScore, forKey: Keys.focusScoreToday)
        defaults.set(today + awarded, forKey: Keys.todayReturnPoints)
        defaults.set(now.timeIntervalSince1970, forKey: Keys.lastReturnAt)
        return true
    }
}

/// `yyyy-MM-dd` 포맷 문자열 — 메인 앱과 일치 (UserDefaultsPersistenceStore.todayString).
private enum ISO8601Date {
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func todayString(now: Date = Date()) -> String {
        formatter.string(from: now)
    }
}
