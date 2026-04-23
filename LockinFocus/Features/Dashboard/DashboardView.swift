import SwiftUI
import FamilyControls

/// 평시 홈 대시보드. MVP 3요소: 점수 / 허용 앱 / 다음 스케줄.
/// + "지금 집중 시작/종료" 수동 토글 (스케줄과 독립).
struct DashboardView: View {
    @EnvironmentObject var deps: AppDependencies

    @State private var showAppPicker: Bool = false
    @State private var showScheduleEditor: Bool = false
    @State private var showSettings: Bool = false

    @State private var selection: FamilyActivitySelection = FamilyActivitySelection()
    @State private var schedule: Schedule = .weekdayWorkHours
    @State private var isManualFocus: Bool = false

    private var hasAnyAllowed: Bool {
        !selection.applicationTokens.isEmpty ||
        !selection.categoryTokens.isEmpty ||
        !selection.webDomainTokens.isEmpty
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                        .padding(.top, 8)

                    FocusScoreCard(score: deps.persistence.focusScoreToday)

                    AllowedAppsCard(selection: selection) {
                        showAppPicker = true
                    }

                    NextScheduleCard(schedule: schedule) {
                        showScheduleEditor = true
                    }

                    manualFocusButton

                    if !hasAnyAllowed {
                        Text("허용 앱이 아직 없어서 실제 차단은 꺼져 있어요. 먼저 허용 앱을 골라주세요.")
                            .font(.system(size: 13))
                            .foregroundStyle(AppColors.warning)
                            .padding(.horizontal, 4)
                    }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 20)
            }
        }
        .onAppear(perform: load)
        .sheet(isPresented: $showAppPicker) {
            AppSelectionView(selection: $selection) {
                showAppPicker = false
                save()
            }
        }
        .sheet(isPresented: $showScheduleEditor) {
            ScheduleEditorView(schedule: $schedule) {
                showScheduleEditor = false
                save()
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(deps)
        }
    }

    @ViewBuilder
    private var manualFocusButton: some View {
        Button {
            toggleManualFocus()
        } label: {
            HStack {
                Image(systemName: isManualFocus ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 20))
                Text(isManualFocus ? "집중 종료" : "지금 집중 시작")
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
            }
            .padding(.horizontal, 20)
            .frame(height: 56)
            .foregroundStyle(Color.white)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(hasAnyAllowed ? AppColors.primaryText : AppColors.primaryText.opacity(0.3))
            )
        }
        .buttonStyle(.plain)
        .disabled(!hasAnyAllowed)
    }

    private var header: some View {
        HStack {
            Text("락인 포커스")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(AppColors.primaryText)

            Spacer()

            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 20))
                    .foregroundStyle(AppColors.primaryText)
            }
            .buttonStyle(.plain)
        }
    }

    private func load() {
        selection = deps.persistence.selection
        schedule = deps.persistence.schedule
        isManualFocus = deps.persistence.isManualFocusActive
    }

    /// 수동 집중 모드 토글. 스케줄과 독립적이며, 즉시 shield 적용/해제한다.
    private func toggleManualFocus() {
        if isManualFocus {
            deps.blocking.clearShield()
            deps.persistence.isManualFocusActive = false
            isManualFocus = false
        } else {
            deps.blocking.applyWhitelist(for: selection)
            deps.persistence.isManualFocusActive = true
            isManualFocus = true
        }
    }

    private func save() {
        deps.persistence.selection = selection
        deps.persistence.schedule = schedule

        if schedule.isEnabled {
            deps.blocking.applyWhitelist(for: selection)
            try? deps.monitoring.startSchedule(schedule, name: "block_main")
        } else {
            deps.blocking.clearShield()
            deps.monitoring.stopMonitoring(name: "block_main")
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(AppDependencies.preview())
}
