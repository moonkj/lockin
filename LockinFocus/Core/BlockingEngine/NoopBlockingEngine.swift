import FamilyControls
import ManagedSettings
import Foundation

/// 시뮬레이터 라이브 빌드 전용 No-op. Shield/ManagedSettings 가 시뮬레이터에서
/// 동작하지 않으므로 크래시 없이 UI 플로우만 검증하도록 모든 호출을 무시한다.
final class NoopBlockingEngine: BlockingEngine {
    func applyWhitelist(for selection: FamilyActivitySelection) {}
    func clearShield() {}
    func temporarilyAllow(token: ApplicationToken, for duration: TimeInterval) {}
}
