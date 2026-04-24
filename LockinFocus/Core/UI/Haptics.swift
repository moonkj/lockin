import UIKit

/// 앱 공통 햅틱 피드백. 중요한 순간에만 미세하게 — 사용자 주의를 흩뜨리지 않는 수준.
///
/// 사용처:
/// - 뱃지 획득 축하 모달 "확인" (`success`)
/// - Intercept 화면 "돌아가기" (`success`)
/// - 엄격 모드 자동 만료 (`success`)
/// - 허용 앱 0개 경고 다이얼로그 (`warning`)
/// - 닉네임 검증 실패 / 비번 틀림 (`error`)
///
/// iOS 접근성 설정 "진동 활성화" 가 꺼져 있으면 시스템이 자동으로 무시하므로
/// 별도 분기 불필요.
enum Haptics {
    /// 성공적인 액션 완료 — 짧고 긍정적.
    static func success() {
        let g = UINotificationFeedbackGenerator()
        g.notificationOccurred(.success)
    }

    /// 주의 필요 — 짧고 조심스러운 두 번.
    static func warning() {
        let g = UINotificationFeedbackGenerator()
        g.notificationOccurred(.warning)
    }

    /// 에러 — 두 번의 짧은 진동.
    static func error() {
        let g = UINotificationFeedbackGenerator()
        g.notificationOccurred(.error)
    }

    /// 가벼운 선택 — 토글, 탭 전환 등에.
    static func selection() {
        let g = UISelectionFeedbackGenerator()
        g.selectionChanged()
    }

    /// 임팩트 — 카드가 떨어지거나 닫히는 순간 등.
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let g = UIImpactFeedbackGenerator(style: style)
        g.impactOccurred()
    }
}
