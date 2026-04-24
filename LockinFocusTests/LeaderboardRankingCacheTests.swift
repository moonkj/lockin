import XCTest
@testable import LockinFocus

/// Round 2 Perf #4 — LeaderboardServiceProtocol 이 `fetchAllRaw` 를 노출하고,
/// 기본 구현이 fetchRanking(.daily) 로 fallback 하는지 계약 고정.
@MainActor
final class LeaderboardRankingCacheTests: XCTestCase {

    final class MockService: LeaderboardServiceProtocol {
        var fetchRankingCallCount = 0
        var fetchAllRawCallCount = 0
        var seeded: [LeaderboardEntry] = []

        func accountAvailable() async -> Bool { true }

        func submit(userID: String, nickname: String, dailyScore: Int, weeklyTotal: Int, monthlyTotal: Int, now: Date) async throws -> LeaderboardEntry {
            LeaderboardEntry(
                userID: userID, nickname: nickname,
                dailyScore: dailyScore, dailyDate: LeaderboardPeriodID.daily(now),
                weeklyTotal: weeklyTotal, weeklyWeek: LeaderboardPeriodID.weekly(now),
                monthlyTotal: monthlyTotal, monthlyMonth: LeaderboardPeriodID.monthly(now),
                updatedAt: now
            )
        }

        func fetchRanking(period: LeaderboardPeriod, limit: Int) async throws -> [LeaderboardEntry] {
            fetchRankingCallCount += 1
            return seeded
        }

        func fetchAllRaw(limit: Int) async throws -> [LeaderboardEntry] {
            fetchAllRawCallCount += 1
            return seeded
        }

        func deleteRecord(userID: String) async throws -> Bool { true }
    }

    func testProtocol_defaultFetchAllRaw_fallsBackToFetchRanking() async throws {
        // Default extension 구현 테스트를 위한 minimal mock (오직 fetchRanking 만 오버라이드).
        final class LegacyMock: LeaderboardServiceProtocol {
            var calls = 0
            func accountAvailable() async -> Bool { true }
            func submit(userID: String, nickname: String, dailyScore: Int, weeklyTotal: Int, monthlyTotal: Int, now: Date) async throws -> LeaderboardEntry {
                fatalError()
            }
            func fetchRanking(period: LeaderboardPeriod, limit: Int) async throws -> [LeaderboardEntry] {
                calls += 1
                return []
            }
            func deleteRecord(userID: String) async throws -> Bool { false }
            // fetchAllRaw 오버라이드 없음 — default impl 사용.
        }
        let legacy = LegacyMock()
        _ = try await legacy.fetchAllRaw(limit: 500)
        XCTAssertEqual(legacy.calls, 1, "default impl 이 fetchRanking(.daily) 에 위임해야")
    }

    func testProtocol_overriddenFetchAllRaw_doesNotCallFetchRanking() async throws {
        let mock = MockService()
        _ = try await mock.fetchAllRaw(limit: 500)
        XCTAssertEqual(mock.fetchAllRawCallCount, 1)
        XCTAssertEqual(mock.fetchRankingCallCount, 0, "커스텀 fetchAllRaw 가 있으면 fetchRanking 은 안 불려야")
    }
}
