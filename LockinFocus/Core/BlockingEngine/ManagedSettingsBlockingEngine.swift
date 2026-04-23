import FamilyControls
import ManagedSettings
import Foundation

/// `ManagedSettingsStore` 실구현.
///
/// 전략: **Whitelist (`.all(except: applicationTokens)`)** — 사용자가 고른 개별 앱만 예외,
/// 나머지는 전부 잠금. 빈 selection 은 "모든 앱 잠김" (시스템 자동 보호 앱 제외).
/// 카테고리 토큰은 Apple API 상 예외 처리 불가이므로 Whitelist 모드에서는 무시된다.
final class ManagedSettingsBlockingEngine: BlockingEngine {
    private let store: ManagedSettingsStore
    /// `temporarilyAllow` 의 5분 타이머 트리거용. 없을 수도 있어 옵셔널.
    private weak var monitoring: MonitoringEngine?

    init(
        store: ManagedSettingsStore = ManagedSettingsStore(named: .lockinPrimary),
        monitoring: MonitoringEngine? = nil
    ) {
        self.store = store
        self.monitoring = monitoring
    }

    /// 순환 주입을 피하기 위한 후주입.
    func bind(monitoring: MonitoringEngine) {
        self.monitoring = monitoring
    }

    // MARK: - BlockingEngine

    func applyWhitelist(for selection: FamilyActivitySelection) {
        // 빈 selection 도 허용 — 모든 카테고리 전체 차단 (시스템 자동 보호 앱만 예외).
        store.shield.applicationCategories =
            .all(except: selection.applicationTokens)
        store.shield.webDomainCategories =
            .all(except: selection.webDomainTokens)
        // Whitelist 전략에서는 개별 앱 지정은 비워 둔다 (카테고리 규칙이 전체 커버).
        store.shield.applications = nil
        store.shield.webDomains = nil
    }

    func clearShield() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        store.shield.webDomainCategories = nil
    }

    /// 특정 앱 토큰 하나를 `duration` 초 동안 해제 후 자동 복원.
    /// Whitelist 에서는 `applicationCategories = .all(except: allowed + token)` 방식으로 추가.
    /// MVP 에서는 InterceptView 가 Shield 전체 해제 + 5분 재적용 패턴을 사용하므로 미호출.
    func temporarilyAllow(token: ApplicationToken, for duration: TimeInterval) {
        try? monitoring?.startTemporaryAllow(
            name: "temp_allow_\(UUID().uuidString.prefix(8))",
            duration: duration
        )
    }
}

extension ManagedSettingsStore.Name {
    /// 명명된 Store — 추후 "집중/휴식" 분리 대비.
    static let lockinPrimary = Self("com.moonkj.LockinFocus.primary")
}
