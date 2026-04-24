import XCTest
import SwiftUI
import ViewInspector
@testable import LockinFocus

/// ReportView 는 주간/월간 탭에서 Swift Charts 를 쓰는데, Charts 가
/// ViewInspector 와 호환 안 돼서 테스트는 일간 탭에서 진행한다.
@MainActor
final class ReportViewTests: XCTestCase {

    func testReportView_dailyInitial_rendersTabs() throws {
        let view = ReportView(initialRange: .daily)
            .environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(text: L("일간")))
        XCTAssertNoThrow(try view.inspect().find(text: L("주간")))
        XCTAssertNoThrow(try view.inspect().find(text: L("월간")))
    }

    func testReportView_hasCloseButton() throws {
        let view = ReportView(initialRange: .daily)
            .environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(button: L("닫기")))
    }

    func testReportView_daily_rendersGoalLabel() throws {
        let view = ReportView(initialRange: .daily)
            .environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(text: L("남은 목표")))
    }

    func testReportView_daily_rendersBadgeProgress() throws {
        let view = ReportView(initialRange: .daily)
            .environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(text: L("획득 뱃지")))
    }

    func testReportView_daily_rendersCumulativeReturns() throws {
        let view = ReportView(initialRange: .daily)
            .environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(text: L("누적 집중 지킴")))
    }

    func testReportView_range_allCases() {
        XCTAssertEqual(ReportView.Range.allCases.count, 3)
        XCTAssertEqual(ReportView.Range.daily.rawValue, "일간")
        XCTAssertEqual(ReportView.Range.weekly.rawValue, "주간")
        XCTAssertEqual(ReportView.Range.monthly.rawValue, "월간")
    }

    func testReportView_range_id() {
        XCTAssertEqual(ReportView.Range.daily.id, "일간")
        XCTAssertEqual(ReportView.Range.weekly.id, "주간")
        XCTAssertEqual(ReportView.Range.monthly.id, "월간")
    }

    // Weekly/Monthly 탭 body 는 history 가 비어 있으면 Chart 를 렌더하지 않도록
    // 가드가 추가됐다. PreviewPersistenceStore 의 dailyFocusHistory 는 더미 데이터를
    // 반환해 실제 시나리오를 재현하므로, 테스트는 onAppear 전의 초기 빈 상태에서
    // inspect 를 시도한다.

    // WeeklyReport/MonthlyReport 의 history @State 는 onAppear 에서 채워지지만
    // ViewInspector inspect() 는 onAppear 를 발동하지 않아 history 는 빈 배열로 유지.
    // Chart 는 history.isEmpty 가드 덕분에 빈 상태에선 렌더되지 않으므로 안전.

    func testReportView_weeklyInitial_rendersAverageCard() throws {
        let view = ReportView(initialRange: .weekly)
            .environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(text: L("최근 7일 평균")))
    }

    func testReportView_monthlyInitial_rendersStatsStrip() throws {
        let view = ReportView(initialRange: .monthly)
            .environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(text: L("기록 일수")))
        XCTAssertNoThrow(try view.inspect().find(text: L("총점")))
    }

    func testReportView_range_tapSwitchesState() throws {
        let view = ReportView(initialRange: .daily)
            .environmentObject(AppDependencies.preview())
        // 탭 버튼 3개 중 첫 버튼(일간) tap 시 에러 없이 동작.
        XCTAssertNoThrow(try view.inspect().find(button: L("일간")).tap())
    }
}
