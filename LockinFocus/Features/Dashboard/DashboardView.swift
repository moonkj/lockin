import SwiftUI
import FamilyControls
import WidgetKit

/// 평시 홈 대시보드. MVP 3요소: 점수 / 허용 앱 / 다음 스케줄.
/// + "지금 집중 시작/종료" 수동 토글 (스케줄과 독립).
struct DashboardView: View {
    @EnvironmentObject var deps: AppDependencies

    /// 대시보드에서 띄울 수 있는 모든 sheet 의 식별자.
    /// `.sheet(item:)` 에 바인딩해 한 번에 하나만 뜨도록 강제한다.
    /// 기존 @State Bool 9개 → 단일 enum 으로 정리.
    enum ActiveSheet: Identifiable {
        case appPicker
        case scheduleEditor
        case settings
        case weeklyReport
        case badges
        case focusEndConfirm
        case quoteDetail
        case leaderboard
        case passcodeSetup
        /// Shield 의 secondary 버튼 → 메인 앱 진입 시 자동 띄움 (10초 카운트다운).
        case intercept

        var id: String {
            switch self {
            case .appPicker:       return "appPicker"
            case .scheduleEditor:  return "scheduleEditor"
            case .settings:        return "settings"
            case .weeklyReport:    return "weeklyReport"
            case .badges:          return "badges"
            case .focusEndConfirm: return "focusEndConfirm"
            case .quoteDetail:     return "quoteDetail"
            case .leaderboard:     return "leaderboard"
            case .passcodeSetup:   return "passcodeSetup"
            case .intercept:       return "intercept"
            }
        }
    }

    @State private var activeSheet: ActiveSheet?
    @State private var showEmptyAllowConfirm: Bool = false  // confirmationDialog — 별도 API
    @State private var showStrictActiveAlert: Bool = false  // alert — 별도 API
    @State private var showStartConfirm: Bool = false       // 충동 회피 방어 — 시작 직전 1회 확인

    @State private var selection: FamilyActivitySelection
    @State private var schedule: Schedule
    @State private var isManualFocus: Bool
    @State private var toastMessage: String? = nil
    /// 7일 스트릭 히스토리 캐시 — 매 tick 마다 body 가 재평가돼도 JSON 디코드를
    /// 반복하지 않도록 load 시점에 한 번만 읽는다.
    @State private var last7DaysHistory: [DailyFocus] = []

    init() {
        _selection = State(initialValue: FamilyActivitySelection())
        _schedule = State(initialValue: .weekdayWorkHours)
        _isManualFocus = State(initialValue: false)
    }

    /// 테스트 전용 init — 초기 isManualFocus + alert/confirm 상태 주입.
    init(
        initialIsManualFocus: Bool,
        initialShowEmptyAllowConfirm: Bool = false,
        initialShowStrictActiveAlert: Bool = false,
        initialToast: String? = nil
    ) {
        _selection = State(initialValue: FamilyActivitySelection())
        _schedule = State(initialValue: .weekdayWorkHours)
        _isManualFocus = State(initialValue: initialIsManualFocus)
        _showEmptyAllowConfirm = State(initialValue: initialShowEmptyAllowConfirm)
        _showStrictActiveAlert = State(initialValue: initialShowStrictActiveAlert)
        _toastMessage = State(initialValue: initialToast)
    }

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

                    FocusScoreCard(
                        score: deps.persistence.focusScoreToday,
                        goal: deps.persistence.focusGoalScore
                    )

                    // 핀 고정된 뱃지가 있을 때만 표시 — 없으면 VStack spacing 도 절약.
                    if !deps.persistence.pinnedBadgeIDs.isEmpty {
                        PinnedBadgesStrip(
                            pinnedIDs: deps.persistence.pinnedBadgeIDs,
                            onTap: { _ in activeSheet = .badges }
                        )
                    }

                    StreakDotsCard(
                        history: last7DaysHistory,
                        freezeTokens: deps.persistence.streakFreezeToken
                    )

                    AllowedAppsCard(selection: selection) {
                        // 집중 구동 중 (수동/스케줄/엄격) 에는 허용 앱 변경으로 즉시 우회
                        // 가능하므로 잠금. 토스트로 안내.
                        switch focusButtonState {
                        case .strict:
                            toastMessage = "엄격 모드 중에는 허용 앱을 바꿀 수 없어요."
                        case .scheduleActive:
                            toastMessage = "스케줄로 차단 중에는 허용 앱을 바꿀 수 없어요."
                        case .manualActive:
                            toastMessage = "집중 중에는 허용 앱을 바꿀 수 없어요. 종료 후 변경해주세요."
                        case .idle:
                            activeSheet = .appPicker
                        }
                    }

                    NextScheduleCard(schedule: schedule, now: deps.tick) {
                        switch focusButtonState {
                        case .strict:
                            toastMessage = "엄격 모드 중에는 스케줄을 바꿀 수 없어요."
                        case .scheduleActive, .manualActive:
                            // 스케줄 변경은 회피 방어 거치므로 진입은 허용 — 저장 시
                            // ScheduleApplier 가 deferred 처리. 사용자가 이전 차단 시간
                            // 끝까지 유지된다는 사실을 토스트로 미리 안내.
                            activeSheet = .scheduleEditor
                            toastMessage = "변경해도 현재 차단은 끝까지 유지돼요."
                        case .idle:
                            activeSheet = .scheduleEditor
                        }
                    }

                    manualFocusButton

                    if allowedCount == 0 {
                        Text("허용 앱이 0개예요. 집중을 시작하면 시스템 자동 보호 앱(전화·메시지·설정) 외 대부분 앱이 잠깁니다.")
                            .scaledFont(13)
                            .foregroundStyle(AppColors.secondaryText)
                            .padding(.horizontal, 4)
                    }

                    DailyQuoteCard(onTap: { activeSheet = .quoteDetail })

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 20)
                .readingWidth()
            }
        }
        .onAppear(perform: load)
        .sheet(item: $activeSheet, onDismiss: onSheetDismiss) { sheet in
            sheetContent(sheet)
        }
        .toast(message: $toastMessage)
        .onChange(of: deps.pendingRoute) { route in
            guard let route else { return }
            switch route {
            case .weeklyReport:
                activeSheet = .weeklyReport
            case .quoteDetail:
                activeSheet = .quoteDetail
            case .startFocus:
                // Siri/Shortcut "집중 시작" — 엄격 중이거나 이미 활성이면 토스트로 안내.
                if deps.persistence.isStrictModeActive {
                    toastMessage = "엄격 모드가 켜져 있어서 시작할 수 없어요."
                } else if deps.startManualFocusFromIntent() {
                    isManualFocus = true
                    Haptics.success()
                }
            case .endFocus:
                // 엄격 중이거나 안 돌고 있으면 조용히 무시.
                if deps.endManualFocusFromIntent() {
                    isManualFocus = false
                    Haptics.success()
                }
            case .showFocusScore:
                // Siri "집중 점수 보여줘" — Dashboard 가 이미 점수를 보여주므로 추가 동작 없음.
                break
            case .intercept:
                // Shield secondary → 메인 앱 진입 시 InterceptView 시트 자동 표시.
                activeSheet = .intercept
            }
            deps.consumeRoute()
        }
    }

    /// Sheet 라우터 — activeSheet 케이스별로 화면 반환.
    @ViewBuilder
    private func sheetContent(_ sheet: ActiveSheet) -> some View {
        switch sheet {
        case .appPicker:
            AppSelectionView(selection: $selection) {
                activeSheet = nil
                save()
            }
        case .scheduleEditor:
            ScheduleEditorView(schedule: $schedule) {
                activeSheet = nil
                save()
            }
        case .settings:
            SettingsView().environmentObject(deps)
        case .weeklyReport:
            ReportView().environmentObject(deps)
        case .badges:
            BadgesView().environmentObject(deps)
        case .focusEndConfirm:
            FocusEndConfirmView(
                ordinal: deps.persistence.focusEndCountToday + 1,
                onConfirm: endManualFocus
            )
        case .quoteDetail:
            QuoteDetailSheet()
        case .leaderboard:
            LeaderboardView().environmentObject(deps)
        case .passcodeSetup:
            AppPasscodeSetupView { _ in }
        case .intercept:
            // ShieldExtension 이 이 경로에서 점수 부여 안 함 — InterceptView 가 자체 핸들.
            InterceptView(skipReturnScore: false).environmentObject(deps)
        }
    }

    /// Sheet 가 닫힐 때 호출. Settings 가 닫혀 상태가 바뀌었을 수 있으니 다시 불러온다.
    private func onSheetDismiss() {
        // 기존엔 Settings sheet 에만 onDismiss: load 가 붙어 있었다.
        // 통합 후엔 어떤 sheet 가 닫혔는지 알 수 없으니 항상 load — 비용은 UserDefaults 몇 번.
        load()
    }

    /// 스케줄 자동 차단이 활성 중인지. 매 tick 갱신.
    private var scheduleActive: Bool {
        schedule.isCurrentlyActive(at: deps.tick)
    }

    private func focusButtonIcon(_ state: FocusButtonState) -> String {
        switch state {
        case .strict: return "lock.fill"
        case .scheduleActive: return "clock.fill"
        case .manualActive: return "pause.circle.fill"
        case .idle: return "play.circle.fill"
        }
    }

    private func focusButtonLabel(_ state: FocusButtonState) -> String {
        switch state {
        case .strict: return "엄격 모드 집중 중"
        case .scheduleActive:
            if let next = schedule.nextStateChange(from: deps.tick) {
                let f = DateFormatter()
                f.dateFormat = "HH:mm"
                return "스케줄로 \(f.string(from: next))까지 집중 중"
            }
            return "스케줄로 집중 중"
        case .manualActive: return "집중 종료"
        case .idle: return "지금 집중 시작"
        }
    }

    private func focusButtonColor(_ state: FocusButtonState) -> Color {
        switch state {
        case .strict, .scheduleActive: return AppColors.secondaryText  // 회색 = 자동 / 못 끔
        case .manualActive, .idle: return AppColors.primaryText
        }
    }

    /// 버튼 상태 — 우선순위: strict > 스케줄 > manual > idle.
    private enum FocusButtonState {
        case strict          // 엄격 모드 활성 — 어떤 방법으로도 못 풀음
        case scheduleActive  // 스케줄 자동 차단 중 — 종료 시각까지 자동 풀림
        case manualActive    // 수동 집중 중 — 종료 누르면 풀림
        case idle            // 차단 안 함 — 시작 가능
    }

    private var focusButtonState: FocusButtonState {
        if deps.persistence.isStrictModeActive { return .strict }
        if scheduleActive { return .scheduleActive }
        if isManualFocus { return .manualActive }
        return .idle
    }

    @ViewBuilder
    private var manualFocusButton: some View {
        let state = focusButtonState
        Button {
            switch state {
            case .strict:
                showStrictActiveAlert = true
            case .scheduleActive:
                // 스케줄 자동 차단은 사용자가 못 끔 — 끝 시각까지 기다려야. 토스트 안내.
                if let next = schedule.nextStateChange(from: deps.tick) {
                    let f = DateFormatter()
                    f.dateFormat = "HH:mm"
                    toastMessage = "스케줄로 \(f.string(from: next))까지 집중 중이에요."
                } else {
                    toastMessage = "스케줄로 집중 중이에요."
                }
            case .manualActive:
                // 바로 종료하지 않고 10초 심호흡 확인 뷰를 거친다.
                activeSheet = .focusEndConfirm
            case .idle:
                if !AppPasscodeStore.isSet {
                    // 앱 비번이 없으면 잠금을 시작할 수 없다 — 하루 첫 해제 때 비번 입력이 필수 과정.
                    toastMessage = "앱 비밀번호를 먼저 설정해주세요."
                    activeSheet = .passcodeSetup
                } else if allowedCount == 0 {
                    showEmptyAllowConfirm = true
                } else {
                    // 충동적으로 켰다 끄기를 막기 위한 1회 확인.
                    showStartConfirm = true
                }
            }
        } label: {
            HStack {
                Image(systemName: focusButtonIcon(state))
                    .scaledFont(20)
                Text(focusButtonLabel(state))
                    .scaledFont(17, weight: .semibold)
                Spacer()
            }
            .padding(.horizontal, 20)
            .frame(height: 56)
            .foregroundStyle(Color.white)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(focusButtonColor(state))
            )
        }
        .buttonStyle(.plain)
        .confirmationDialog(
            "지금 집중 시작할까요?",
            isPresented: $showStartConfirm,
            titleVisibility: .visible
        ) {
            Button("시작") { toggleManualFocus() }
            Button("취소", role: .cancel) {}
        } message: {
            Text("시작하면 허용 앱 외에는 잠겨요. 종료하려면 10초 카운트다운 + 문장 입력 + 비밀번호 단계를 거쳐야 해요.")
        }
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
            // CLAUDE.md UX 카피 규칙: 앱 이름 노출 금지. 화면 상단은 기능 중심으로 표기.
            Text("오늘의 집중")
                .scaledFont(20, weight: .semibold)
                .foregroundStyle(AppColors.primaryText)

            Spacer()

            Button {
                activeSheet = .leaderboard
            } label: {
                Image(systemName: "trophy")
                    .scaledFont(20)
                    .foregroundStyle(AppColors.primaryText)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("랭킹 열기")

            Button {
                activeSheet = .badges
            } label: {
                Image(systemName: "rosette")
                    .scaledFont(20)
                    .foregroundStyle(AppColors.primaryText)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("뱃지 모음 열기")

            Button {
                activeSheet = .weeklyReport
            } label: {
                Image(systemName: "chart.bar")
                    .scaledFont(20)
                    .foregroundStyle(AppColors.primaryText)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("리포트 열기")

            Button {
                activeSheet = .settings
            } label: {
                Image(systemName: "gearshape")
                    .scaledFont(20)
                    .foregroundStyle(AppColors.primaryText)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("설정 열기")
        }
    }

    private func load() {
        selection = deps.persistence.selection
        schedule = deps.persistence.schedule
        isManualFocus = deps.persistence.isManualFocusActive
        // 7일 히스토리는 뷰 라이프사이클 (onAppear, 시트 닫힘) 에만 재로드. body 안에서
        // 매 tick JSON 디코드하지 않도록 @State 캐시 사용.
        last7DaysHistory = deps.persistence.dailyFocusHistory(lastDays: 7)
        // 주 1회 스트릭 보존 토큰 — 새 주가 시작됐으면 자동 지급.
        StreakEngine.grantWeeklyTokenIfNeeded(persistence: deps.persistence)
    }

    /// 수동 집중 **시작** 전용. 종료는 `endManualFocus()` 가 FocusEndConfirmView 경유해서 호출.
    private func toggleManualFocus() {
        guard !isManualFocus else { return }
        // showStartConfirm dialog 떠 있는 사이 시간 경계 도달로 strict / 스케줄이 활성된
        // 케이스 방어 — confirm 누른 시점에 다시 검증해서 혼동을 막는다.
        if deps.persistence.isStrictModeActive {
            showStrictActiveAlert = true
            return
        }
        if schedule.isCurrentlyActive(at: deps.tick) {
            // 이미 스케줄로 차단 중 — manual 시작 불필요. 종료 시각 안내.
            if let next = schedule.nextStateChange(from: deps.tick) {
                let f = DateFormatter()
                f.dateFormat = "HH:mm"
                toastMessage = "이미 스케줄로 \(f.string(from: next))까지 집중 중이에요."
            } else {
                toastMessage = "이미 스케줄로 집중 중이에요."
            }
            return
        }
        let now = Date()
        deps.blocking.applyWhitelist(for: selection)
        deps.persistence.isManualFocusActive = true
        deps.persistence.manualFocusStartedAt = now
        deps.celebrate(BadgeEngine.onManualFocusStarted(persistence: deps.persistence))
        isManualFocus = true

        FocusActivityService.start(
            startDate: now,
            strictEndDate: deps.persistence.strictModeEndAt,
            allowedCount: allowedCount,
            focusScore: deps.persistence.focusScoreToday
        )
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
        FocusActivityService.end()
        isManualFocus = false
    }

    private func save() {
        let previousSchedule = deps.persistence.schedule
        deps.persistence.selection = selection
        deps.persistence.schedule = schedule
        let result = ScheduleApplier.apply(
            schedule: schedule,
            selection: selection,
            blocking: deps.blocking,
            monitoring: deps.monitoring,
            manualFocusActive: isManualFocus,
            previousSchedule: previousSchedule
        )
        // 자기 위반 회피 방어 발동 — 사용자에게 명확히 안내.
        if result == .deferredAwaitingScheduleEnd {
            if let endAt = previousSchedule.nextStateChange(from: deps.tick) {
                let f = DateFormatter()
                f.dateFormat = "HH:mm"
                toastMessage = "현재 차단은 \(f.string(from: endAt))까지 유지돼요. 새 스케줄은 그 다음부터 적용."
            } else {
                toastMessage = "현재 차단이 끝난 뒤 새 스케줄이 적용돼요."
            }
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(AppDependencies.preview())
}
