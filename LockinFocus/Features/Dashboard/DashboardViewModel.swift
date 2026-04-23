import Foundation
import FamilyControls
import SwiftUI

/// DashboardView 의 집중 시작·종료·토스트·뱃지 집계 로직을 분리한 ViewModel.
/// 뷰는 프레젠테이션만 담당하고, 테스트는 이 VM 을 통해 상태 전환을 검증.
@MainActor
final class DashboardViewModel: ObservableObject {
    private let persistence: PersistenceStore
    private let blocking: BlockingEngine
    private let badgeAwardHandler: ([Badge]) -> Void
    private let widgetReload: () -> Void
    private let passcodeIsSetProvider: () -> Bool
    private let clock: () -> Date

    @Published var selection: FamilyActivitySelection = FamilyActivitySelection()
    @Published var schedule: Schedule = .weekdayWorkHours
    @Published var isManualFocus: Bool = false
    @Published var toastMessage: String? = nil

    init(
        persistence: PersistenceStore,
        blocking: BlockingEngine,
        badgeAwardHandler: @escaping ([Badge]) -> Void,
        widgetReload: @escaping () -> Void = {},
        passcodeIsSetProvider: @escaping () -> Bool = { AppPasscodeStore.isSet },
        clock: @escaping () -> Date = Date.init
    ) {
        self.persistence = persistence
        self.blocking = blocking
        self.badgeAwardHandler = badgeAwardHandler
        self.widgetReload = widgetReload
        self.passcodeIsSetProvider = passcodeIsSetProvider
        self.clock = clock
    }

    /// 대시보드 진입/설정 복귀 시 호출 — 저장된 값으로 상태를 채운다.
    func load() {
        selection = persistence.selection
        schedule = persistence.schedule
        isManualFocus = persistence.isManualFocusActive
    }

    var allowedCount: Int {
        selection.applicationTokens.count
        + selection.categoryTokens.count
        + selection.webDomainTokens.count
    }

    var isStrictActive: Bool { persistence.isStrictModeActive }

    /// 다음 해제가 오늘 몇 번째인지 — FocusEndConfirmView 에 넘기는 ordinal.
    var nextFocusEndOrdinal: Int { persistence.focusEndCountToday + 1 }

    /// "지금 집중 시작" 버튼 액션. 반환값으로 뷰에게 다음 표시를 알림.
    enum StartAction {
        case started
        case needsPasscode      // 토스트만 띄우고 시작 안 함
        case confirmEmptyAllow  // 허용 앱 0개 확인 다이얼로그
    }

    @discardableResult
    func handleStartTap() -> StartAction {
        guard !isManualFocus else { return .started }
        if !passcodeIsSetProvider() {
            toastMessage = "앱 비밀번호를 먼저 설정해주세요. 설정에서 등록할 수 있어요."
            return .needsPasscode
        }
        if allowedCount == 0 {
            return .confirmEmptyAllow
        }
        startManualFocus()
        return .started
    }

    /// 실제 수동 집중 시작 — handleStartTap 내부 또는 "시스템 앱 외 전부 잠그기" 확인 후 호출.
    func startManualFocus() {
        guard !isManualFocus else { return }
        blocking.applyWhitelist(for: selection)
        persistence.isManualFocusActive = true
        persistence.manualFocusStartedAt = clock()
        let unlocked = BadgeEngine.onManualFocusStarted(persistence: persistence)
        badgeAwardHandler(unlocked)
        isManualFocus = true
    }

    /// "집중 종료" 확정 — FocusEndConfirmView 에서 통과된 뒤 호출.
    func endManualFocus() {
        let start = persistence.manualFocusStartedAt
        let now = clock()
        blocking.clearShield()
        persistence.isManualFocusActive = false
        persistence.recordManualFocusEnd()
        persistence.awardSessionCompletionIfEligible(now: now)
        var unlocked: [Badge] = []
        if let start {
            unlocked.append(contentsOf: BadgeEngine.onManualFocusEnded(
                elapsed: now.timeIntervalSince(start),
                persistence: persistence
            ))
        }
        unlocked.append(contentsOf: BadgeEngine.onScoreChanged(persistence: persistence))
        badgeAwardHandler(unlocked)
        widgetReload()
        isManualFocus = false
    }
}
