import Foundation

/// 전역 1초 타이머. tick + strictActive 캐시 + scenePhase pause/resume.
///
/// 이전엔 AppDependencies 가 Timer + @Published tick + strictActive 캐시를 모두 보유했으나,
/// 시간 추적은 라우팅/persistence 와 책임이 다르니 별도 ObservableObject 로 분리.
/// 매초 fire 시 strictActive flip 감지 후 호출자가 등록한 핸들러를 호출 — strict 만료
/// cleanup 같은 도메인 로직은 호출자가 처리.
///
/// **scenePhase 처리**: `pause()` 로 invalidate, `resume()` 로 재시작. 백그라운드 wake-up 0.
@MainActor
final class ClockTicker: ObservableObject {

    /// 현재 tick 시각. 관찰하는 뷰가 매초 (strict 활성) 또는 10초 (비활성) 단위로 재렌더.
    @Published private(set) var tick: Date = Date()

    /// 엄격 모드 활성 캐시 — 매 호출 UserDefaults 읽기를 피하기 위해 ticker 가 관리.
    @Published private(set) var strictActive: Bool = false

    /// 매 tick 후 호출 — strictActive 갱신 이후. 호출자가 strict 만료 cleanup 등 처리.
    var afterTick: () -> Void = {}

    /// strict 활성 여부를 판단하는 provider. 보통 `persistence.isStrictModeActive` 참조.
    private let isStrictActiveProvider: () -> Bool

    private var tickTimer: Timer?

    init(initialStrictActive: Bool, isStrictActiveProvider: @escaping () -> Bool) {
        self.strictActive = initialStrictActive
        self.isStrictActiveProvider = isStrictActiveProvider
    }

    deinit {
        // tickTimer 는 main actor 에 묶여있지만 deinit 은 어디서든 호출됨.
        // Timer.invalidate() 는 thread-safe.
        tickTimer?.invalidate()
    }

    func start() {
        tickTimer?.invalidate()
        let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.onTick()
            }
        }
        tickTimer = timer
    }

    /// 백그라운드 진입 시 호출 — Timer 정지.
    func pause() {
        tickTimer?.invalidate()
        tickTimer = nil
    }

    /// 포그라운드 복귀 시 호출 — Timer 재시작 + 즉시 한 번 onTick.
    func resume() {
        guard tickTimer == nil else { return }
        onTick()
        start()
    }

    private func onTick() {
        let now = Date()
        let currentStrict = isStrictActiveProvider()

        if currentStrict != strictActive {
            strictActive = currentStrict
        }

        // strict 활성: 매초 publish. 비활성: 10초 throttle.
        let secondsSinceLastPublish = now.timeIntervalSince(tick)
        if currentStrict || secondsSinceLastPublish >= 10 {
            tick = now
        }

        afterTick()
    }
}
