import Foundation
import Combine

/// 뱃지 축하 모달 큐 관리자.
///
/// 이전엔 AppDependencies 가 currentCelebratedBadge / badgeQueue / celebrate 를 모두
/// 보유했지만, 라이프사이클상 routing/persistence 와 무관해서 별도 ObservableObject
/// 로 분리. RootView 가 fullScreenCover 로 관찰하므로 unrelated AppDependencies 변경
/// 시 cover 영향 없도록 (re-render 비용 절감).
///
/// **Concurrency**: @MainActor — SwiftUI 바인딩 + UI 스레드 공유.
@MainActor
final class CelebrationCenter: ObservableObject {

    /// 현재 화면에 떠 있는 축하 모달. 없으면 nil.
    @Published private(set) var currentBadge: Badge?

    /// 아직 안 보여준 뱃지 대기열. 동시에 여러 개 해제되면 순차 표시.
    private var queue: [Badge] = []

    /// BadgeEngine 이 반환한 해제 뱃지를 축하 큐에 추가. 빈 배열은 무시.
    func celebrate(_ badges: [Badge]) {
        guard !badges.isEmpty else { return }
        if currentBadge == nil {
            var rest = badges
            currentBadge = rest.removeFirst()
            queue.append(contentsOf: rest)
        } else {
            queue.append(contentsOf: badges)
        }
    }

    /// 축하 모달 "확인" 에서 호출. 대기열이 남아 있으면 다음 뱃지로 넘어감.
    func dismiss() {
        if queue.isEmpty {
            currentBadge = nil
        } else {
            currentBadge = queue.removeFirst()
        }
    }
}
