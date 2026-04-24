import SwiftUI

/// 온보딩 Step 4 — 스케줄 프리셋 3 + 커스텀 진입.
/// MVP 는 프리셋 선택만. 커스텀은 이후 `ScheduleEditorView` 재사용.
struct ScheduleStepView: View {
    @Binding var schedule: Schedule
    let onNext: () -> Void

    enum Preset: String, CaseIterable, Identifiable {
        case now, weekdayWork, custom
        var id: String { rawValue }

        var title: String {
            switch self {
            case .now: return "지금부터"
            case .weekdayWork: return "평일 09:00 – 17:00"
            case .custom: return "직접 설정"
            }
        }

        var subtitle: String {
            switch self {
            case .now: return "수동으로 끄기 전까지 계속"
            case .weekdayWork: return "월 – 금, 업무 시간대"
            case .custom: return "요일과 시간을 직접 고르기"
            }
        }
    }

    @State private var selected: Preset = .weekdayWork
    @State private var showEditor: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("집중 시간대를 골라주세요")
                    .scaledFont(28, weight: .semibold)
                    .foregroundStyle(AppColors.primaryText)

                Text("나중에 언제든 바꿀 수 있어요.")
                    .scaledFont(15)
                    .foregroundStyle(AppColors.secondaryText)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)

            VStack(spacing: 12) {
                ForEach(Preset.allCases) { preset in
                    presetRow(preset)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            PrimaryButton("다음", action: applyAndNext)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
        }
        .sheet(isPresented: $showEditor) {
            ScheduleEditorView(schedule: $schedule) {
                showEditor = false
            }
        }
    }

    private func presetRow(_ preset: Preset) -> some View {
        Button {
            selected = preset
            if preset == .custom {
                showEditor = true
            }
        } label: {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(selected == preset ? AppColors.primaryText : AppColors.divider, lineWidth: 1.5)
                        .frame(width: 20, height: 20)
                    if selected == preset {
                        Circle()
                            .fill(AppColors.primaryText)
                            .frame(width: 10, height: 10)
                    }
                }
                .padding(.top, 2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(preset.title)
                        .scaledFont(16, weight: .medium)
                        .foregroundStyle(AppColors.primaryText)
                    Text(preset.subtitle)
                        .scaledFont(13)
                        .foregroundStyle(AppColors.secondaryText)
                }

                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(selected == preset ? AppColors.primaryText : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func applyAndNext() {
        switch selected {
        case .now:
            schedule = Schedule(
                startHour: 0, startMinute: 0,
                endHour: 23, endMinute: 59,
                weekdays: [1, 2, 3, 4, 5, 6, 7],
                isEnabled: true
            )
        case .weekdayWork:
            schedule = .weekdayWorkHours
        case .custom:
            // 커스텀은 이미 sheet 에서 설정됨.
            break
        }
        onNext()
    }
}

#Preview {
    ScheduleStepView(schedule: .constant(.weekdayWorkHours), onNext: {})
        .background(AppColors.background)
}
