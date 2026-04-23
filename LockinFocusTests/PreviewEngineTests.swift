import XCTest
import FamilyControls
@testable import LockinFocus

/// Preview / Noop 엔진들이 어떤 호출에서도 crash 없이 종료되는지 smoke test.
/// 시뮬레이터 라이브 빌드가 Noop 을 주입하므로, UI QA 중 실행 경로가
/// 크래시를 유발하지 않아야 한다는 계약을 고정한다.
@MainActor
final class PreviewEngineTests: XCTestCase {

    // PreviewBlockingEngine 의 모든 메서드 호출은 무해해야 한다.
    func testPreviewBlockingEngine_doesNotThrow() {
        let engine = PreviewBlockingEngine()
        engine.applyBlocklist(for: FamilyActivitySelection())
        engine.clearShield()
        // temporarilyAllow 은 opaque token 생성이 불가해 호출만 스킵.
        XCTAssertTrue(true)
    }

    // PreviewMonitoringEngine 도 throw 없이 모든 호출이 성립.
    func testPreviewMonitoringEngine_doesNotThrow() {
        let engine = PreviewMonitoringEngine()
        XCTAssertNoThrow(try engine.startSchedule(.weekdayWorkHours, name: "block_main"))
        engine.stopMonitoring(name: "block_main")
        XCTAssertNoThrow(try engine.startTemporaryAllow(name: "temp_allow_test", duration: 300))
    }

    // NoopBlockingEngine / NoopMonitoringEngine 도 동일.
    func testNoopEngines_doNotThrow() {
        let blocking = NoopBlockingEngine()
        blocking.applyBlocklist(for: FamilyActivitySelection())
        blocking.clearShield()

        let monitoring = NoopMonitoringEngine()
        XCTAssertNoThrow(try monitoring.startSchedule(.weekdayWorkHours, name: "block_main"))
        monitoring.stopMonitoring(name: "block_main")
        XCTAssertNoThrow(try monitoring.startTemporaryAllow(name: "temp_allow_xyz", duration: 300))
    }

    // AppDependencies.preview() 가 모든 필드를 정상 구성하는지.
    func testAppDependencies_previewFactory_returnsAllFields() {
        let deps = AppDependencies.preview()
        XCTAssertNotNil(deps.persistence)
        XCTAssertNotNil(deps.blocking)
        XCTAssertNotNil(deps.monitoring)
        // PreviewPersistenceStore 기본값 확인.
        XCTAssertEqual(deps.persistence.focusScoreToday, 42)
        XCTAssertFalse(deps.persistence.hasCompletedOnboarding)
    }
}
