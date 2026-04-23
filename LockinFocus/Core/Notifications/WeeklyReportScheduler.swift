import Foundation
import UserNotifications

/// 주간 리포트 로컬 알림 관리자.
/// 매주 일요일 20:00 고정 발송 (UNCalendarNotificationTrigger `repeats: true`).
enum WeeklyReportScheduler {
    private static let identifier = "lockinFocus.weeklyReport"

    /// 사용자에게 알림 권한을 요청하고, 승인되면 일요일 20:00 반복 알림을 등록.
    static func enable(completion: @escaping (Bool) -> Void = { _ in }) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            guard granted else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            schedule()
            DispatchQueue.main.async { completion(true) }
        }
    }

    /// 이미 권한이 있을 때 직접 스케줄만 (앱 시작 시 갱신용).
    static func reschedule() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            schedule()
        }
    }

    /// 알림 해제.
    static func disable() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    // MARK: - Private

    private static func schedule() {
        let content = UNMutableNotificationContent()
        content.title = "이번 주 집중 돌아보기"
        content.body = "짧은 주간 리포트가 준비됐어요. 지난 7일의 집중 흐름을 확인해 보세요."
        content.sound = .default

        var comps = DateComponents()
        comps.weekday = 1      // Sunday (Calendar.Component 기준, 1 = Sunday)
        comps.hour = 20
        comps.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.add(request) { _ in }
    }
}
