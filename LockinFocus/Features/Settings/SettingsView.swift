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
    @State private var showStrictUnlock: Bool = false
    @State private var showPasscodeSetup: Bool = false
    @State private var passcodeIsSet: Bool = AppPasscodeStore.isSet

    @State private var selection: FamilyActivitySelection = FamilyActivitySelection()
    @State private var schedule: Schedule = .weekdayWorkHours
    @State private var strictMode: Bool = false

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return v
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                List {
                    Section("차단") {
                        Button {
                            showAppPicker = true
                        } label: {
                            row(title: "허용 앱", trailing: allowedCountLabel)
                        }

                        Button {
                            showScheduleEditor = true
                        } label: {
                            row(title: "스케줄", trailing: scheduleLabel)
                        }

                        Button(role: .destructive) {
                            attemptEmergencyUnlock()
                        } label: {
                            Text("모든 차단 즉시 해제")
                                .foregroundStyle(AppColors.error)
                        }
                    }

                    Section {
                        Toggle(isOn: Binding(
                            get: { strictMode },
                            set: { newValue in
                                if newValue {
                                    // 앱 비번 필수. 없으면 토글을 거부하고 비번 설정으로 유도.
                                    guard passcodeIsSet else {
                                        showPasscodeSetup = true
                                        return
                                    }
                                    enableStrictMode()
                                } else {
                                    // OFF 시도 → StrictModeUnlockView 로 유도.
                                    showStrictUnlock = true
                                }
                            }
                        )) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("엄격 모드").foregroundStyle(AppColors.primaryText)
                                Text("켜면 즉시 차단이 시작되고, 해제는 30초 + 문장 입력 + 앱 비밀번호가 필요해요.")
                                    .font(.system(size: 12))
                                    .foregroundStyle(AppColors.secondaryText)
                            }
                        }
                        .tint(AppColors.primaryText)
                        .disabled(!passcodeIsSet && !strictMode)

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
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(AppColors.secondaryText)
                            }
                        }
                    } header: {
                        Text("엄격 모드")
                    } footer: {
                        Text(passcodeIsSet
                             ? "해제할 때 이 앱 비밀번호를 입력하면 됩니다. (Face ID 는 사용하지 않아요.)"
                             : "엄격 모드를 켜려면 먼저 앱 비밀번호를 설정해야 해요.")
                            .font(.system(size: 11))
                    }

                    Section("앱 정보") {
                        HStack {
                            Text("버전").foregroundStyle(AppColors.primaryText)
                            Spacer()
                            Text(appVersion).foregroundStyle(AppColors.secondaryText)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(AppColors.background)
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
        .sheet(isPresented: $showStrictUnlock) {
            StrictModeUnlockView {
                // 해제 3단계 성공 → 엄격 모드 OFF + shield 해제 동시 수행.
                strictMode = false
                deps.persistence.isStrictModeActive = false
                deps.blocking.clearShield()
                deps.persistence.isManualFocusActive = false
                deps.monitoring.stopMonitoring(name: "block_main")
                BadgeEngine.onStrictSurvived(persistence: deps.persistence)
            }
        }
        .sheet(isPresented: $showPasscodeSetup) {
            AppPasscodeSetupView { saved in
                if saved { passcodeIsSet = true }
            }
        }
    }

    private func row(title: String, trailing: String) -> some View {
        HStack {
            Text(title).foregroundStyle(AppColors.primaryText)
            Spacer()
            Text(trailing).foregroundStyle(AppColors.secondaryText)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppColors.secondaryText)
        }
    }

    private var allowedCountLabel: String {
        let c = selection.applicationTokens.count + selection.categoryTokens.count
        return "\(c)개"
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
        strictMode = deps.persistence.isStrictModeActive
        passcodeIsSet = AppPasscodeStore.isSet
    }

    /// 엄격 모드 활성화: 상태 저장 + 즉시 shield 적용 + 수동 집중 모드 강제 ON.
    /// 이로써 Dashboard 집중 종료 버튼이 눌리더라도 StrictModeUnlockView 없이는 풀 수 없다.
    private func enableStrictMode() {
        strictMode = true
        deps.persistence.isStrictModeActive = true
        deps.persistence.isManualFocusActive = true
        deps.blocking.applyWhitelist(for: selection)
        if schedule.isEnabled {
            try? deps.monitoring.startSchedule(schedule, name: "block_main")
        }
    }

    /// 엄격 모드가 켜져 있으면 긴급 해제도 Friction 을 거치게 한다.
    private func attemptEmergencyUnlock() {
        if strictMode {
            showStrictUnlock = true
        } else {
            emergencyUnlock()
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

    /// 사용자가 앱에 잠겨 다른 앱에 접근 못 할 때를 위한 긴급 탈출.
    /// shield 전체 해제 + 스케줄 모니터링 중단 + 로컬 스케줄 OFF 로 저장.
    private func emergencyUnlock() {
        deps.blocking.clearShield()
        deps.monitoring.stopMonitoring(name: "block_main")
        schedule.isEnabled = false
        deps.persistence.schedule = schedule
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppDependencies.preview())
}
