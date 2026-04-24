import SwiftUI
import FamilyControls

/// MVP 설정 화면.
/// - 허용 앱 재선택
/// - 스케줄 편집
/// - 앱 정보 (버전)
/// 엄격 모드 / 도파민 디톡스 / 단계별 차단 / 주간 리포트 / 초기화 는 Phase 5.
struct SettingsView: View {
    @EnvironmentObject var deps: AppDependencies
    @Environment(\.dismiss) private var dismiss

    @State private var showAppPicker: Bool = false
    @State private var showScheduleEditor: Bool = false
    @State private var showPasscodeSetup: Bool = false
    @State private var showStrictDurationPicker: Bool = false
    @State private var showNicknameSetup: Bool = false
    @State private var passcodeIsSet: Bool = AppPasscodeStore.isSet
    @State private var nickname: String? = nil
    @State private var goalScore: Int = 80
    @State private var dailySummaryOn: Bool = false
    @State private var biometricOn: Bool = false

    #if ADMIN_TOOLS_ENABLED
    @State private var versionTaps: Int = 0
    @State private var showAdminEntry: Bool = false
    @State private var showAdminPanel: Bool = false
    #endif

    @State private var selection: FamilyActivitySelection = FamilyActivitySelection()
    @State private var schedule: Schedule = .weekdayWorkHours
    private var strictEndAt: Date? { deps.persistence.strictModeEndAt }

    private var strictActive: Bool {
        deps.persistence.isStrictModeActive
    }

    private var strictRemainingText: String {
        let now = deps.tick
        guard let end = strictEndAt, end > now else { return "" }
        let total = Int(end.timeIntervalSince(now))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 { return String(format: "%d시간 %d분", h, m) }
        if m > 0 { return String(format: "%d분 %d초", m, s) }
        return String(format: "%d초", s)
    }

    /// 엄격 모드 프리셋 (라벨, 지속 시간 초).
    private let strictPresets: [(label: String, seconds: TimeInterval)] = [
        ("30분", 30 * 60),
        ("1시간", 60 * 60),
        ("2시간", 2 * 60 * 60),
        ("4시간", 4 * 60 * 60),
        ("8시간", 8 * 60 * 60)
    ]

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return v
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                List {
                    Section {
                        Button {
                            showAppPicker = true
                        } label: {
                            row(title: "허용 앱", trailing: allowedCountLabel)
                        }
                        .listRowBackground(AppColors.surface)

                        Button {
                            showScheduleEditor = true
                        } label: {
                            row(title: "스케줄", trailing: scheduleLabel)
                        }
                        .listRowBackground(AppColors.surface)

                    } header: {
                        sectionHeader("차단")
                    }

                    Section {
                        if strictActive {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("활성 중")
                                        .scaledFont(16, weight: .semibold)
                                        .foregroundStyle(AppColors.primaryText)
                                    Spacer()
                                    Text(strictRemainingText)
                                        .scaledFont(15, weight: .semibold, design: .rounded)
                                        .foregroundStyle(AppColors.accent)
                                        .monospacedDigit()
                                }
                                Text("설정한 시간이 끝나기 전에는 어떤 방법으로도 해제할 수 없어요.")
                                    .scaledFont(12)
                                    .foregroundStyle(AppColors.secondaryText)
                            }
                            .listRowBackground(AppColors.surface)
                        } else {
                            Button {
                                // 엄격 모드는 시간이 지나기 전에는 어떤 수단으로도 해제 불가 —
                                // 비번을 요구하지 않는다. 비번은 일반 모드 첫 해제 때만 쓰인다.
                                showStrictDurationPicker = true
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("엄격 모드 시작")
                                        .scaledFont(16, weight: .medium)
                                        .foregroundStyle(AppColors.primaryText)
                                    Text("설정한 시간 동안은 어떤 방법으로도 해제할 수 없어요.")
                                        .scaledFont(12)
                                        .foregroundStyle(AppColors.secondaryText)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .listRowBackground(AppColors.surface)
                        }

                        Button {
                            showPasscodeSetup = true
                        } label: {
                            HStack {
                                Text("앱 비밀번호 설정")
                                    .foregroundStyle(AppColors.primaryText)
                                Spacer()
                                Text(passcodeIsSet ? "설정됨" : "미설정")
                                    .foregroundStyle(passcodeIsSet ? AppColors.secondaryText : AppColors.warning)
                                Image(systemName: "chevron.right")
                                    .scaledFont(12, weight: .semibold)
                                    .foregroundStyle(AppColors.secondaryText)
                                    .accessibilityHidden(true)
                            }
                        }
                        .listRowBackground(AppColors.surface)
                    } header: {
                        sectionHeader("엄격 모드")
                    } footer: {
                        Text("앱 비밀번호는 일반 모드의 하루 첫 해제 때만 쓰여요. 엄격 모드는 시간이 지나기 전에는 어떤 방법으로도 풀 수 없어요.")
                            .scaledFont(12)
                            .foregroundStyle(AppColors.secondaryText)
                    }

                    Section {
                        Button {
                            showNicknameSetup = true
                        } label: {
                            HStack {
                                Text("닉네임").foregroundStyle(AppColors.primaryText)
                                Spacer()
                                Text(nickname ?? "미설정")
                                    .foregroundStyle(nickname == nil ? AppColors.warning : AppColors.secondaryText)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.trailing)
                                Image(systemName: "chevron.right")
                                    .scaledFont(12, weight: .semibold)
                                    .foregroundStyle(AppColors.secondaryText)
                                    .accessibilityHidden(true)
                            }
                        }
                        .listRowBackground(AppColors.surface)
                    } header: {
                        sectionHeader("랭킹")
                    } footer: {
                        Text("랭킹에서 다른 사용자에게 보이는 이름이에요. 욕설·성적 단어는 차단돼요.")
                            .scaledFont(12)
                            .foregroundStyle(AppColors.secondaryText)
                    }

                    Section {
                        HStack(spacing: 12) {
                            Text("오늘의 목표")
                                .foregroundStyle(AppColors.primaryText)
                            Spacer()
                            Text("\(goalScore)점")
                                .foregroundStyle(AppColors.secondaryText)
                                .monospacedDigit()
                        }
                        .listRowBackground(AppColors.surface)

                        VStack(spacing: 8) {
                            HStack {
                                ForEach([60, 80, 100], id: \.self) { preset in
                                    Button {
                                        goalScore = preset
                                        deps.persistence.focusGoalScore = preset
                                    } label: {
                                        Text("\(preset)")
                                            .scaledFont(13, weight: goalScore == preset ? .semibold : .regular)
                                            .foregroundStyle(goalScore == preset ? Color.white : AppColors.primaryText)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 32)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                    .fill(goalScore == preset ? AppColors.primaryText : AppColors.divider.opacity(0.2))
                                            )
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .listRowBackground(AppColors.surface)
                    } header: {
                        sectionHeader("집중 목표")
                    } footer: {
                        Text("대시보드에서 목표까지 남은 점수와 달성 알림을 보여줘요.")
                            .scaledFont(12)
                            .foregroundStyle(AppColors.secondaryText)
                    }

                    Section {
                        Toggle(isOn: $dailySummaryOn) {
                            Text("하루 마감 알림")
                                .foregroundStyle(AppColors.primaryText)
                        }
                        .tint(AppColors.primaryText)
                        .onChange(of: dailySummaryOn) { newValue in
                            deps.persistence.dailySummaryNotification = newValue
                            if newValue {
                                DailySummaryScheduler.enable { granted in
                                    // 권한 거부 시 UI 토글 되돌림.
                                    if !granted { dailySummaryOn = false }
                                }
                            } else {
                                DailySummaryScheduler.disable()
                            }
                        }
                        .listRowBackground(AppColors.surface)

                        if BiometricAuth.isAvailable {
                            Toggle(isOn: $biometricOn) {
                                Text("Face ID 로 잠금 해제")
                                    .foregroundStyle(AppColors.primaryText)
                            }
                            .tint(AppColors.primaryText)
                            .onChange(of: biometricOn) { newValue in
                                deps.persistence.useBiometricForPasscode = newValue
                            }
                            .listRowBackground(AppColors.surface)
                        }
                    } header: {
                        sectionHeader("알림")
                    } footer: {
                        Text("매일 밤 10시에 오늘의 점수와 연속 기록을 한 번 돌아볼 수 있어요.\n생체 인식이 실패하거나 취소하면 자동으로 6자리 비번 입력으로 돌아와요.")
                            .scaledFont(12)
                            .foregroundStyle(AppColors.secondaryText)
                    }

                    Section {
                        HStack {
                            Text("버전").foregroundStyle(AppColors.primaryText)
                            Spacer()
                            Text(appVersion).foregroundStyle(AppColors.secondaryText)
                        }
                        .contentShape(Rectangle())
                        #if ADMIN_TOOLS_ENABLED
                        .onTapGesture {
                            versionTaps += 1
                            if versionTaps >= 10 {
                                versionTaps = 0
                                showAdminEntry = true
                            }
                        }
                        #endif
                        .listRowBackground(AppColors.surface)
                    } header: {
                        sectionHeader("앱 정보")
                    }
                }
                .scrollContentBackground(.hidden)
                .background(AppColors.background)
                .readingWidth(720)
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                        .foregroundStyle(AppColors.secondaryText)
                }
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
        .sheet(isPresented: $showStrictDurationPicker) {
            StrictDurationPickerView(presets: strictPresets) { seconds in
                startStrict(duration: seconds)
            }
        }
        .sheet(isPresented: $showPasscodeSetup) {
            AppPasscodeSetupView { saved in
                if saved { passcodeIsSet = true }
            }
        }
        .sheet(isPresented: $showNicknameSetup) {
            NicknameSetupView { saved in
                nickname = saved
            }
            .environmentObject(deps)
        }
        #if ADMIN_TOOLS_ENABLED
        .sheet(isPresented: $showAdminEntry) {
            AdminEntryView { showAdminPanel = true }
        }
        .sheet(isPresented: $showAdminPanel) {
            AdminPanelView().environmentObject(deps)
        }
        #endif
    }

    /// 기본 iOS secondaryLabel 은 흰 배경 위에서 거의 안 보일 만큼 연해서
    /// 직접 primaryText + 중간 weight 로 지정해 가독성을 확보.
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .scaledFont(13, weight: .semibold)
            .foregroundStyle(AppColors.primaryText)
            .textCase(nil)
    }

    private func row(title: String, trailing: String) -> some View {
        HStack {
            Text(title).foregroundStyle(AppColors.primaryText)
            Spacer()
            Text(trailing).foregroundStyle(AppColors.secondaryText)
            Image(systemName: "chevron.right")
                .scaledFont(12, weight: .semibold)
                .foregroundStyle(AppColors.secondaryText)
                .accessibilityHidden(true)
        }
    }

    private var allowedCountLabel: String {
        selection.displayBreakdown ?? "0"
    }

    private var scheduleLabel: String {
        if !schedule.isEnabled { return "꺼짐" }
        let s = String(format: "%02d:%02d", schedule.startHour, schedule.startMinute)
        let e = String(format: "%02d:%02d", schedule.endHour, schedule.endMinute)
        return "\(s)–\(e)"
    }

    private func load() {
        selection = deps.persistence.selection
        schedule = deps.persistence.schedule
        passcodeIsSet = AppPasscodeStore.isSet
        nickname = deps.persistence.nickname
        goalScore = deps.persistence.focusGoalScore
        dailySummaryOn = deps.persistence.dailySummaryNotification
        biometricOn = deps.persistence.useBiometricForPasscode
    }

    /// 엄격 모드 시작: 종료 시각을 설정하고 즉시 shield 적용 + 수동 집중 ON.
    /// 그 시간까지 Dashboard 종료 버튼을 포함한 모든 해제 경로가 차단된다.
    private func startStrict(duration: TimeInterval) {
        let now = Date()
        let end = now.addingTimeInterval(duration)
        // start 와 end 모두 기록 — 현재 시각이 start 이전이면 시계 조작으로 판정.
        deps.persistence.strictModeStartAt = now
        deps.persistence.strictModeEndAt = end
        deps.persistence.isManualFocusActive = true
        deps.persistence.manualFocusStartedAt = now
        deps.blocking.applyWhitelist(for: selection)
        if schedule.isEnabled {
            try? deps.monitoring.startSchedule(schedule, name: "block_main")
        }

        let allowedCount = selection.applicationTokens.count
            + selection.categoryTokens.count
            + selection.webDomainTokens.count
        FocusActivityService.start(
            startDate: now,
            strictEndDate: end,
            allowedCount: allowedCount,
            focusScore: deps.persistence.focusScoreToday
        )
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
    SettingsView()
        .environmentObject(AppDependencies.preview())
}
