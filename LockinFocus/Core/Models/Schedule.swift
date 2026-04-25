import Foundation

struct Schedule: Codable, Equatable, Hashable {
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int
    /// Calendar weekday index. 1=Sunday ... 7=Saturday.
    var weekdays: Set<Int>
    var isEnabled: Bool

    static let weekdayWorkHours = Schedule(
        startHour: 9, startMinute: 0,
        endHour: 17, endMinute: 0,
        weekdays: [2, 3, 4, 5, 6],
        isEnabled: true
    )

    static let allDay = Schedule(
        startHour: 0, startMinute: 0,
        endHour: 23, endMinute: 59,
        weekdays: [1, 2, 3, 4, 5, 6, 7],
        isEnabled: false
    )

    var startComponents: DateComponents {
        DateComponents(hour: startHour, minute: startMinute)
    }

    var endComponents: DateComponents {
        DateComponents(hour: endHour, minute: endMinute)
    }

    /// 지정한 시각이 이 스케줄의 활성 구간 안에 있는지.
    /// - 요일 일치 (Calendar.weekday 1=일 ~ 7=토)
    /// - 시간이 [start, end) 사이
    /// - `isEnabled=false` 면 항상 false
    ///
    /// 메인 앱이 스케줄을 저장한 직후 "지금 shield 를 적용할지" 판단하는 용도.
    /// DeviceActivityMonitor extension 이 OS 레벨에서 시간 도달 시 자동으로
    /// shield 를 켜고/끄지만, 앱이 활성화된 채 스케줄을 변경했을 때 즉각 반영하려면
    /// 이 판정을 거쳐야 한다.
    func isCurrentlyActive(at date: Date = Date(), calendar: Calendar = .current) -> Bool {
        guard isEnabled else { return false }
        let weekday = calendar.component(.weekday, from: date)
        guard weekdays.contains(weekday) else { return false }
        let h = calendar.component(.hour, from: date)
        let m = calendar.component(.minute, from: date)
        let nowMinutes = h * 60 + m
        let startMinutes = startHour * 60 + startMinute
        let endMinutes = endHour * 60 + endMinute
        if startMinutes <= endMinutes {
            // 같은 날 안에 끝남 (e.g. 09:00–17:00).
            return nowMinutes >= startMinutes && nowMinutes < endMinutes
        } else {
            // 자정을 넘어가는 스케줄 (e.g. 22:00–06:00). 두 구간으로 분리.
            return nowMinutes >= startMinutes || nowMinutes < endMinutes
        }
    }
}
