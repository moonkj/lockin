import Foundation

/// CloudKit 랭킹 서비스 추상화. 뷰모델·테스트에서는 이 protocol 로 주입 받아
/// 실기기에선 CloudKitLeaderboardService, 테스트에선 MockLeaderboardService 를 사용.
@MainActor
protocol LeaderboardServiceProtocol: AnyObject {
    func accountAvailable() async -> Bool

    @discardableResult
    func submit(
        userID: String,
        nickname: String,
        dailyScore: Int,
        weeklyTotal: Int,
        monthlyTotal: Int,
        now: Date
    ) async throws -> LeaderboardEntry

    func fetchRanking(period: LeaderboardPeriod, limit: Int) async throws -> [LeaderboardEntry]

    /// period 필터/정렬을 하지 않은 raw 목록. LeaderboardView 의 3-period cache 용 —
    /// 한 번 fetch 로 일간/주간/월간 세 탭 모두 client-side 필터로 커버.
    /// 기본 구현은 fetchRanking(.daily) 에 위임 (backward compat); production 구현이 오버라이드.
    func fetchAllRaw(limit: Int) async throws -> [LeaderboardEntry]

    /// 특정 userID 의 record 를 Public DB 에서 삭제.
    /// 반환값: true = 실제로 지웠음, false = 애초에 record 가 없었음.
    @discardableResult
    func deleteRecord(userID: String) async throws -> Bool
}

/// default-argument helpers. 호출부 편의를 위해 extension 에 구현.
extension LeaderboardServiceProtocol {
    @discardableResult
    func submit(
        userID: String,
        nickname: String,
        dailyScore: Int,
        weeklyTotal: Int,
        monthlyTotal: Int
    ) async throws -> LeaderboardEntry {
        try await submit(
            userID: userID,
            nickname: nickname,
            dailyScore: dailyScore,
            weeklyTotal: weeklyTotal,
            monthlyTotal: monthlyTotal,
            now: Date()
        )
    }

    func fetchRanking(period: LeaderboardPeriod) async throws -> [LeaderboardEntry] {
        try await fetchRanking(period: period, limit: 500)
    }

    func fetchAllRaw(limit: Int = 500) async throws -> [LeaderboardEntry] {
        // Mock / legacy 구현은 fetchRanking(.daily) 로 fallback.
        // 실제 production 구현은 period 필터를 skip 한 full list 를 반환.
        try await fetchRanking(period: .daily, limit: limit)
    }
}

extension CloudKitLeaderboardService: LeaderboardServiceProtocol {}
