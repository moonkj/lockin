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
    @State private var showEmptyAllowConfirm: Bool = false
    @State private var showStrictActiveAlert: Bool = false

    @State private var detoxSelection: FamilyActivitySelection = FamilyActivitySelection()
    @State private var isDetoxActive: Bool = false
    @State private var showDetoxPicker: Bool = false
    @State private var showWeeklyReport: Bool = false

    private var allowedCount: Int {
        selection.applicationTokens.count
        + selection.categoryTokens.count
        + selection.webDomainTokens.count
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

                    if allowedCount == 0 {
                        Text("허용 앱이 0개예요. 집중을 시작하면 시스템 자동 보호 앱(전화·메시지·설정) 외 대부분 앱이 잠깁니다.")
                            .font(.system(size: 13))
                            .foregroundStyle(AppColors.secondaryText)
                            .padding(.horizontal, 4)
                    }

                    DetoxPresetCard(
                        selection: $detoxSelection,
                        isActive: isDetoxActive,
                        onTap: toggleDetox,
                        onEdit: { showDetoxPicker = true }
                    )

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
        .sheet(isPresented: $showDetoxPicker) {
            AppSelectionView(selection: $detoxSelection) {
                showDetoxPicker = false
                deps.persistence.detoxSelection = detoxSelection
            }
        }
        .sheet(isPresented: $showWeeklyReport) {
            WeeklyReportView()
                .environmentObject(deps)
        }
    }

    @ViewBuilder
    private var manualFocusButton: some View {
        Button {
            if isManualFocus {
                // 엄격 모드 활성화 상태에서는 종료 버튼이 경고만 띄운다.
                if deps.persistence.isStrictModeActive {
                    showStrictActiveAlert = true
                } else {
                    toggleManualFocus()
                }
            } else if allowedCount == 0 {
                showEmptyAllowConfirm = true
            } else {
                toggleManualFocus()
            }
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
                    .fill(AppColors.primaryText)
            )
        }
        .buttonStyle(.plain)
        .confirmationDialog(
            "허용 앱 0개로 집중 시작",
            isPresented: $showEmptyAllowConfirm,
            titleVisibility: .visible
        ) {
            Button("시스템 앱 외 전부 잠그기", role: .destructive) {
                toggleManualFocus()
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("전화·메시지·설정은 iOS 가 자동 보호하지만 카메라·지도 등은 보호 보장이 없어요. 허용 앱 카드에서 먼저 필요한 앱을 고를 수도 있어요.")
        }
        .alert("엄격 모드 활성화 중", isPresented: $showStrictActiveAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("엄격 모드가 켜져 있어 집중을 끌 수 없어요. 설정에서 엄격 모드를 해제하면 종료할 수 있어요.")
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Text("락인 포커스")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(AppColors.primaryText)

            Spacer()

            Button {
                showWeeklyReport = true
            } label: {
                Image(systemName: "chart.bar")
                    .font(.system(size: 20))
                    .foregroundStyle(AppColors.primaryText)
            }
            .buttonStyle(.plain)

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
        detoxSelection = deps.persistence.detoxSelection
        isDetoxActive = deps.persistence.isDetoxActive
    }

    /// 도파민 디톡스 토글. 활성 시 Shield 를 디톡스 selection 으로 교체, 종료 시 원 상태 복귀.
    /// 엄격 모드가 켜져 있으면 종료를 막는다(엄격 모드 해제 흐름을 통해서만 해제 가능).
    private func toggleDetox() {
        if isDetoxActive {
            if deps.persistence.isStrictModeActive {
                showStrictActiveAlert = true
                return
            }
            // 디톡스 종료 → 평소 selection 으로 복귀 (수동 집중이 켜져있으면 유지)
            if deps.persistence.isManualFocusActive {
                deps.blocking.applyWhitelist(for: selection)
            } else {
                deps.blocking.clearShield()
            }
            deps.persistence.isDetoxActive = false
            isDetoxActive = false
        } else {
            deps.blocking.applyWhitelist(for: detoxSelection)
            deps.persistence.isDetoxActive = true
            isDetoxActive = true
            // 디톡스 중에도 수동 집중 모드로 간주(집중 종료 UI 와 일관).
            deps.persistence.isManualFocusActive = true
            isManualFocus = true
        }
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
