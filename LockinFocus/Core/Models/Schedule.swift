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

    /// 활성/비활성 상태가 다음 번에 바뀌는 시각.
    /// - 활성 중이면 → 종료 시각 (오늘 또는 다음 활성 요일의 end)
    /// - 비활성이면 → 다음 활성 시작 시각
    /// - `isEnabled=false` 또는 weekdays 비어있으면 nil.
    ///
    /// 최대 8일 (오늘 포함) 까지 forward search — 그 안에 매칭이 없으면 nil.
    func nextStateChange(from date: Date = Date(), calendar: Calendar = .current) -> Date? {
        guard isEnabled, !weekdays.isEmpty else { return nil }
        let active = isCurrentlyActive(at: date, calendar: calendar)
        if active {
            // 종료 시각 — 오늘 또는 다음 활성 요일의 end. 단순화: 오늘이 활성 weekday 면
            // 오늘 endHour:endMinute (자정 wrap 이면 다음 날 endHour:endMinute).
            let today = calendar.startOfDay(for: date)
            let startMinutes = startHour * 60 + startMinute
            let endMinutes = endHour * 60 + endMinute
            if startMinutes <= endMinutes {
                // 같은 날 안에 끝남.
                return calendar.date(bySettingHour: endHour, minute: endMinute, second: 0, of: today)
            } else {
                // 자정 wrap: 시작이 어제였으면 오늘의 end, 시작이 오늘이면 내일의 end.
                let nowMinutes = calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)
                if nowMinutes >= startMinutes {
                    // 오늘 시작 → 내일 endHour 종료.
                    let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
                    return calendar.date(bySettingHour: endHour, minute: endMinute, second: 0, of: tomorrow)
                } else {
                    // 어제 시작 → 오늘 endHour 종료.
                    return calendar.date(bySettingHour: endHour, minute: endMinute, second: 0, of: today)
                }
            }
        } else {
            // 비활성 — forward 8 일 search 로 다음 활성 시작 찾기.
            for offset in 0..<8 {
                guard let day = calendar.date(byAdding: .day, value: offset, to: date) else { continue }
                let weekday = calendar.component(.weekday, from: day)
                guard weekdays.contains(weekday) else { continue }
                let dayStart = calendar.startOfDay(for: day)
                guard let candidate = calendar.date(bySettingHour: startHour, minute: startMinute, second: 0, of: dayStart) else { continue }
                if candidate > date { return candidate }
            }
            return nil
        }
    }
}
