import SwiftUI
import FamilyControls
import WidgetKit

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
    @State private var showQuoteDetail: Bool = false
    @State private var showLeaderboard: Bool = false
    @State private var showPasscodeSetup: Bool = false
    @State private var toastMessage: String? = nil

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

                    DailyQuoteCard(onTap: { showQuoteDetail = true })

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
        .sheet(isPresented: $showSettings, onDismiss: load) {
            SettingsView()
                .environmentObject(deps)
        }
        .sheet(isPresented: $showWeeklyReport) {
            ReportView()
                .environmentObject(deps)
        }
        .sheet(isPresented: $showBadges) {
            BadgesView()
                .environmentObject(deps)
        }
        .sheet(isPresented: $showFocusEndConfirm) {
            FocusEndConfirmView(
                ordinal: deps.persistence.focusEndCountToday + 1,
                onConfirm: endManualFocus
            )
        }
        .sheet(isPresented: $showQuoteDetail) {
            QuoteDetailSheet()
        }
        .sheet(isPresented: $showLeaderboard) {
            LeaderboardView().environmentObject(deps)
        }
        .sheet(isPresented: $showPasscodeSetup) {
            AppPasscodeSetupView { _ in }
        }
        .toast(message: $toastMessage)
        .onChange(of: deps.pendingRoute) { route in
            guard let route else { return }
            switch route {
            case .weeklyReport:
                showWeeklyReport = true
            case .quoteDetail:
                showQuoteDetail = true
            }
            deps.consumeRoute()
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
            } else if !AppPasscodeStore.isSet {
                // 앱 비번이 없으면 잠금을 시작할 수 없다 — 하루 첫 해제 때 비번 입력이 필수 과정이기 때문.
                toastMessage = "앱 비밀번호를 먼저 설정해주세요. 설정에서 등록할 수 있어요."
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
            Text(strictRemainingMessage)
        }
    }

    private var strictRemainingMessage: String {
        let remain = deps.persistence.strictModeRemainingSeconds
        guard remain > 0 else { return "엄격 모드가 켜져 있어요." }
        let total = Int(remain)
        let h = total / 3600
        let m = (total % 3600) / 60
        if h > 0 { return "엄격 모드가 끝나려면 \(h)시간 \(m)분 남았어요. 그 전에는 풀 수 없어요." }
        if m > 0 { return "엄격 모드가 끝나려면 \(m)분 남았어요. 그 전에는 풀 수 없어요." }
        return "엄격 모드가 끝나려면 \(total)초 남았어요."
    }

    private var header: some View {
        HStack(spacing: 12) {
            Text("락인 포커스")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(AppColors.primaryText)

            Spacer()

            Button {
                showLeaderboard = true
            } label: {
                Image(systemName: "trophy")
                    .font(.system(size: 20))
                    .foregroundStyle(AppColors.primaryText)
            }
            .buttonStyle(.plain)

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
        deps.celebrate(BadgeEngine.onManualFocusStarted(persistence: deps.persistence))
        isManualFocus = true
    }

    /// 수동 집중 종료 — FocusEndConfirmView 에서 "종료할게요" 확정 시만 호출.
    /// 점수 규칙 B(15분 이상 → +15점) + 뱃지(누적 집중 시간, 점수, 스트릭, 주간 평균) 판정.
    private func endManualFocus() {
        let start = deps.persistence.manualFocusStartedAt
        let now = Date()
        deps.blocking.clearShield()
        deps.persistence.isManualFocusActive = false
        deps.persistence.recordManualFocusEnd()
        deps.persistence.awardSessionCompletionIfEligible(now: now)
        var unlocked: [Badge] = []
        if let start {
            unlocked.append(contentsOf: BadgeEngine.onManualFocusEnded(
                elapsed: now.timeIntervalSince(start),
                persistence: deps.persistence
            ))
        }
        unlocked.append(contentsOf: BadgeEngine.onScoreChanged(persistence: deps.persistence))
        deps.celebrate(unlocked)
        WidgetCenter.shared.reloadTimelines(ofKind: "LockinFocusScoreWidget")
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
