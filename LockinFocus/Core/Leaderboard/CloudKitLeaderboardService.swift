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
        // 실패 시 조용한 "익명" 덮어쓰기는 금지: 이전에 저장된 정상 record 가
        // 규칙 강화 뒤 재제출에서 "익명" 으로 파괴되는 regression 을 막기 위해
        // ValidationError 를 그대로 던진다. 호출부(ViewModel)는 errorMessage 로 표시.
        guard case .success(let cleanNickname) = NicknameValidator.validate(nickname) else {
            throw ServiceError.underlying(
                NSError(
                    domain: "LockinFocus.NicknameValidation",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "닉네임이 규칙에 맞지 않아요. 2~20자 + 금칙어 없이 다시 입력해주세요."]
                )
            )
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

    /// 특정 userID 의 record 를 Public DB 에서 삭제.
    /// 반환값: true = 실제로 지웠음, false = 애초에 없었음.
    /// 호출부가 "삭제 완료" vs "이미 없음" 메시지를 구분해 보여줄 수 있도록.
    @discardableResult
    func deleteRecord(userID: String) async throws -> Bool {
        let recordID = CKRecord.ID(recordName: userID)
        do {
            _ = try await database.deleteRecord(withID: recordID)
            return true
        } catch let error as CKError where error.code == .unknownItem {
            return false
        } catch {
            throw mapError(error)
        }
    }

    /// 모든 record 를 가져와 현재 period 에 해당하는 것만 남긴 뒤 점수 내림차순으로 정렬.
    func fetchRanking(period: LeaderboardPeriod, limit: Int = 500) async throws -> [LeaderboardEntry] {
        let all = try await fetchAllRaw(limit: limit)
        let currentID = LeaderboardPeriodID.current(period)
        let filtered = all.filter { $0.periodID(for: period) == currentID }
        return filtered.sorted { $0.score(for: period) > $1.score(for: period) }
    }

    /// 필터/정렬 없는 raw 목록. LeaderboardView 가 period 마다 재-호출하지 않고
    /// 한 번 받은 뒤 client-side 로 3 탭을 모두 구성할 수 있게 한다.
    func fetchAllRaw(limit: Int = 500) async throws -> [LeaderboardEntry] {
        let query = CKQuery(
            recordType: LeaderboardEntry.recordType,
            predicate: NSPredicate(value: true)
        )
        query.sortDescriptors = []

        let matches: [(CKRecord.ID, Result<CKRecord, Error>)]
        do {
            (matches, _) = try await database.records(matching: query, resultsLimit: limit)
        } catch {
            throw mapError(error)
        }

        return matches.compactMap { _, result in
            guard let record = try? result.get() else { return nil }
            return LeaderboardEntry(record: record)
        }
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
