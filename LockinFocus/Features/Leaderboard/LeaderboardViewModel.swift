import Foundation
import SwiftUI

/// LeaderboardView 의 비즈니스 로직을 뷰에서 분리한 ViewModel.
/// 테스트에서 MockLeaderboardService 를 주입해 submit / fetch / rank 계산을 검증한다.
@MainActor
final class LeaderboardViewModel: ObservableObject {
    // 입력 의존성.
    private let service: LeaderboardServiceProtocol
    private let persistence: PersistenceStore
    private let badgeAwardHandler: (([Badge]) -> Void)?
    private let clock: () -> Date

    // 뷰가 바인딩할 상태.
    @Published var period: LeaderboardPeriod = .daily
    @Published var entries: [LeaderboardEntry] = []
    @Published var isLoading: Bool = false
    @Published var isSubmitting: Bool = false
    @Published var errorMessage: String?

    /// iCloud KV 호출을 반복하지 않기 위해 생성자에서 캐시.
    let myUserID: String
    var myNickname: String? { persistence.nickname }

    init(
        service: LeaderboardServiceProtocol,
        persistence: PersistenceStore,
        badgeAwardHandler: (([Badge]) -> Void)? = nil,
        clock: @escaping () -> Date = Date.init
    ) {
        self.service = service
        self.persistence = persistence
        self.badgeAwardHandler = badgeAwardHandler
        self.clock = clock
        self.myUserID = persistence.leaderboardUserID
    }

    var myRank: Int? {
        entries.firstIndex { $0.userID == myUserID }.map { $0 + 1 }
    }

    var myEntry: LeaderboardEntry? {
        entries.first { $0.userID == myUserID }
    }

    var myPercentile: Int? {
        guard let rank = myRank, !entries.isEmpty else { return nil }
        let ratio = Double(rank) / Double(entries.count)
        return max(1, min(100, Int(ceil(ratio * 100))))
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        if !(await service.accountAvailable()) {
            errorMessage = "iCloud 에 로그인해주세요. 설정 → Apple ID → iCloud."
            entries = []
            isLoading = false
            return
        }
        do {
            entries = try await service.fetchRanking(period: period)
            let unlocked = BadgeEngine.onRankingFetched(
                entries: entries,
                userID: myUserID,
                persistence: persistence
            )
            if !unlocked.isEmpty { badgeAwardHandler?(unlocked) }
        } catch let error as CloudKitLeaderboardService.ServiceError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// "지금 점수로 랭킹 제출" — 오늘/최근 7일/최근 30일 점수를 집계해 한 번에 업데이트.
    func submitAndRefresh(
        nicknameSetupTrigger: (() -> Void)? = nil
    ) async {
        guard let nickname = myNickname else {
            nicknameSetupTrigger?()
            return
        }
        guard await service.accountAvailable() else {
            errorMessage = "iCloud 에 로그인되어 있어야 랭킹에 참여할 수 있어요."
            return
        }
        isSubmitting = true
        errorMessage = nil

        let now = clock()
        let dailyScore = persistence.focusScoreToday
        let recent7 = persistence.dailyFocusHistory(lastDays: 7)
        let weeklyTotal = recent7.reduce(0) { $0 + $1.score }
        let recent30 = persistence.dailyFocusHistory(lastDays: 30)
        let monthlyTotal = recent30.reduce(0) { $0 + $1.score }

        do {
            _ = try await service.submit(
                userID: myUserID,
                nickname: nickname,
                dailyScore: dailyScore,
                weeklyTotal: weeklyTotal,
                monthlyTotal: monthlyTotal,
                now: now
            )
            await load()
        } catch let error as CloudKitLeaderboardService.ServiceError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }
}
