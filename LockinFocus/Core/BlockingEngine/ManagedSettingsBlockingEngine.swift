import FamilyControls
import ManagedSettings
import Foundation

/// `ManagedSettingsStore` 실구현.
///
/// MVP 전략은 **Blocklist**: 사용자가 고른 앱/카테고리만 shield 에 적용 (`.specific(...)`).
/// 고르지 않은 앱·카테고리는 자동으로 열린다 → 시스템 앱(전화/설정/카메라/지도 등)이
/// 사용자 개입 없이 자동 허용된다. 이 패턴이 Apple 공식 Screen Time 예제와 일치.
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

    func applyBlocklist(for selection: FamilyActivitySelection) {
        // 빈 selection = 차단할 것 없음. shield 전체 해제.
        let hasAnyBlocked =
            !selection.applicationTokens.isEmpty ||
            !selection.categoryTokens.isEmpty ||
            !selection.webDomainTokens.isEmpty
        guard hasAnyBlocked else {
            clearShield()
            return
        }
        // 개별 앱 차단 + 카테고리 차단.
        store.shield.applications = selection.applicationTokens.isEmpty
            ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil : .specific(selection.categoryTokens, except: [])
        store.shield.webDomains = selection.webDomainTokens.isEmpty
            ? nil : selection.webDomainTokens
        // 웹 카테고리는 Picker 에서 별도 카테고리 집합을 주지 않으므로 MVP 에선 미사용.
        store.shield.webDomainCategories = nil
    }

    func clearShield() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        store.shield.webDomainCategories = nil
    }

    /// 특정 앱 토큰 하나를 `duration` 초 동안 해제 후 자동 복원.
    /// MVP 에서는 "그래도 열기" 경로가 Shield 전체를 임시 해제하는 방식으로 단순화되어
    /// 이 메서드는 직접 사용되지 않는다. Phase 5 에서 개별 앱 단위 복원으로 확장 예정.
    func temporarilyAllow(token: ApplicationToken, for duration: TimeInterval) {
        // 현재 shield 에서 해당 토큰만 임시 제거.
        if var apps = store.shield.applications {
            apps.remove(token)
            store.shield.applications = apps.isEmpty ? nil : apps
        }
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
