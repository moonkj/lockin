import SwiftUI
import FamilyControls

/// 온보딩 5 스텝 컨테이너.
/// 1) 가치 제안
/// 2) 시스템 기본 허용 (프리셋)
/// 3) 허용 앱 선택 (FamilyActivityPicker)
/// 4) 스케줄
/// 5) 권한 요청
///
/// 흰색 배경, 단계 점 인디케이터 하단 고정.
struct OnboardingContainerView: View {
    @EnvironmentObject var deps: AppDependencies

    @State private var step: Int = 0
    @State private var draftSelection: FamilyActivitySelection = FamilyActivitySelection()
    @State private var draftSchedule: Schedule = .weekdayWorkHours
    @State private var authorizationDenied: Bool = false

    private let totalSteps = 5

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
            SystemPresetStepView(onNext: goNext)
        case 2:
            AppPickerStepView(selection: $draftSelection, onNext: goNext)
        case 3:
            ScheduleStepView(schedule: $draftSchedule, onNext: goNext)
        case 4:
            AuthorizationStepView(
                denied: $authorizationDenied,
                onAuthorize: requestAuthorization,
                onOpenSettings: openSystemSettings
            )
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
                    finishOnboarding()
                }
            } catch {
                await MainActor.run {
                    authorizationDenied = true
                }
            }
        }
    }

    private func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func finishOnboarding() {
        deps.persistence.selection = draftSelection
        deps.persistence.schedule = draftSchedule
        deps.persistence.hasCompletedOnboarding = true

        // 실구현이 들어온 경우에만 동작. Preview mock 은 noop.
        deps.blocking.applyWhitelist(for: draftSelection)
        do {
            try deps.monitoring.startSchedule(draftSchedule, name: "primary")
        } catch {
            // Phase 3: 조용히 무시. 로그는 Debugger 단계에서 추가.
        }
    }
}

#Preview {
    OnboardingContainerView()
        .environmentObject(AppDependencies.preview())
}
