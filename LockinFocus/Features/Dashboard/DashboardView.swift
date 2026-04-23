import SwiftUI
import FamilyControls

/// 평시 홈 대시보드. MVP 3요소: 점수 / 허용 앱 / 다음 스케줄.
struct DashboardView: View {
    @EnvironmentObject var deps: AppDependencies

    @State private var showAppPicker: Bool = false
    @State private var showScheduleEditor: Bool = false
    @State private var showSettings: Bool = false

    @State private var selection: FamilyActivitySelection = FamilyActivitySelection()
    @State private var schedule: Schedule = .weekdayWorkHours

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
    }

    private func save() {
        deps.persistence.selection = selection
        deps.persistence.schedule = schedule
        deps.blocking.applyWhitelist(for: selection)
        do {
            try deps.monitoring.startSchedule(schedule, name: "primary")
        } catch {
            // MVP: 조용히 무시.
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(AppDependencies.preview())
}
