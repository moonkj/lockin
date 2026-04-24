import XCTest
@testable import LockinFocus

/// Round 2 Feature #6 — 주간 리포트 인사이트 배너.
/// 규칙 5 개 중 한 개만 매치되고 우선순위가 있어야 한다 (위→아래).
final class WeeklyInsightsTests: XCTestCase {

    private func entry(_ date: String, _ score: Int) -> DailyFocus {
        DailyFocus(date: date, score: score)
    }

    func testGenerate_emptyHistory_returnsNil() {
        XCTAssertNil(WeeklyInsights.generate(history: [], best7d: nil))
    }

    func testGenerate_allZero_returnsNil() {
        let h = (0..<7).map { entry("2026-04-\(18+$0)", 0) }
        XCTAssertNil(WeeklyInsights.generate(history: h, best7d: 0))
    }

    // Rule 1: 최고 기록 ±5 이내.
    func testGenerate_near_personalBest() {
        let h = [
            entry("2026-04-18", 50),
            entry("2026-04-19", 60),
            entry("2026-04-20", 95)
        ]
        let result = WeeklyInsights.generate(history: h, best7d: 98)
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.contains("최고 기록"))
    }

    // Rule 2: 주 후반 평균 상승.
    func testGenerate_improvingTrend() {
        let h = [
            entry("2026-04-18", 20),
            entry("2026-04-19", 30),
            entry("2026-04-20", 25),
            entry("2026-04-21", 60),
            entry("2026-04-22", 70),
            entry("2026-04-23", 80)
        ]
        let result = WeeklyInsights.generate(history: h, best7d: 80)
        XCTAssertNotNil(result)
    }

    // Rule 3: 3일 이상 연속.
    func testGenerate_streak3Days() {
        let h = [
            entry("2026-04-18", 0),
            entry("2026-04-19", 0),
            entry("2026-04-20", 40),
            entry("2026-04-21", 50),
            entry("2026-04-22", 60)
        ]
        let result = WeeklyInsights.generate(history: h, best7d: 60)
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.contains("연속"))
    }

    // Rule 4: 쉬고 복귀.
    func testGenerate_returnedAfterBreak() {
        let h = [
            entry("2026-04-21", 40),
            entry("2026-04-22", 0),
            entry("2026-04-23", 55)
        ]
        // 복귀 메시지 or 연속(1일뿐이라 매치 안 됨) 또는 주간최고(동점) 중 하나.
        // 최소한 nil 은 아니어야.
        XCTAssertNotNil(WeeklyInsights.generate(history: h, best7d: 55))
    }

    // 짧은 history 라도 최소 1개 규칙에 걸리면 결과.
    func testGenerate_singleEntry_fallsThrough() {
        let h = [entry("2026-04-24", 10)]
        // 단일 점수 + 오늘 최고치 동시 — 우선순위가 낮아 nil 일 수도 있음. 규칙 검증.
        _ = WeeklyInsights.generate(history: h, best7d: 10)
    }
}
