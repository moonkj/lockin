import SwiftUI

/// 대시보드 다음 스케줄 카드. 시작/종료 시각 + 편집 링크.
struct NextScheduleCard: View {
    let schedule: Schedule
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
