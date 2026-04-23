import FamilyControls
import Foundation

/// App Group `UserDefaults` 기반 실구현.
/// - `FamilyActivitySelection`, `Schedule`, `[InterceptEvent]` 는 JSON Data 로 저장.
/// - `focusScoreToday`, `hasCompletedOnboarding` 은 네이티브 `.integer / .bool`.
/// - `drainInterceptQueue()` 는 Extension 이 쓴 **원시 포맷** 큐를 디코딩하고 비운다.
final class UserDefaultsPersistenceStore: PersistenceStore {
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = AppGroup.sharedDefaults) {
        self.defaults = defaults
    }

    // MARK: - FamilyActivitySelection

    var selection: FamilyActivitySelection {
        get {
            guard let data = defaults.data(forKey: SharedKeys.familySelection) else {
                return FamilyActivitySelection()
            }
            return (try? decoder.decode(FamilyActivitySelection.self, from: data))
                ?? FamilyActivitySelection()
        }
        set {
            if let data = try? encoder.encode(newValue) {
                defaults.set(data, forKey: SharedKeys.familySelection)
            }
        }
    }

    // MARK: - Schedule

    var schedule: Schedule {
        get {
            guard let data = defaults.data(forKey: PersistenceKeys.schedule) else {
                return .weekdayWorkHours
            }
            return (try? decoder.decode(Schedule.self, from: data)) ?? .weekdayWorkHours
        }
        set {
            if let data = try? encoder.encode(newValue) {
                defaults.set(data, forKey: PersistenceKeys.schedule)
            }
        }
    }

    // MARK: - Scalars

    var focusScoreToday: Int {
        get { defaults.integer(forKey: SharedKeys.focusScoreToday) }
        set { defaults.set(newValue, forKey: SharedKeys.focusScoreToday) }
    }

    var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: PersistenceKeys.hasCompletedOnboarding) }
        set { defaults.set(newValue, forKey: PersistenceKeys.hasCompletedOnboarding) }
    }

    var isManualFocusActive: Bool {
        get { defaults.bool(forKey: PersistenceKeys.isManualFocusActive) }
        set { defaults.set(newValue, forKey: PersistenceKeys.isManualFocusActive) }
    }

    // MARK: - InterceptQueue (Codable 보관)

    var interceptQueue: [InterceptEvent] {
        get {
            guard let data = defaults.data(forKey: PersistenceKeys.codableInterceptQueue) else {
                return []
            }
            return (try? decoder.decode([InterceptEvent].self, from: data)) ?? []
        }
        set {
            if let data = try? encoder.encode(newValue) {
                defaults.set(data, forKey: PersistenceKeys.codableInterceptQueue)
            }
        }
    }

    // MARK: - Raw queue drain

    /// Extension 이 기록한 원시 `[[String: Any]]` 큐를 `InterceptEvent` 로 변환 후 비운다.
    /// 원시 키 이름은 `ShieldActionExtensionHandler` 의 `enqueue` 와 동일해야 한다.
    func drainInterceptQueue() -> [InterceptEvent] {
        let raw = defaults.array(forKey: PersistenceKeys.rawInterceptQueue)
            as? [[String: Any]] ?? []

        let events: [InterceptEvent] = raw.compactMap { entry in
            guard
                let ts = entry["timestamp"] as? TimeInterval,
                let typeRaw = entry["type"] as? String,
                let subjectRaw = entry["subjectKind"] as? String,
                let type = mapType(typeRaw),
                let subjectKind = InterceptEvent.SubjectKind(rawValue: subjectRaw)
            else {
                return nil
            }
            return InterceptEvent(
                timestamp: Date(timeIntervalSince1970: ts),
                type: type,
                subjectKind: subjectKind
            )
        }

        defaults.removeObject(forKey: PersistenceKeys.rawInterceptQueue)
        return events
    }

    /// Extension 의 문자열 타입(`"intercept_requested"`, `"returned"`) → enum 변환.
    private func mapType(_ raw: String) -> InterceptEvent.EventType? {
        switch raw {
        case "returned": return .returned
        case "intercept_requested", "interceptRequested": return .interceptRequested
        default: return nil
        }
    }
}
