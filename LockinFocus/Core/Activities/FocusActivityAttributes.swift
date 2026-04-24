import Foundation
#if canImport(ActivityKit)
import ActivityKit
#endif

/// Live Activity 속성 — 집중 세션이 활성 중일 때 Lock Screen + Dynamic Island
/// 에 남은 시간·상태를 보여준다.
///
/// 정적 속성 (`Attributes`) 은 시작 시 고정. 동적 상태 (`ContentState`) 는
/// `Activity.update(...)` 로 갱신된다.
///
/// 메인 앱 + 위젯 타깃 양쪽 모두에 포함되어야 직렬화 호환성이 유지된다.
#if canImport(ActivityKit)
@available(iOS 16.2, *)
public struct FocusActivityAttributes: ActivityAttributes {
    public typealias ContentState = State

    public struct State: Codable, Hashable {
        /// 집중 세션 시작 시각. 경과 시간 계산용.
        public let startDate: Date
        /// 엄격 모드 만료 시각. 일반 모드면 nil (무기한 ~ 사용자가 종료).
        public let strictEndDate: Date?
        /// 허용된 앱·카테고리 총 개수. 0 이면 사실상 모든 앱 잠금.
        public let allowedCount: Int
        /// 오늘의 집중 점수 (0~100).
        public let focusScore: Int

        public init(
            startDate: Date,
            strictEndDate: Date?,
            allowedCount: Int,
            focusScore: Int
        ) {
            self.startDate = startDate
            self.strictEndDate = strictEndDate
            self.allowedCount = allowedCount
            self.focusScore = focusScore
        }

        /// 엄격 모드면 true. UI 분기에 사용.
        public var isStrict: Bool { strictEndDate != nil }
    }

    public init() {}
}
#endif
