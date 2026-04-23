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

    @State private var selection: FamilyActivitySelection = FamilyActivitySelection()
    @State private var schedule: Schedule = .weekdayWorkHours

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
    }

    private func save() {
        deps.persistence.selection = selection
        deps.persistence.schedule = schedule
        deps.blocking.applyWhitelist(for: selection)
        do {
            try deps.monitoring.startSchedule(schedule, name: "primary")
        } catch {
            // MVP 조용히 무시.
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppDependencies.preview())
}
