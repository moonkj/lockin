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
        XCTAssertNoThrow(try view.inspect().find(text: "일간"))
        XCTAssertNoThrow(try view.inspect().find(text: "주간"))
        XCTAssertNoThrow(try view.inspect().find(text: "월간"))
    }

    func testReportView_hasCloseButton() throws {
        let view = ReportView(initialRange: .daily)
            .environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(button: "닫기"))
    }

    func testReportView_daily_rendersGoalLabel() throws {
        let view = ReportView(initialRange: .daily)
            .environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(text: "남은 목표"))
    }

    func testReportView_daily_rendersBadgeProgress() throws {
        let view = ReportView(initialRange: .daily)
            .environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(text: "획득 뱃지"))
    }

    func testReportView_daily_rendersCumulativeReturns() throws {
        let view = ReportView(initialRange: .daily)
            .environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(text: "누적 집중 지킴"))
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

    func testReportView_instantiateWeekly() {
        // weekly 탭 기본 생성 경로 — body 가 Charts 까지 들어가지 않는다면 crash 없이 통과.
        let view = ReportView(initialRange: .weekly)
            .environmentObject(AppDependencies.preview())
        _ = view  // 뷰 구조체 생성만 테스트 (body 는 SwiftUI 가 필요할 때 호출)
    }

    func testReportView_instantiateMonthly() {
        let view = ReportView(initialRange: .monthly)
            .environmentObject(AppDependencies.preview())
        _ = view
    }
}
