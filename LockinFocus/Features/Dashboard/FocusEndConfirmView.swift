import SwiftUI

/// 수동 집중 종료 전 10초 "심호흡" 개입 뷰.
/// Intercept 와 같은 철학: 자동 종료를 자각의 순간으로 바꾸기.
/// 10초 동안 원이 호흡처럼 커졌다 작아지고, 그 후에만 종료 버튼이 활성화된다.
struct FocusEndConfirmView: View {
    let onConfirm: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var remaining: Int = 10
    @State private var timer: Timer?
    @State private var breathScale: CGFloat = 0.7

    private var canConfirm: Bool { remaining == 0 }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                breathCircle

                Spacer().frame(height: 32)

                Text(breathLabel)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(AppColors.secondaryText)
                    .animation(.easeInOut(duration: 0.3), value: breathScale)

                Spacer().frame(height: 24)

                Text("정말 종료할까요?")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(AppColors.primaryText)

                Text("천천히 숨을 쉬면서 한 번 더 생각해봐요.")
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
        .onAppear {
            startCountdown()
            startBreathing()
        }
        .onDisappear {
            timer?.invalidate()
        }
        .interactiveDismissDisabled(true)
    }

    // MARK: - Breathing visuals

    private var breathCircle: some View {
        ZStack {
            Circle()
                .fill(AppColors.primaryText.opacity(0.08))
                .frame(width: 220, height: 220)
                .scaleEffect(breathScale)

            Circle()
                .stroke(AppColors.primaryText.opacity(0.4), lineWidth: 2)
                .frame(width: 220, height: 220)
                .scaleEffect(breathScale)

            Text("\(remaining)")
                .font(.system(size: 44, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.primaryText)
                .monospacedDigit()
        }
    }

    private var breathLabel: String {
        breathScale > 0.85 ? "천천히 들이쉬어요" : "천천히 내쉬어요"
    }

    // MARK: - Timers

    private func startCountdown() {
        timer?.invalidate()
        remaining = 10
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
            if remaining > 0 { remaining -= 1 }
            if remaining == 0 { t.invalidate() }
        }
    }

    private func startBreathing() {
        // 2.5초 주기로 0.7 <-> 1.0 반복 → 10초 동안 두 호흡 주기 체감.
        breathScale = 0.7
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            breathScale = 1.0
        }
    }
}

#Preview {
    FocusEndConfirmView(onConfirm: {})
}
