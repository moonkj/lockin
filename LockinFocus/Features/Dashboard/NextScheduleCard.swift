import SwiftUI

/// 대시보드 다음 스케줄 카드. 활성 여부 + 시작/종료 시각 + 다음 상태 변경 시각.
struct NextScheduleCard: View {
    let schedule: Schedule
    /// Dashboard 의 deps.tick (10초 throttle 비활성 시) 또는 매초 (활성 시) 갱신.
    /// 기본값은 init 시 Date() 한 번만 사용 (preview/테스트).
    var now: Date = Date()
    let onEdit: () -> Void

    private var timeRange: String {
        let start = String(format: "%02d:%02d", schedule.startHour, schedule.startMinute)
        let end = String(format: "%02d:%02d", schedule.endHour, schedule.endMinute)
        return "\(start) – \(end)"
    }

    private var weekdaysLabel: String {
        let sorted = schedule.weekdays.sorted()
        if sorted == [1, 2, 3, 4, 5, 6, 7] { return "매일" }
        if sorted == [2, 3, 4, 5, 6] { return "평일" }
        if sorted == [1, 7] { return "주말" }
        let names = ["", "일", "월", "화", "수", "목", "금", "토"]
        return sorted.map { names[$0] }.joined(separator: "·")
    }

    private var statusLine: String? {
        guard schedule.isEnabled else { return nil }
        guard let next = schedule.nextStateChange(from: now) else { return nil }
        let active = schedule.isCurrentlyActive(at: now)
        let label = active ? "끝남" : "시작"
        let cal = Calendar.current
        let nextDay = cal.startOfDay(for: next)
        let today = cal.startOfDay(for: now)
        let daysAhead = cal.dateComponents([.day], from: today, to: nextDay).day ?? 0

        let timeFmt = DateFormatter()
        timeFmt.dateFormat = "HH:mm"
        let timeStr = timeFmt.string(from: next)

        switch daysAhead {
        case 0:
            // 같은 날.
            return "오늘 \(timeStr)에 \(label)"
        case 1:
            return "내일 \(timeStr)에 \(label)"
        default:
            let names = ["", "일", "월", "화", "수", "목", "금", "토"]
            let weekdayIdx = cal.component(.weekday, from: next)
            return "\(names[weekdayIdx])요일 \(timeStr)에 \(label)"
        }
    }

    var body: some View {
        Button(action: onEdit) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("다음 스케줄")
                        .scaledFont(14, weight: .medium)
                        .foregroundStyle(AppColors.secondaryText)

                    if schedule.isEnabled {
                        Text("\(weekdaysLabel) · \(timeRange)")
                            .scaledFont(18, weight: .semibold)
                            .foregroundStyle(AppColors.primaryText)
                        if let line = statusLine {
                            Text(line)
                                .scaledFont(13)
                                .foregroundStyle(AppColors.secondaryText)
                                .padding(.top, 2)
                        }
                    } else {
                        Text("꺼짐")
                            .scaledFont(18, weight: .semibold)
                            .foregroundStyle(AppColors.secondaryText)
                    }
                }

                Spacer()

                HStack(spacing: 4) {
                    Text("편집")
                        .scaledFont(14, weight: .medium)
                        .foregroundStyle(AppColors.primaryText)
                    Image(systemName: "chevron.right")
                        .scaledFont(12, weight: .semibold)
                        .foregroundStyle(AppColors.secondaryText)
                        .accessibilityHidden(true)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppColors.surface)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 12) {
        NextScheduleCard(schedule: .weekdayWorkHours, onEdit: {})
        NextScheduleCard(schedule: .allDay, onEdit: {})
    }
    .padding(24)
    .background(AppColors.background)
}
