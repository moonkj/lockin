import XCTest
import FamilyControls
import ManagedSettings
@testable import LockinFocus

@MainActor
final class DashboardViewModelTests: XCTestCase {

    /// 초간단 BlockingEngine mock — 호출만 추적.
    final class MockBlockingEngine: BlockingEngine {
        var applyCallCount = 0
        var clearCallCount = 0
        func applyWhitelist(for selection: FamilyActivitySelection) {
            applyCallCount += 1
        }
        func clearShield() { clearCallCount += 1 }
        func temporarilyAllow(token: ApplicationToken, for duration: TimeInterval) {}
    }

    // MARK: - helpers

    private func makeVM(
        passcodeSet: Bool = true,
        allowedApps: Bool = true
    ) -> (DashboardViewModel, InMemoryPersistenceStore, MockBlockingEngine, [Badge]) {
        let store = InMemoryPersistenceStore()
        if allowedApps {
            var sel = FamilyActivitySelection()
            // FamilyActivitySelection 에 토큰 주입 불가 — allowedCount 를 다른 방식으로 테스트.
            // 여기선 빈 selection 유지하고 allowedCount=0 케이스로 분기 검증.
            _ = sel
        }
        let blocking = MockBlockingEngine()
        var badges: [Badge] = []
        let vm = DashboardViewModel(
            persistence: store,
            blocking: blocking,
            badgeAwardHandler: { badges.append(contentsOf: $0) },
            widgetReload: {},
            passcodeIsSetProvider: { passcodeSet }
        )
        return (vm, store, blocking, badges)
    }

    // MARK: - handleStartTap

    func testHandleStartTap_noPasscode_showsToastAndDoesNotStart() {
        let (vm, store, blocking, _) = makeVM(passcodeSet: false)
        let action = vm.handleStartTap()
        XCTAssertEqual(action, .needsPasscode)
        XCTAssertNotNil(vm.toastMessage)
        XCTAssertFalse(vm.isManualFocus)
        XCTAssertFalse(store.isManualFocusActive)
        XCTAssertEqual(blocking.applyCallCount, 0)
    }

    func testHandleStartTap_noAllowedApps_returnsConfirmDialog() {
        let (vm, _, _, _) = makeVM(passcodeSet: true, allowedApps: false)
        // selection 이 기본값(비어있음) → allowedCount 0 → confirmEmptyAllow
        XCTAssertEqual(vm.handleStartTap(), .confirmEmptyAllow)
        XCTAssertFalse(vm.isManualFocus)
    }

    func testHandleStartTap_alreadyFocusing_returnsStartedNoop() {
        let (vm, store, blocking, _) = makeVM()
        store.isManualFocusActive = true
        vm.isManualFocus = true
        let before = blocking.applyCallCount
        _ = vm.handleStartTap()
        XCTAssertEqual(blocking.applyCallCount, before)
    }

    // MARK: - startManualFocus

    func testStartManualFocus_awardsFirstManualFocusBadge() {
        let (vm, store, blocking, _) = makeVM()
        var awarded: [Badge] = []
        let vm2 = DashboardViewModel(
            persistence: store,
            blocking: blocking,
            badgeAwardHandler: { awarded.append(contentsOf: $0) },
            passcodeIsSetProvider: { true }
        )
        vm2.startManualFocus()
        XCTAssertTrue(vm2.isManualFocus)
        XCTAssertTrue(store.isManualFocusActive)
        XCTAssertNotNil(store.manualFocusStartedAt)
        XCTAssertTrue(awarded.contains(.firstManualFocus))
        _ = vm // suppress unused
    }

    func testStartManualFocus_whenAlreadyActive_noOp() {
        let (vm, store, blocking, _) = makeVM()
        store.isManualFocusActive = true
        vm.isManualFocus = true
        vm.startManualFocus()
        XCTAssertEqual(blocking.applyCallCount, 0)
    }

    // MARK: - endManualFocus

    func testEndManualFocus_clearsStateAndCallsShield() {
        let (vm, store, blocking, _) = makeVM()
        // 시작부터 20분 후 종료 세팅.
        vm.startManualFocus()
        store.manualFocusStartedAt = Date().addingTimeInterval(-20 * 60)
        vm.endManualFocus()
        XCTAssertFalse(vm.isManualFocus)
        XCTAssertFalse(store.isManualFocusActive)
        XCTAssertEqual(blocking.clearCallCount, 1)
        XCTAssertEqual(store.focusEndCountToday, 1)
    }

    func testEndManualFocus_longSession_awardsSessionBonus() {
        let (vm, store, _, _) = makeVM()
        store.addFocusPoints(0)  // rollover 고정
        vm.startManualFocus()
        store.manualFocusStartedAt = Date().addingTimeInterval(-30 * 60)
        store.focusScoreToday = 10
        vm.endManualFocus()
        XCTAssertGreaterThanOrEqual(store.focusScoreToday, 25, "15분 이상이면 +15 보너스")
    }

    func testEndManualFocus_shortSession_noBonus() {
        let (vm, store, _, _) = makeVM()
        store.addFocusPoints(0)  // rollover 고정
        vm.startManualFocus()
        store.manualFocusStartedAt = Date().addingTimeInterval(-2 * 60)
        store.focusScoreToday = 10
        vm.endManualFocus()
        XCTAssertEqual(store.focusScoreToday, 10, "15분 미만에는 세션 보너스 없음")
    }

    // MARK: - load

    func testLoad_populatesFromPersistence() {
        let (vm, store, _, _) = makeVM()
        store.schedule = .allDay
        store.isManualFocusActive = true
        vm.load()
        XCTAssertEqual(vm.schedule, .allDay)
        XCTAssertTrue(vm.isManualFocus)
    }

    // MARK: - nextFocusEndOrdinal

    func testNextFocusEndOrdinal_reflectsCount() {
        let (vm, store, _, _) = makeVM()
        XCTAssertEqual(vm.nextFocusEndOrdinal, 1)
        store.recordManualFocusEnd()
        XCTAssertEqual(vm.nextFocusEndOrdinal, 2)
    }

    // MARK: - isStrictActive

    func testIsStrictActive_reflectsPersistence() {
        let (vm, store, _, _) = makeVM()
        XCTAssertFalse(vm.isStrictActive)
        store.strictModeEndAt = Date().addingTimeInterval(3600)
        XCTAssertTrue(vm.isStrictActive)
    }
}

extension DashboardViewModel.StartAction: Equatable {
    public static func == (
        lhs: DashboardViewModel.StartAction,
        rhs: DashboardViewModel.StartAction
    ) -> Bool {
        switch (lhs, rhs) {
        case (.started, .started),
             (.needsPasscode, .needsPasscode),
             (.confirmEmptyAllow, .confirmEmptyAllow):
            return true
        default:
            return false
        }
    }
}
