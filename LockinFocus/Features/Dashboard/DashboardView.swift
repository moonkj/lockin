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

    @State private var showWeeklyReport: Bool = false
    @State private var showBadges: Bool = false
    @State private var showFocusEndConfirm: Bool = false

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
        .sheet(isPresented: $showWeeklyReport) {
            WeeklyReportView()
                .environmentObject(deps)
        }
        .sheet(isPresented: $showBadges) {
            BadgesView()
                .environmentObject(deps)
        }
        .sheet(isPresented: $showFocusEndConfirm) {
            FocusEndConfirmView(onConfirm: endManualFocus)
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
                    // 바로 종료하지 않고 10초 심호흡 확인 뷰를 거친다.
                    showFocusEndConfirm = true
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
                showBadges = true
            } label: {
                Image(systemName: "rosette")
                    .font(.system(size: 20))
                    .foregroundStyle(AppColors.primaryText)
            }
            .buttonStyle(.plain)

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
    }

    /// 수동 집중 **시작** 전용. 종료는 `endManualFocus()` 가 FocusEndConfirmView 경유해서 호출.
    private func toggleManualFocus() {
        guard !isManualFocus else { return }
        deps.blocking.applyWhitelist(for: selection)
        deps.persistence.isManualFocusActive = true
        deps.persistence.manualFocusStartedAt = Date()
        BadgeEngine.onManualFocusStarted(persistence: deps.persistence)
        isManualFocus = true
    }

    /// 수동 집중 종료 — FocusEndConfirmView 에서 "종료할게요" 확정 시만 호출.
    /// 점수 규칙 B(15분 이상 → +15점) + 뱃지(누적 집중 시간, 점수, 스트릭, 주간 평균) 판정.
    private func endManualFocus() {
        let start = deps.persistence.manualFocusStartedAt
        let now = Date()
        deps.blocking.clearShield()
        deps.persistence.isManualFocusActive = false
        deps.persistence.awardSessionCompletionIfEligible(now: now)
        if let start {
            BadgeEngine.onManualFocusEnded(
                elapsed: now.timeIntervalSince(start),
                persistence: deps.persistence
            )
        }
        BadgeEngine.onScoreChanged(persistence: deps.persistence)
        isManualFocus = false
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
