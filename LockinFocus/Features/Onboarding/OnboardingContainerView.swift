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
                        Text("뒤로")
                    }
                    .font(.system(size: 15))
                    .foregroundStyle(AppColors.secondaryText)
                }
                .buttonStyle(.plain)
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

        // 스케줄이 꺼진 상태로 온보딩을 끝내면 shield 를 적용하지 않는다.
        // 허용 앱 0개인 경우에도 BlockingEngine 이 내부적으로 clearShield 로 폴백.
        if scheduleToSave.isEnabled {
            deps.blocking.applyWhitelist(for: draftSelection)
            try? deps.monitoring.startSchedule(scheduleToSave, name: "block_main")
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
