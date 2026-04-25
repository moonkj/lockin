import SwiftUI
import FamilyControls

/// 온보딩 6 스텝 컨테이너.
/// 1) 가치 제안
/// 2) 권한 요청 (Family Controls) — Picker 가 권한 전에는 앱 리스트를 보여주지 않으므로 먼저 수행
/// 3) 시스템 기본 허용 (프리셋)
/// 4) 허용 앱 선택 (FamilyActivityPicker)
/// 5) 스케줄
/// 6) 앱 비밀번호 (건너뛰기 가능)
///
/// 흰색 배경, 단계 점 인디케이터 하단 고정.
struct OnboardingContainerView: View {
    @EnvironmentObject var deps: AppDependencies

    @State private var step: Int
    @State private var draftSelection: FamilyActivitySelection = FamilyActivitySelection()
    @State private var draftSchedule: Schedule = .weekdayWorkHours
    @State private var authorizationDenied: Bool = false

    private let totalSteps = 6

    init(initialStep: Int = 0) {
        _step = State(initialValue: initialStep)
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                stepIndicator
                    .padding(.bottom, 24)
            }
            .readingWidth(560)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            if step > 0 {
                Button {
                    withAnimation { step -= 1 }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .accessibilityHidden(true)
                        Text("뒤로")
                    }
                    .scaledFont(15)
                    .foregroundStyle(AppColors.secondaryText)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("뒤로")
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .frame(height: 44)
    }

    // MARK: - Body

    @ViewBuilder
    private var content: some View {
        switch step {
        case 0:
            ValueStepView(onNext: goNext)
        case 1:
            AuthorizationStepView(
                denied: $authorizationDenied,
                onAuthorize: requestAuthorization,
                onOpenSettings: openSystemSettings
            )
        case 2:
            SystemPresetStepView(onNext: goNext)
        case 3:
            AppPickerStepView(selection: $draftSelection, onNext: goNext)
        case 4:
            ScheduleStepView(schedule: $draftSchedule, onNext: goNext)
        case 5:
            PasscodeStepView(onNext: goNext)
        default:
            EmptyView()
        }
    }

    // MARK: - Step indicator

    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { idx in
                Circle()
                    .fill(idx == step ? AppColors.primaryText : AppColors.divider)
                    .frame(width: 6, height: 6)
            }
        }
        .accessibilityLabel("진행 \(step + 1) / \(totalSteps)")
    }

    // MARK: - Actions

    private func goNext() {
        if step < totalSteps - 1 {
            withAnimation { step += 1 }
        } else {
            finishOnboarding()
        }
    }

    private func requestAuthorization() {
        Task {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                await MainActor.run {
                    authorizationDenied = false
                    goNext()
                }
            } catch {
                await MainActor.run { authorizationDenied = true }
            }
        }
    }

    private func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func finishOnboarding() {
        // 앱 비번이 없으면 "지금부터" 같은 즉시-잠금 스케줄을 켜둘 수 없다 —
        // 하루 첫 해제 때 비번 입력이 필수라서 풀 방법이 없어지기 때문.
        // 스케줄은 저장하되 비활성 상태로 내려두고, 사용자는 나중에 설정에서
        // 비번 등록 후 스케줄을 다시 켜면 된다.
        var scheduleToSave = draftSchedule
        if scheduleToSave.isEnabled && !AppPasscodeStore.isSet {
            scheduleToSave.isEnabled = false
        }

        deps.persistence.selection = draftSelection
        deps.persistence.schedule = scheduleToSave
        deps.persistence.hasCompletedOnboarding = true

        // **버그 수정 (2026-04-25)**: 이전 코드는 스케줄 토글이 켜져있기만 하면 즉시
        // applyWhitelist 했으나, 그러면 토요일에 평일(월-금) 스케줄을 등록하면 토요일에도
        // shield 가 켜져 잠겨버렸다. 이제 "현재 시각이 스케줄 활성 구간 안에 있을 때만"
        // shield 적용. 그 외엔 DeviceActivity 에 등록만 해두고 Extension 이 활성 시간에
        // 자동으로 켜고/끄도록 위임.
        if scheduleToSave.isEnabled {
            try? deps.monitoring.startSchedule(scheduleToSave, name: "block_main")
            if scheduleToSave.isCurrentlyActive() {
                deps.blocking.applyWhitelist(for: draftSelection)
            } else {
                deps.blocking.clearShield()
            }
        } else {
            deps.blocking.clearShield()
            deps.monitoring.stopMonitoring(name: "block_main")
        }

        // 주간 리포트 로컬 알림 등록 (권한 요청 포함).
        WeeklyReportScheduler.enable()

        // RootView 가 deps.persistence.hasCompletedOnboarding 를 다시 읽도록 강제 재렌더.
        deps.objectWillChange.send()
    }
}

#Preview {
    OnboardingContainerView()
        .environmentObject(AppDependencies.preview())
}
