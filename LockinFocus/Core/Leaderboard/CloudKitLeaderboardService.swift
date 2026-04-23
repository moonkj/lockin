import CloudKit
import Foundation

/// CloudKit Public DB 랭킹 — 일간/주간/월간 점수를 한 record 에 함께 저장한다.
/// 조회는 모든 record 를 가져와 클라이언트에서 `period` 식별자 필터 + 점수 정렬.
/// (queryable/sortable 인덱스 수동 설정을 요구하지 않기 위한 초기 전략)
@MainActor
final class CloudKitLeaderboardService: ObservableObject {
    static let shared = CloudKitLeaderboardService()

    enum ServiceError: LocalizedError {
        case iCloudUnavailable
        case notLoggedIn
        case networkFailure
        case underlying(Error)

        var errorDescription: String? {
            switch self {
            case .iCloudUnavailable: return "iCloud 를 사용할 수 없어요."
            case .notLoggedIn:       return "설정에서 iCloud 에 로그인해주세요."
            case .networkFailure:    return "네트워크 연결을 확인해주세요."
            case .underlying(let e): return e.localizedDescription
            }
        }
    }

    private let container: CKContainer
    private var database: CKDatabase { container.publicCloudDatabase }

    private init(
        container: CKContainer = CKContainer(identifier: "iCloud.com.moonkj.LockinFocus")
    ) {
        self.container = container
    }

    func accountAvailable() async -> Bool {
        do {
            return try await container.accountStatus() == .available
        } catch {
            return false
        }
    }

    /// 전체 점수 제출. 호출 시점의 daily/weekly/monthly 를 한 번에 갱신.
    @discardableResult
    func submit(
        userID: String,
        nickname: String,
        dailyScore: Int,
        weeklyTotal: Int,
        monthlyTotal: Int,
        now: Date = Date()
    ) async throws -> LeaderboardEntry {
        // 클라이언트 측 sanity clamp — 서버 측 검증이 없는 현 구조에서 최소한의 장벽.
        // 서버 보안은 별도 Phase 에서 CloudKit security rules 또는 App Attest 로 해결.
        let daily = max(0, min(100, dailyScore))
        let weekly = max(0, min(700, weeklyTotal))
        let monthly = max(0, min(3100, monthlyTotal))
        // 닉네임 재검증 — UI 를 거치지 않은 직접 호출 경로도 가드.
        let cleanNickname: String
        if case .success(let valid) = NicknameValidator.validate(nickname) {
            cleanNickname = valid
        } else {
            // 검증 실패 시 원본을 그대로 쓰지 않고 알 수 없는 사용자 처리.
            cleanNickname = "익명"
        }
        let recordID = CKRecord.ID(recordName: userID)
        let record: CKRecord
        do {
            record = try await database.record(for: recordID)
        } catch let error as CKError where error.code == .unknownItem {
            record = CKRecord(recordType: LeaderboardEntry.recordType, recordID: recordID)
        } catch {
            throw mapError(error)
        }

        record["nickname"] = cleanNickname as CKRecordValue
        record["dailyScore"] = daily as CKRecordValue
        record["dailyDate"] = LeaderboardPeriodID.daily(now) as CKRecordValue
        record["weeklyTotal"] = weekly as CKRecordValue
        record["weeklyWeek"] = LeaderboardPeriodID.weekly(now) as CKRecordValue
        record["monthlyTotal"] = monthly as CKRecordValue
        record["monthlyMonth"] = LeaderboardPeriodID.monthly(now) as CKRecordValue
        record["updatedAt"] = now as CKRecordValue

        do {
            let saved = try await database.save(record)
            return LeaderboardEntry(record: saved) ?? LeaderboardEntry(
                userID: userID,
                nickname: cleanNickname,
                dailyScore: daily,
                dailyDate: LeaderboardPeriodID.daily(now),
                weeklyTotal: weekly,
                weeklyWeek: LeaderboardPeriodID.weekly(now),
                monthlyTotal: monthly,
                monthlyMonth: LeaderboardPeriodID.monthly(now),
                updatedAt: now
            )
        } catch {
            throw mapError(error)
        }
    }

    /// 모든 record 를 가져와 현재 period 에 해당하는 것만 남긴 뒤 점수 내림차순으로 정렬.
    func fetchRanking(period: LeaderboardPeriod, limit: Int = 500) async throws -> [LeaderboardEntry] {
        let query = CKQuery(
            recordType: LeaderboardEntry.recordType,
            predicate: NSPredicate(value: true)
        )
        // 정렬은 클라이언트에서 period 별로 수행한다. CloudKit 의 server sort 를
        // 쓰려면 해당 필드에 sortable 인덱스가 필요하므로, 초기 스키마 설정 부담을
        // 줄이기 위해 sortDescriptors 는 비워둔다.
        query.sortDescriptors = []

        let matches: [(CKRecord.ID, Result<CKRecord, Error>)]
        do {
            (matches, _) = try await database.records(matching: query, resultsLimit: limit)
        } catch {
            throw mapError(error)
        }

        let all: [LeaderboardEntry] = matches.compactMap { _, result in
            guard let record = try? result.get() else { return nil }
            return LeaderboardEntry(record: record)
        }

        let currentID = LeaderboardPeriodID.current(period)
        let filtered = all.filter { $0.periodID(for: period) == currentID }
        return filtered.sorted { $0.score(for: period) > $1.score(for: period) }
    }

    // MARK: - Error mapping

    private func mapError(_ error: Error) -> ServiceError {
        guard let ck = error as? CKError else { return .underlying(error) }
        switch ck.code {
        case .notAuthenticated:          return .notLoggedIn
        case .networkUnavailable,
             .networkFailure,
             .serviceUnavailable,
             .requestRateLimited:        return .networkFailure
        default:                         return .underlying(ck)
        }
    }
}
