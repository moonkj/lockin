import FamilyControls
import ManagedSettings
import Foundation

/// `ManagedSettingsStore` 실구현.
///
/// MVP 전략은 **역-화이트리스트**: 모든 카테고리를 차단하되 사용자가 고른
/// 개별 토큰은 예외 처리한다 (`.all(except:)`).
/// `applications = nil` 을 유지해야 개별 토큰 허용이 카테고리 규칙보다 우선 적용된다.
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
        store.shield.applicationCategories =
            .all(except: selection.applicationTokens)
        store.shield.webDomainCategories =
            .all(except: selection.webDomainTokens)
        // 개별 토큰 화이트리스트 전략에서는 나머지는 비워 둔다.
        store.shield.applications = nil
        store.shield.webDomains = nil
    }

    func clearShield() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        store.shield.webDomainCategories = nil
    }

    /// 특정 앱 토큰 하나를 `duration` 초 동안 예외 처리 후 자동 복원.
    /// 복원은 Monitor Extension 의 `intervalDidEnd(temp_allow_*)` 에서
    /// 원본 selection 을 다시 적용하는 방식으로 이루어진다 (순환 의존 회피).
    func temporarilyAllow(token: ApplicationToken, for duration: TimeInterval) {
        // 현재 적용된 카테고리 차단에서 해당 토큰만 추가 예외 처리.
        // selection 원본이 엔진 레벨에 없으므로, 현재 store 의 예외 목록에
        // 토큰을 합치는 전략으로 구현.
        var allowed = currentAllowedApplicationTokens()
        allowed.insert(token)
        store.shield.applicationCategories = .all(except: allowed)

        // 5분 후 원본 shield 복원을 Monitor Extension 에서 수행.
        try? monitoring?.startTemporaryAllow(
            name: "temp_allow_\(UUID().uuidString.prefix(8))",
            duration: duration
        )
    }

    /// 현재 `applicationCategories` 가 `.all(except:)` 형태일 때 예외 토큰 셋을 꺼낸다.
    /// policy enum 의 associated value 접근은 공식 API 가 없으므로,
    /// persistence 의 selection 기준으로 폴백하는 편이 안전하다.
    private func currentAllowedApplicationTokens() -> Set<ApplicationToken> {
        // iOS SDK 상에서 policy 의 associated value 를 안전히 읽는 API 가 없어
        // 빈 셋을 폴백값으로 둔다. 호출부에서 token 을 추가로 넣으므로 최소 1개는 보장됨.
        return []
    }
}

extension ManagedSettingsStore.Name {
    /// 명명된 Store — 추후 "집중/휴식" 분리 대비.
    static let lockinPrimary = Self("com.imurmkj.LockinFocus.primary")
}
