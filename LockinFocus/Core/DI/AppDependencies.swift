import Foundation
import FamilyControls
import ManagedSettings

@MainActor
final class AppDependencies: ObservableObject {
    let persistence: PersistenceStore
    let blocking: BlockingEngine
    let monitoring: MonitoringEngine

    init(
        persistence: PersistenceStore,
        blocking: BlockingEngine,
        monitoring: MonitoringEngine
    ) {
        self.persistence = persistence
        self.blocking = blocking
        self.monitoring = monitoring
    }

    /// Preview / 시뮬레이터 / Coder-A 실구현 미완 상태에서 빌드를 유지하는 Mock 세트.
    /// Coder-A 가 `live()` 실구현을 별도 파일에 추가한다.
    static func preview() -> AppDependencies {
        AppDependencies(
            persistence: PreviewPersistenceStore(),
            blocking: PreviewBlockingEngine(),
            monitoring: PreviewMonitoringEngine()
        )
    }
}

// MARK: - Preview Mocks

final class PreviewPersistenceStore: PersistenceStore {
    var selection = FamilyActivitySelection()
    var schedule = Schedule.weekdayWorkHours
    var focusScoreToday = 42
    var hasCompletedOnboarding = false
    var isManualFocusActive = false
    var isStrictModeActive = false
    var detoxSelection = FamilyActivitySelection()
    var isDetoxActive = false
    var interceptQueue: [InterceptEvent] = []

    func drainInterceptQueue() -> [InterceptEvent] {
        let q = interceptQueue
        interceptQueue.removeAll()
        return q
    }

    // Preview: 고정 10초 반환, unlock 누적은 하지 않음.
    func currentUnlockDelaySeconds() -> Int { 10 }
    func recordManualUnlock() {}
    func addFocusPoints(_ points: Int) {
        focusScoreToday = max(0, min(100, focusScoreToday + points))
    }

    func dailyFocusHistory(lastDays: Int) -> [DailyFocus] {
        // Preview 용 더미 데이터 — 최근 7일 요일별.
        let sample = [24, 42, 71, 55, 90, 33, focusScoreToday]
        let cal = Calendar.current
        let today = Date()
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return sample.enumerated().map { idx, score in
            let date = cal.date(byAdding: .day, value: idx - 6, to: today) ?? today
            return DailyFocus(date: f.string(from: date), score: score)
        }.suffix(lastDays).map { $0 }
    }
}

final class PreviewBlockingEngine: BlockingEngine {
    func applyWhitelist(for selection: FamilyActivitySelection) {}
    func clearShield() {}
    func temporarilyAllow(token: ApplicationToken, for duration: TimeInterval) {}
}

final class PreviewMonitoringEngine: MonitoringEngine {
    func startSchedule(_ schedule: Schedule, name: String) throws {}
    func stopMonitoring(name: String) {}
    func startTemporaryAllow(name: String, duration: TimeInterval) throws {}
}
