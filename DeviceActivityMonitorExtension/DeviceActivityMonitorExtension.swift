import DeviceActivity
import FamilyControls
import ManagedSettings
import Foundation

/// 스케줄(예: 평일 9–17시) 구간 진입·종료·임계값 도달 이벤트를 처리한다.
/// 실제 차단(shield) 적용/해제는 ManagedSettingsStore 를 통해 이루어진다.
/// Extension 메모리/실행시간 제한이 있으니 무거운 로직은 메인 앱에서 처리한다.
///
/// activity 이름 규약:
/// - `block_main` : 주 스케줄 (selection 기반 whitelist 적용/해제)
/// - `temp_allow_*` : "그래도 열기" 5분 일시 해제 구간 — 종료 시 주 shield 복원
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    private let store = ManagedSettingsStore(named: .lockinPrimary)

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        if activity.rawValue == ExtensionActivityName.blockMain {
            applyBlocklistFromStore()
        }
        // temp_allow_* 구간 시작 시점에는 기존 shield 상태를 유지 (메인 앱에서
        // 이미 예외 토큰을 추가한 상태이므로 추가 작업 불필요).
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        if activity.rawValue.hasPrefix(ExtensionActivityName.tempAllowPrefix) {
            // 일시 해제 종료 → 주 shield 복원.
            applyBlocklistFromStore()
        } else if activity.rawValue == ExtensionActivityName.blockMain {
            // 주 스케줄 종료 → shield 전체 해제.
            clearShield()
        }
    }

    override func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        super.eventDidReachThreshold(event, activity: activity)
        // MVP: 단계별 차단(Progressive) 미사용. 로깅만.
    }

    // MARK: - Shield ops

    private func applyBlocklistFromStore() {
        let selection = readFamilySelection()
        // 빈 selection = 차단할 것 없음. shield 전체 해제.
        let hasAnyBlocked =
            !selection.applicationTokens.isEmpty ||
            !selection.categoryTokens.isEmpty ||
            !selection.webDomainTokens.isEmpty
        guard hasAnyBlocked else {
            clearShield()
            return
        }
        store.shield.applications = selection.applicationTokens.isEmpty
            ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil : .specific(selection.categoryTokens, except: [])
        store.shield.webDomains = selection.webDomainTokens.isEmpty
            ? nil : selection.webDomainTokens
        store.shield.webDomainCategories = nil
    }

    private func clearShield() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        store.shield.webDomainCategories = nil
    }

    // MARK: - Shared storage

    private func readFamilySelection() -> FamilyActivitySelection {
        guard
            let defaults = UserDefaults(suiteName: ExtensionAppGroup.identifier),
            let data = defaults.data(forKey: ExtensionSharedKeys.familySelection),
            let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
        else {
            return FamilyActivitySelection()
        }
        return selection
    }
}

// MARK: - Extension-local constants
// 메인 앱 소스(Core/Shared/AppGroup.swift) 를 공유하지 않으므로 Extension 안에서 재선언.
// 메인 앱 쪽 상수와 반드시 일치시킨다.

private enum ExtensionAppGroup {
    static let identifier = "group.com.moonkj.LockinFocus"
}

private enum ExtensionSharedKeys {
    static let familySelection = "familySelection"
}

private enum ExtensionActivityName {
    static let blockMain = "block_main"
    static let tempAllowPrefix = "temp_allow_"
}

private extension ManagedSettingsStore.Name {
    static let lockinPrimary = Self("com.moonkj.LockinFocus.primary")
}
