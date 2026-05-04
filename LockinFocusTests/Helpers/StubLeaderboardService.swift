import Foundation
@testable import LockinFocus

/// 빈 결과만 돌려주는 테스트용 stub. VM-level 단위 테스트에서 CloudKit 의존성 없이
/// `LeaderboardViewModel` 을 인스턴스화하기 위해 사용.
///
/// 이전엔 LeaderboardViewBranchTests 와 LeaderboardViewRenderTests 가 동일한 stub 을
/// 각각 `MockEmptyService` / `MockEmptyServiceForRender` 라는 다른 이름으로 중복 정의
/// 했었음. 한 헬퍼로 통합.
final class StubEmptyLeaderboardService: LeaderboardServiceProtocol {
    func accountAvailable() async -> Bool { false }

    func submit(
        userID: String, nickname: String,
        dailyScore: Int, weeklyTotal: Int, monthlyTotal: Int, now: Date
    ) async throws -> LeaderboardEntry {
        throw CloudKitLeaderboardService.ServiceError.iCloudUnavailable
    }

    func fetchRanking(period: LeaderboardPeriod, limit: Int) async throws -> [LeaderboardEntry] { [] }
    func fetchAllRaw(limit: Int) async throws -> [LeaderboardEntry] { [] }
    func deleteRecord(userID: String) async throws -> Bool { false }
}
