import SwiftUI
import WidgetKit

/// 차단 앱 실행 후 Shield → 메인 앱으로 돌아온 사용자에게 10초의 자각 공간을 제공.
/// 쟁점 3: MVP countdown 1종만. variant 는 Phase 5.
/// 쟁점 5: "그래도 열기" 는 MVP 단순화로 Shield **전체**를 5분 일시 해제 후 재차단.
///         원래 UX 는 "해당 앱만" 이지만, Extension 이 `ApplicationToken` 을 App Group 큐에
///         안정적으로 직렬화하지 못하는 현재 한계에 맞춰 단순화. Tasklist.md 에 기록.
struct InterceptView: View {
    @EnvironmentObject var deps: AppDependencies
    @Environment(\.dismiss) private var dismiss

    @State private var totalSeconds: Int = 10
    @State private var remaining: Int = 10
    @State private var timer: Timer?

    private var canExit: Bool { remaining == 0 }
    private var strictActive: Bool { deps.persistence.isStrictModeActive }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                timerCircle

                Spacer().frame(height: 40)

                Text("잠깐 기다려봐요")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(AppColors.primaryText)

                Text("이 앱이 지금 꼭 필요한가요?")
                    .font(.system(size: 15))
                    .foregroundStyle(AppColors.secondaryText)
                    .padding(.top, 8)

                Spacer()

                VStack(spacing: 8) {
                    PrimaryButton("돌아가기", action: handleReturn)

                    SecondaryLinkButton(
                        strictActive
                            ? "엄격 모드에서는 열 수 없어요"
                            : (canExit ? "그래도 열기" : "\(totalSeconds)초 뒤에 선택할 수 있어요"),
                        isEnabled: canExit && !strictActive,
                        action: handleOpenAnyway
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
        .onAppear(perform: startCountdown)
        .onDisappear { timer?.invalidate() }
        .interactiveDismissDisabled(true)
    }

    // MARK: - Circle

    private var timerCircle: some View {
        ZStack {
            Circle()
                .stroke(AppColors.divider, lineWidth: 3)
                .frame(width: 160, height: 160)

            Circle()
                .trim(from: 0, to: CGFloat(max(0, remaining)) / CGFloat(max(1, totalSeconds)))
                .stroke(AppColors.primaryText, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 160, height: 160)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.3), value: remaining)

            Text("\(remaining)")
                .font(.system(size: 48, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.primaryText)
                .monospacedDigit()
        }
    }

    // MARK: - Countdown

    private func startCountdown() {
        timer?.invalidate()
        // 지연 해제 점증: 오늘 "그래도 열기" 누른 횟수에 따라 10/30/60 초로 증가.
        let seconds = deps.persistence.currentUnlockDelaySeconds()
        totalSeconds = seconds
        remaining = seconds
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
            if remaining > 0 {
                remaining -= 1
            }
            if remaining == 0 {
                t.invalidate()
            }
        }
    }

    // MARK: - Actions

    private func handleReturn() {
        // 점수 규칙 B: 돌아가기 +5점 + 3분 쿨다운 + 하루 40점 한도.
        deps.persistence.awardReturnPoint()
        deps.persistence.interceptQueue.append(
            InterceptEvent(type: .returned, subjectKind: .application)
        )
        // 뱃지 판정.
        BadgeEngine.onReturn(persistence: deps.persistence)
        BadgeEngine.onScoreChanged(persistence: deps.persistence)
        // 위젯도 즉시 새로고침 (iOS 는 hint 로 처리).
        WidgetCenter.shared.reloadTimelines(ofKind: "LockinFocusScoreWidget")
        timer?.invalidate()
        dismiss()
    }

    private func handleOpenAnyway() {
        // 지연 해제 점증: 오늘 해제 요청 카운트 +1 → 다음 intercept 는 더 오래 기다림.
        deps.persistence.recordManualUnlock()

        // 쟁점 5 MVP 단순화: 전체 shield 일시 해제 + 5분 타이머로 재적용.
        deps.blocking.clearShield()
        do {
            try deps.monitoring.startTemporaryAllow(name: "temp_allow_all", duration: 5 * 60)
        } catch {
            // MVP 조용히 무시.
        }
        timer?.invalidate()
        dismiss()
    }
}

#Preview {
    InterceptView()
        .environmentObject(AppDependencies.preview())
}
