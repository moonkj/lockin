import Foundation
import UserNotifications

/// 하루 마감 요약 로컬 알림 (22:00).
/// 사용자가 앱을 안 열어도 오늘 점수·연속 기록을 한 번 돌아보는 retention loop.
///
/// 동적 본문을 만들기 어려운 static 트리거라서 고정 카피 + 점수 세부는 사용자가
/// 탭했을 때 앱 내 Dashboard 에서 확인하도록 유도. (UserNotifications 의 calendar
/// repeating trigger 는 매일 같은 content 로 발송됨.)
enum DailySummaryScheduler {
    private static let identifier = "lockinFocus.dailySummary"

    /// 권한 요청 후 스케줄 등록.
    /// - 이미 거부된 상태면 system prompt 가 안 뜨고 즉시 false → 사용자 입장에선
    ///   "토글이 안 켜진다" 로 보임. 사전에 status 를 확인해 호출부에 명확한 신호 전달.
    static func enable(completion: @escaping (Bool) -> Void = { _ in }) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .denied:
                // 거부 상태 — request 시도해도 false 반환만 받게 됨. 호출부가 alert 띄우도록.
                DispatchQueue.main.async { completion(false) }
            case .authorized, .provisional, .ephemeral:
                schedule()
                DispatchQueue.main.async { completion(true) }
            case .notDetermined:
                fallthrough
            @unknown default:
                center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                    if granted { schedule() }
                    DispatchQueue.main.async { completion(granted) }
                }
            }
        }
    }

    /// 알림 해제.
    static func disable() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    /// 이미 권한이 있을 때 없으면 등록 (앱 시작 시 사용자 토글이 on 이면 호출).
    static func rescheduleIfEnabled(when isOn: Bool) {
        guard isOn else {
            disable()
            return
        }
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            center.getPendingNotificationRequests { requests in
                if requests.contains(where: { $0.identifier == identifier }) { return }
                schedule()
            }
        }
    }

    private static func schedule() {
        let content = UNMutableNotificationContent()
        // Bundle.main.localizedString 가 .strings 에서 언어에 맞게 찾아준다.
        content.title = Bundle.main.localizedString(
            forKey: "오늘의 집중 돌아보기",
            value: "오늘의 집중 돌아보기",
            table: nil
        )
        content.body = Bundle.main.localizedString(
            forKey: "오늘 하루의 점수와 연속 기록을 한 번 돌아보세요.",
            value: "오늘 하루의 점수와 연속 기록을 한 번 돌아보세요.",
            table: nil
        )
        content.sound = .default

        var comps = DateComponents()
        comps.hour = 22
        comps.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.add(request) { _ in }
    }
}
