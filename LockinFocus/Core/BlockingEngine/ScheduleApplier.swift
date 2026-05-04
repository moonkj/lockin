import Foundation
import FamilyControls

/// 스케줄 변경 시 (Onboarding finish · Settings save · Dashboard save) 어디서나 동일한
/// "DeviceActivity 등록 + 활성 시간일 때만 즉시 shield 적용" 패턴을 한 곳에 모음.
///
/// 이전엔 3개 사이트 모두 인라인으로 같은 if 트리를 가지고 있어, 토요일에도 shield 가
/// 켜지는 R6 버그가 한 곳에서 수정돼도 다른 두 곳에는 누락될 위험이 있었다.
/// 이제 모두 이 헬퍼를 호출 — 동작 단일 진실 + 단위 테스트 가능.
enum ScheduleApplier {

    /// 스케줄 변경 후 호출.
    /// - Parameters:
    ///   - schedule: 새로 저장된 스케줄.
    ///   - selection: 활성 시간일 때 적용할 허용 앱 selection.
    ///   - blocking: shield 적용/해제할 엔진.
    ///   - monitoring: DeviceActivity 등록/해제할 엔진.
    ///   - manualFocusActive: 수동 집중 모드 활성 여부 — true 면 스케줄 비활성 시간이라도
    ///     shield clear 안 함 (수동이 우선).
    ///   - now: 현재 시각 (테스트용 주입).
    /// - Returns: 실제 수행된 액션 — 테스트에서 검증할 수 있도록.
    @discardableResult
    static func apply(
        schedule: Schedule,
        selection: FamilyActivitySelection,
        blocking: BlockingEngine,
        monitoring: MonitoringEngine,
        manualFocusActive: Bool = false,
        now: Date = Date()
    ) -> Action {
        if schedule.isEnabled {
            try? monitoring.startSchedule(schedule, name: "block_main")
            if schedule.isCurrentlyActive(at: now) {
                blocking.applyWhitelist(for: selection)
                return .applied
            } else if !manualFocusActive {
                blocking.clearShield()
                return .clearedAwaitingSchedule
            } else {
                // 수동 집중 중이라 shield 유지. 스케줄 등록은 됨.
                return .registeredOnly
            }
        } else {
            monitoring.stopMonitoring(name: "block_main")
            if !manualFocusActive {
                blocking.clearShield()
            }
            return manualFocusActive ? .scheduleDisabledManualKept : .scheduleDisabledCleared
        }
    }

    enum Action: Equatable {
        case applied                       // 활성 시간 → shield 켬
        case clearedAwaitingSchedule       // 비활성 시간 → shield 해제, OS 가 시간 도달 시 발동
        case registeredOnly                // 비활성 시간 + 수동 집중 → shield 유지
        case scheduleDisabledCleared       // 토글 off + 수동 미활성
        case scheduleDisabledManualKept    // 토글 off + 수동 활성
    }
}
