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
}
