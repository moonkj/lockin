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
}
