import SwiftUI

/// 커스텀 스케줄 편집. 요일 토글 + 시작/종료 시간.
/// 엄격 모드 토글은 Phase 5 이므로 UI 에 노출 안 함.
struct ScheduleEditorView: View {
    @Binding var schedule: Schedule
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss

    private let weekdayLabels: [(Int, String)] = [
        (2, "월"), (3, "화"), (4, "수"), (5, "목"),
        (6, "금"), (7, "토"), (1, "일")
    ]

    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("요일")
                                .scaledFont(14, weight: .medium)
                                .foregroundStyle(AppColors.secondaryText)

                            HStack(spacing: 8) {
                                ForEach(weekdayLabels, id: \.0) { pair in
                                    let active = schedule.weekdays.contains(pair.0)
                                    Button {
                                        toggleWeekday(pair.0)
                                    } label: {
                                        Text(pair.1)
                                            .scaledFont(14, weight: .medium)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 40)
                                            .foregroundStyle(active ? Color.white : AppColors.primaryText)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                    .fill(active ? AppColors.primaryText : AppColors.surface)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("시간")
                                .scaledFont(14, weight: .medium)
                                .foregroundStyle(AppColors.secondaryText)

                            VStack(spacing: 0) {
                                DatePicker("시작", selection: $startDate, displayedComponents: .hourAndMinute)
                                    .datePickerStyle(.compact)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)

                                Rectangle()
                                    .fill(AppColors.divider)
                                    .frame(height: 0.5)

                                DatePicker("종료", selection: $endDate, displayedComponents: .hourAndMinute)
                                    .datePickerStyle(.compact)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(AppColors.surface)
                            )
                        }

                        Toggle(isOn: Binding(
                            get: { schedule.isEnabled },
                            set: { schedule.isEnabled = $0 }
                        )) {
                            Text("이 스케줄 사용")
                                .scaledFont(15)
                                .foregroundStyle(AppColors.primaryText)
                        }
                        .tint(AppColors.primaryText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(AppColors.surface)
                        )

                        PrimaryButton("저장") {
                            commit()
                            onSave()
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("스케줄")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                        .foregroundStyle(AppColors.secondaryText)
                }
            }
        }
        .onAppear(perform: load)
    }

    // MARK: - Helpers

    private func toggleWeekday(_ w: Int) {
        if schedule.weekdays.contains(w) {
            schedule.weekdays.remove(w)
        } else {
            schedule.weekdays.insert(w)
        }
    }

    private func load() {
        let cal = Calendar.current
        startDate = cal.date(bySettingHour: schedule.startHour, minute: schedule.startMinute, second: 0, of: Date()) ?? Date()
        endDate = cal.date(bySettingHour: schedule.endHour, minute: schedule.endMinute, second: 0, of: Date()) ?? Date()
    }

    private func commit() {
        let cal = Calendar.current
        let sc = cal.dateComponents([.hour, .minute], from: startDate)
        let ec = cal.dateComponents([.hour, .minute], from: endDate)
        schedule.startHour = sc.hour ?? schedule.startHour
        schedule.startMinute = sc.minute ?? schedule.startMinute
        schedule.endHour = ec.hour ?? schedule.endHour
        schedule.endMinute = ec.minute ?? schedule.endMinute
    }
}

#Preview {
    ScheduleEditorView(schedule: .constant(.weekdayWorkHours), onSave: {})
}
