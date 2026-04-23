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
}
