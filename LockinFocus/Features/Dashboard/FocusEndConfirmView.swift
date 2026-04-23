import SwiftUI

/// 수동 집중 종료 전 10초 개입 뷰.
/// Intercept 와 같은 철학: 자동 종료를 자각의 순간으로 바꾸기.
/// 중앙에서 4개의 원이 연속으로 바깥으로 퍼지는 파형(리플) 애니메이션을 보여주고,
/// 10초가 지난 뒤에만 "종료할게요" 버튼이 활성화된다.
struct FocusEndConfirmView: View {
    let onConfirm: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var remaining: Int = 10
    @State private var timer: Timer?

    private let rippleCount: Int = 4
    private let rippleDuration: Double = 3.2
    private let startedAt: Date = Date()

    private var canConfirm: Bool { remaining == 0 }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                rippleView
                    .frame(width: 280, height: 280)

                Spacer().frame(height: 32)

                Text("정말 종료할까요?")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(AppColors.primaryText)

                Text("잠시 숨을 고르면서 한 번 더 생각해봐요.")
                    .font(.system(size: 14))
                    .foregroundStyle(AppColors.secondaryText)
                    .padding(.top, 8)

                Spacer()

                VStack(spacing: 8) {
                    PrimaryButton("계속 집중하기") {
                        dismiss()
                    }

                    SecondaryLinkButton(
                        canConfirm ? "종료할게요" : "\(remaining)초 뒤에 종료할 수 있어요",
                        isEnabled: canConfirm,
                        action: {
                            onConfirm()
                            dismiss()
                        }
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .onAppear(perform: startCountdown)
        .onDisappear { timer?.invalidate() }
        .interactiveDismissDisabled(true)
    }

    // MARK: - Ripples

    /// TimelineView 가 매 프레임 경과 시간을 제공하고, 4개 원이 서로 다른 phase 로 퍼진다.
    private var rippleView: some View {
        TimelineView(.animation) { context in
            let elapsed = context.date.timeIntervalSince(startedAt)
            ZStack {
                ForEach(0..<rippleCount, id: \.self) { idx in
                    let progress = rippleProgress(elapsed: elapsed, index: idx)
                    rippleCircle(progress: progress)
                }

                // 중앙 정적 이너 원(카운트다운 배경).
                Circle()
                    .fill(AppColors.primaryText.opacity(0.08))
                    .frame(width: 96, height: 96)

                Text("\(remaining)")
                    .font(.system(size: 40, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.primaryText)
                    .monospacedDigit()
            }
        }
    }

    private func rippleProgress(elapsed: Double, index: Int) -> Double {
        let offset = rippleDuration * Double(index) / Double(rippleCount)
        let t = (elapsed + offset).truncatingRemainder(dividingBy: rippleDuration)
        return t / rippleDuration
    }

    private func rippleCircle(progress: Double) -> some View {
        // 중심 96pt 부근에서 시작해 280pt 까지 커지며 점점 투명해진다.
        let baseSize: CGFloat = 96
        let maxSize: CGFloat = 280
        let size = baseSize + (maxSize - baseSize) * CGFloat(progress)
        let strokeAlpha = (1 - progress) * 0.5
        return Circle()
            .stroke(AppColors.primaryText.opacity(strokeAlpha), lineWidth: 1.5)
            .frame(width: size, height: size)
    }

    // MARK: - Countdown

    private func startCountdown() {
        timer?.invalidate()
        remaining = 10
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
            if remaining > 0 { remaining -= 1 }
            if remaining == 0 { t.invalidate() }
        }
    }
}

#Preview {
    FocusEndConfirmView(onConfirm: {})
}
