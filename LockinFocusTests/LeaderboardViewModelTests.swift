import XCTest
@testable import LockinFocus

/// LeaderboardViewModel 의 load/submit/rank 계산 로직을 MockService 로 검증.
@MainActor
final class LeaderboardViewModelTests: XCTestCase {

    // MARK: - Mock service

    final class MockLeaderboardService: LeaderboardServiceProtocol {
        var accountAvailableResult: Bool = true
        var fetchResult: Result<[LeaderboardEntry], Error> = .success([])
        var submitResult: Result<LeaderboardEntry, Error>!
        var submittedPayload: (userID: String, nickname: String, d: Int, w: Int, m: Int)?
        var fetchCallCount = 0
        var submitCallCount = 0

        func accountAvailable() async -> Bool { accountAvailableResult }

        func submit(
            userID: String, nickname: String,
            dailyScore: Int, weeklyTotal: Int, monthlyTotal: Int, now: Date
        ) async throws -> LeaderboardEntry {
            submitCallCount += 1
            submittedPayload = (userID, nickname, dailyScore, weeklyTotal, monthlyTotal)
            switch submitResult! {
            case .success(let e): return e
            case .failure(let err): throw err
            }
        }

        func fetchRanking(period: LeaderboardPeriod, limit: Int) async throws -> [LeaderboardEntry] {
            fetchCallCount += 1
            switch fetchResult {
            case .success(let list): return list
            case .failure(let err): throw err
            }
        }

        var deletedUserIDs: [String] = []
        @discardableResult
        func deleteRecord(userID: String) async throws -> Bool {
            deletedUserIDs.append(userID)
            return true
        }

        var fetchAllRawCallCount = 0
        var fetchAllRawResult: Result<[LeaderboardEntry], Error>?
        func fetchAllRaw(limit: Int) async throws -> [LeaderboardEntry] {
            fetchAllRawCallCount += 1
            if let result = fetchAllRawResult {
                switch result {
                case .success(let list): return list
                case .failure(let err): throw err
                }
            }
            // Override 가 없으면 기본 fetchRanking fallback 경로.
            return try await fetchRanking(period: .daily, limit: limit)
        }
    }

    // MARK: - Helpers

    /// VM 이 today-period filter 를 적용하므로 test entries 는 오늘 날짜로 만든다.
    private func makeEntry(userID: String, daily: Int = 0) -> LeaderboardEntry {
        LeaderboardEntry(
            userID: userID, nickname: "N-\(userID)",
            dailyScore: daily, dailyDate: LeaderboardPeriodID.daily(),
            weeklyTotal: 0, weeklyWeek: "",
            monthlyTotal: 0, monthlyMonth: "",
            updatedAt: Date()
        )
    }

    private func makeVM(
        service: MockLeaderboardService? = nil,
        store: InMemoryPersistenceStore? = nil
    ) -> (LeaderboardViewModel, MockLeaderboardService, InMemoryPersistenceStore) {
        let svc = service ?? MockLeaderboardService()
        let s = store ?? InMemoryPersistenceStore()
        let vm = LeaderboardViewModel(service: svc, persistence: s)
        return (vm, svc, s)
    }

    // MARK: - load()

    func testLoad_success_populatesEntries() async {
        let (vm, svc, _) = makeVM()
        svc.fetchResult = .success([makeEntry(userID: "a"), makeEntry(userID: "b")])
        await vm.load()
        XCTAssertEqual(vm.entries.count, 2)
        XCTAssertNil(vm.errorMessage)
        XCTAssertFalse(vm.isLoading)
    }

    func testLoad_accountUnavailable_setsErrorAndEmptyEntries() async {
        let (vm, svc, _) = makeVM()
        svc.accountAvailableResult = false
        svc.fetchResult = .success([makeEntry(userID: "a")])
        await vm.load()
        XCTAssertTrue(vm.entries.isEmpty)
        XCTAssertNotNil(vm.errorMessage)
        XCTAssertEqual(svc.fetchCallCount, 0, "계정 없으면 fetch 호출도 하지 않아야")
    }

    func testLoad_fetchThrowsServiceError_setsErrorMessage() async {
        let (vm, svc, _) = makeVM()
        svc.fetchResult = .failure(CloudKitLeaderboardService.ServiceError.networkFailure)
        await vm.load()
        XCTAssertNotNil(vm.errorMessage)
        XCTAssertTrue(vm.errorMessage!.contains("네트워크"))
    }

    func testLoad_fetchThrowsGenericError_setsErrorMessage() async {
        let (vm, svc, _) = makeVM()
        svc.fetchResult = .failure(NSError(
            domain: "x", code: 1,
            userInfo: [NSLocalizedDescriptionKey: "boom"]
        ))
        await vm.load()
        XCTAssertEqual(vm.errorMessage, "boom")
    }

    func testLoad_rankingBadgeHandler_firesForTop1Of100() async {
        let store = InMemoryPersistenceStore()
        let svc = MockLeaderboardService()
        var awardedBadges: [Badge] = []
        let vm = LeaderboardViewModel(
            service: svc,
            persistence: store,
            badgeAwardHandler: { awardedBadges.append(contentsOf: $0) }
        )
        // 100명, 1번이 내 ID.
        let myID = vm.myUserID
        var entries: [LeaderboardEntry] = [makeEntry(userID: myID, daily: 100)]
        for i in 1..<100 {
            entries.append(makeEntry(userID: "other-\(i)", daily: 100 - i))
        }
        svc.fetchResult = .success(entries)
        await vm.load()
        XCTAssertTrue(awardedBadges.contains(.rankFirst))
    }

    // MARK: - submitAndRefresh()

    func testSubmit_noNickname_triggersSetup() async {
        let (vm, _, store) = makeVM()
        store.nickname = nil
        var setupTriggered = false
        await vm.submitAndRefresh { setupTriggered = true }
        XCTAssertTrue(setupTriggered)
    }

    func testSubmit_accountUnavailable_errorMessageSet() async {
        let (vm, svc, store) = makeVM()
        store.nickname = "t"
        svc.accountAvailableResult = false
        await vm.submitAndRefresh()
        XCTAssertNotNil(vm.errorMessage)
    }

    func testSubmit_happyPath_callsServiceWithCorrectPayload() async {
        let (vm, svc, store) = makeVM()
        store.nickname = "집중러"
        store.focusScoreToday = 77
        svc.submitResult = .success(makeEntry(userID: vm.myUserID))
        svc.fetchResult = .success([])
        await vm.submitAndRefresh()
        XCTAssertNotNil(svc.submittedPayload)
        XCTAssertEqual(svc.submittedPayload?.nickname, "집중러")
        XCTAssertEqual(svc.submittedPayload?.d, 77)
    }

    func testSubmit_failure_errorMessageSet() async {
        let (vm, svc, store) = makeVM()
        store.nickname = "t"
        svc.submitResult = .failure(CloudKitLeaderboardService.ServiceError.iCloudUnavailable)
        await vm.submitAndRefresh()
        XCTAssertNotNil(vm.errorMessage)
    }

    func testSubmit_genericError_errorMessageSet() async {
        let (vm, svc, store) = makeVM()
        store.nickname = "t"
        svc.submitResult = .failure(NSError(
            domain: "x", code: 1,
            userInfo: [NSLocalizedDescriptionKey: "bang"]
        ))
        await vm.submitAndRefresh()
        XCTAssertEqual(vm.errorMessage, "bang")
    }

    // MARK: - Computed properties

    func testMyRank_nilWhenUserNotInEntries() async {
        let (vm, _, _) = makeVM()
        vm.entries = [makeEntry(userID: "other")]
        XCTAssertNil(vm.myRank)
    }

    func testMyRank_correctWhenPresent() async {
        let (vm, _, _) = makeVM()
        vm.entries = [
            makeEntry(userID: "x"),
            makeEntry(userID: vm.myUserID),
            makeEntry(userID: "z")
        ]
        XCTAssertEqual(vm.myRank, 2)
    }

    func testMyEntry_nilWhenNotPresent() async {
        let (vm, _, _) = makeVM()
        XCTAssertNil(vm.myEntry)
    }

    func testMyPercentile_calculatedFromRank() async {
        let (vm, _, _) = makeVM()
        var entries: [LeaderboardEntry] = []
        for i in 0..<100 {
            entries.append(makeEntry(userID: i == 9 ? vm.myUserID : "o-\(i)"))
        }
        vm.entries = entries
        XCTAssertEqual(vm.myRank, 10)
        XCTAssertEqual(vm.myPercentile, 10)
    }

    func testMyPercentile_nilWhenEmpty() async {
        let (vm, _, _) = makeVM()
        XCTAssertNil(vm.myPercentile)
    }

    // MARK: - Round 4 VM expansion: 60s TTL cache + scope

    func testLoad_useRawCacheWhenFresh_skipsSecondFetch() async {
        let (vm, svc, _) = makeVM()
        svc.fetchAllRawResult = .success([makeEntry(userID: "a"), makeEntry(userID: "b")])
        await vm.load()
        let firstCount = svc.fetchAllRawCallCount
        XCTAssertEqual(firstCount, 1)
        // 동일 period 재load — 캐시 신선하면 CK 호출 안 함.
        await vm.load()
        XCTAssertEqual(svc.fetchAllRawCallCount, firstCount, "cache TTL 내 재load 는 CloudKit 호출 skip")
    }

    func testLoad_forceRefresh_overridesCache() async {
        let (vm, svc, _) = makeVM()
        svc.fetchAllRawResult = .success([makeEntry(userID: "a")])
        await vm.load()
        XCTAssertEqual(svc.fetchAllRawCallCount, 1)
        await vm.load(forceRefresh: true)
        XCTAssertEqual(svc.fetchAllRawCallCount, 2, "forceRefresh 는 캐시 무시")
    }

    func testPeriodChange_usesCachedRawEntries_noCloudKitRoundTrip() async {
        let (vm, svc, _) = makeVM()
        svc.fetchAllRawResult = .success([makeEntry(userID: "a")])
        await vm.load()
        XCTAssertEqual(svc.fetchAllRawCallCount, 1)
        // period 변경 → didSet 이 applyFilter 호출 (또는 fresh 면 load skip).
        vm.period = .weekly
        // applyFilter 는 동기 — 추가 CK 호출 없어야.
        XCTAssertEqual(svc.fetchAllRawCallCount, 1, "period 토글은 client-side 필터로 끝")
    }

    func testScope_friendsWithNoFriends_showsOnlyMyEntry() async {
        let (vm, svc, store) = makeVM()
        store.friendUserIDs = []
        svc.fetchAllRawResult = .success([
            makeEntry(userID: "other1"),
            makeEntry(userID: vm.myUserID),
            makeEntry(userID: "other2")
        ])
        await vm.load()
        vm.scope = .friends
        XCTAssertEqual(vm.entries.count, 1)
        XCTAssertEqual(vm.entries.first?.userID, vm.myUserID)
    }

    func testScope_friendsWithFriends_includesMePlusFriends() async {
        let (vm, svc, store) = makeVM()
        store.friendUserIDs = ["f1", "f2"]
        svc.fetchAllRawResult = .success([
            makeEntry(userID: "stranger"),
            makeEntry(userID: vm.myUserID),
            makeEntry(userID: "f1"),
            makeEntry(userID: "f2")
        ])
        await vm.load()
        vm.scope = .friends
        let ids = Set(vm.entries.map { $0.userID })
        XCTAssertEqual(ids, [vm.myUserID, "f1", "f2"])
        XCTAssertFalse(ids.contains("stranger"))
    }

    func testRefreshMyUserIDIfChanged_updatesWhenStoreChanges() async {
        let store = InMemoryPersistenceStore()
        // InMemory 의 leaderboardUserID 는 UUID 로 한 번 고정됨 — 새 인스턴스로 교체 시뮬.
        let svc = MockLeaderboardService()
        let vm = LeaderboardViewModel(
            service: svc,
            persistence: store,
            initialMyUserID: "old-injected"
        )
        XCTAssertEqual(vm.myUserID, "old-injected")
        // store 의 userID 는 UUID 로 생성된 값 — 명시 호출 시 그 값으로 갱신.
        vm.refreshMyUserIDIfChanged()
        XCTAssertEqual(vm.myUserID, store.leaderboardUserID)
    }

    // MARK: - Round 7: connect() swap 보존

    /// LeaderboardView 가 stub 으로 init 한 VM 을 .task 에서 실제 deps 로 swap 한다.
    /// swap 이후 entries / period / scope 같은 상태가 유지되고, myUserID 는 새 store 값으로
    /// 갱신되는지 확인.
}
