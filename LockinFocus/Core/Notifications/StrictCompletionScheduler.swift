import Foundation
import UserNotifications

/// 엄격 모드 종료 시각에 정확히 한 번 발송되는 로컬 알림.
/// 사용자가 앱 밖에 있을 때 strict 가 끝나는 순간을 감지해 축하/회고 유도.
///
/// 알림 권한은 `WeeklyReportScheduler` / `DailySummaryScheduler` 가 이미 요청했을 수
/// 있고 별도 요청은 하지 않는다. 권한이 없으면 조용히 skip — Dynamic Island / Live
/// Activity 가 이미 있으므로 백업 경로로만 동작.
enum StrictCompletionScheduler {
    private static let identifier = "lockinFocus.strictCompletion"

    /// 엄격 모드 시작 시점에 호출 — `endAt` 에 정확히 맞춘 one-shot 알림 등록.
    /// duration 은 카피에 "N시간 완료" 형태로 박는다.
    static func schedule(endAt: Date, durationSeconds: TimeInterval) {
        // 미래 시각이어야 — 과거면 즉시 발송돼 어색.
        guard endAt > Date().addingTimeInterval(1) else { return }

        let content = UNMutableNotificationContent()
        content.title = Bundle.main.localizedString(
            forKey: "엄격 모드 완료",
            value: "엄격 모드 완료",
            table: nil
        )
        let hours = Int(durationSeconds) / 3600
        let minutes = (Int(durationSeconds) % 3600) / 60
        let durationStr: String
        if hours > 0 && minutes > 0 {
            durationStr = "\(hours)시간 \(minutes)분"
        } else if hours > 0 {
            durationStr = "\(hours)시간"
        } else {
            durationStr = "\(max(1, minutes))분"
        }
        content.body = String(
            format: Bundle.main.localizedString(
                forKey: "%@ 집중을 지켰어요. 잠시 돌아보는 시간을 가져볼까요?",
                value: "%@ 집중을 지켰어요. 잠시 돌아보는 시간을 가져볼까요?",
                table: nil
            ),
            durationStr
        )
        content.sound = .default

        // 초 단위 timeInterval trigger — calendar trigger 는 시·분 단위 매칭이라 정확도 떨어짐.
        let interval = endAt.timeIntervalSinceNow
        guard interval > 0 else { return }
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        let center = UNUserNotificationCenter.current()
        // 기존 건 무효화 후 새로 등록 (엄격 재시작 대응).
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            center.add(request) { _ in }
        }
    }

    /// 엄격 모드가 사용자 명시적 취소 경로로 해제됐을 때 알림도 제거.
    static func cancel() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
