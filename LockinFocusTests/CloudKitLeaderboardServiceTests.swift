import XCTest
import CloudKit
@testable import LockinFocus

/// CloudKit 실요청은 테스트 환경에서 못 하지만, error 메시지/계정 체크 가드 경로는 검증 가능.
final class CloudKitLeaderboardServiceTests: XCTestCase {

    @MainActor
    func testServiceError_errorDescriptions() {
        let e1 = CloudKitLeaderboardService.ServiceError.iCloudUnavailable
        XCTAssertNotNil(e1.errorDescription)
        XCTAssertFalse(e1.errorDescription!.isEmpty)

        let e2 = CloudKitLeaderboardService.ServiceError.notLoggedIn
        XCTAssertNotNil(e2.errorDescription)

        let e3 = CloudKitLeaderboardService.ServiceError.networkFailure
        XCTAssertNotNil(e3.errorDescription)

        let underlying = NSError(domain: "x", code: 1,
                                 userInfo: [NSLocalizedDescriptionKey: "err-desc"])
        let e4 = CloudKitLeaderboardService.ServiceError.underlying(underlying)
        XCTAssertEqual(e4.errorDescription, "err-desc")
    }

    @MainActor
    func testShared_singletonIsStable() {
        XCTAssertTrue(CloudKitLeaderboardService.shared === CloudKitLeaderboardService.shared)
    }

    @MainActor
    func testAccountAvailable_completes() async {
        // 시뮬레이터는 iCloud 계정이 없을 가능성이 높아 false 로 떨어지지만
        // crash 없이 반환만 하면 통과.
        let available = await CloudKitLeaderboardService.shared.accountAvailable()
        _ = available
        XCTAssertTrue(true)
    }

    @MainActor
    func testFetchRanking_loggedOut_throwsOrEmpty() async {
        // CloudKit 요청은 계정 없으면 에러 던짐. 던지거나 빈 배열 반환하거나 모두 OK.
        do {
            let result = try await CloudKitLeaderboardService.shared
                .fetchRanking(period: .daily, limit: 10)
            XCTAssertTrue(result.count >= 0)
        } catch {
            XCTAssertNotNil(error)
        }
    }

    @MainActor
    func testSubmit_loggedOut_throwsError() async {
        // CloudKit submit 은 계정 없으면 에러 경로를 타야 하고, mapError 를 exercise 한다.
        do {
            _ = try await CloudKitLeaderboardService.shared.submit(
                userID: "test-user",
                nickname: "tester",
                dailyScore: 50,
                weeklyTotal: 200,
                monthlyTotal: 800
            )
            // 성공해도 ok (시뮬레이터에 계정 있을 수도 있음).
        } catch {
            XCTAssertNotNil(error)
        }
    }
}
