import Foundation
#if canImport(ActivityKit)
import ActivityKit
#endif

/// Live Activity 생명주기 관리자.
///
/// - 집중 세션 시작 시 Activity 생성 (`start`)
/// - 점수·허용 앱 개수 변화 시 업데이트 (`update`)
/// - 세션 종료 시 Activity 종료 (`end`)
///
/// iOS 16.2 미만이나 시뮬레이터에서 ActivityKit 미지원 시 모든 호출을 no-op 처리.
enum FocusActivityService {

    /// 현재 활성 Activity id. update/end 에서 식별자 기반 접근이 필요할 때.
    private static var currentActivityID: String?

    /// 집중 세션 시작. 이미 활성 Activity 가 있으면 새로 만들지 않고 update 로 상태만 갱신.
    ///
    /// 이전 구현: `endAll()` 후 `Activity.request(…)` — 그런데 endAll 이 Task 로 비동기
    /// 종료하는 동안 request 가 먼저 실행돼서 유저가 빠르게 두 번 탭하면 Dynamic Island
    /// 에 activity 가 두 개 떠 있는 race 가 있었다.
    /// 현 구현: "이미 활성이면 update" 로 단일화 — 새 세션이 아니라 같은 세션의 상태 반영.
    static func start(
        startDate: Date,
        strictEndDate: Date?,
        allowedCount: Int,
        focusScore: Int
    ) {
        #if canImport(ActivityKit)
        if #available(iOS 16.2, *) {
            // 현재 ID 가 시스템 활성 목록에 실제로 존재하면 update 경로로 보낸다.
            if let id = currentActivityID,
               Activity<FocusActivityAttributes>.activities.contains(where: { $0.id == id }) {
                update(strictEndDate: strictEndDate, allowedCount: allowedCount, focusScore: focusScore)
                return
            }

            // 어플리케이션이 모르는 사이 남은 좀비 activity 는 정리 — 중복 방지.
            endAll()

            let attributes = FocusActivityAttributes()
            let state = FocusActivityAttributes.State(
                startDate: startDate,
                strictEndDate: strictEndDate,
                allowedCount: allowedCount,
                focusScore: focusScore
            )

            do {
                let activity = try Activity.request(
                    attributes: attributes,
                    content: .init(state: state, staleDate: nil)
                )
                currentActivityID = activity.id
            } catch {
                // 권한 거부·시스템 한도 초과 등 — 조용히 실패.
                currentActivityID = nil
            }
        }
        #endif
    }

    /// 진행 중 상태 업데이트. 활성 Activity 가 없으면 no-op.
    static func update(
        strictEndDate: Date?,
        allowedCount: Int,
        focusScore: Int
    ) {
        #if canImport(ActivityKit)
        if #available(iOS 16.2, *) {
            guard let id = currentActivityID,
                  let activity = Activity<FocusActivityAttributes>.activities.first(where: { $0.id == id })
            else { return }

            // 기존 startDate 는 보존 — 재시작 없이 이어가는 개념이므로.
            let state = FocusActivityAttributes.State(
                startDate: activity.content.state.startDate,
                strictEndDate: strictEndDate,
                allowedCount: allowedCount,
                focusScore: focusScore
            )

            Task {
                await activity.update(.init(state: state, staleDate: nil))
            }
        }
        #endif
    }

    /// 세션 종료. 즉시 dismiss.
    static func end() {
        #if canImport(ActivityKit)
        if #available(iOS 16.2, *) {
            guard let id = currentActivityID,
                  let activity = Activity<FocusActivityAttributes>.activities.first(where: { $0.id == id })
            else {
                currentActivityID = nil
                return
            }

            Task {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            currentActivityID = nil
        }
        #endif
    }

    /// 앱 재진입 시 혹시 남아 있는 모든 세션을 정리.
    static func endAll() {
        #if canImport(ActivityKit)
        if #available(iOS 16.2, *) {
            Task {
                for activity in Activity<FocusActivityAttributes>.activities {
                    await activity.end(nil, dismissalPolicy: .immediate)
                }
            }
            currentActivityID = nil
        }
        #endif
    }
}
