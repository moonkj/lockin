import SwiftUI

/// 수동 집중 종료 전 개입 뷰.
/// 하루 첫 번째 해제: 10초 원 파형 → 문장 한 줄 입력 → 6자리 비번 → 종료.
/// 두 번째 해제: 30초 원 파형만. 세 번째 이상: 60초 원 파형만.
struct FocusEndConfirmView: View {
    /// 오늘 이번이 몇 번째 해제인지 (1부터 시작).
    let ordinal: Int
    let onConfirm: () -> Void

    @Environment(\.dismiss) private var dismiss

    private enum Step {
        case wave
        case sentence
        case passcode
    }

    @State private var step: Step = .wave
    @State private var remaining: Int = 10
    @State private var timer: Timer?

    @State private var typed: String = ""

    private let rippleCount: Int = 4
    private let rippleDuration: Double = 3.2
    private let startedAt: Date = Date()

    /// 해제 목표 문장 — 사용자가 정확히 따라 써야 다음 단계로.
    private let targetSentence: String = "나는 지금 꼭 집중을 풀어야 한다"

    private var isFirstToday: Bool { ordinal <= 1 }

    private var waitSeconds: Int {
        switch ordinal {
        case ...1: return 10
        case 2:    return 30
        default:   return 60
        }
    }

    private var canConfirmWave: Bool { remaining == 0 }

    private var trimmedTyped: String {
        typed.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var sentenceMatches: Bool {
        trimmedTyped == targetSentence
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            switch step {
            case .wave:     waveStep
            case .sentence: sentenceStep
            case .passcode: passcodeStep
            }
        }
        .onAppear(perform: startCountdown)
        .onDisappear { timer?.invalidate() }
        .interactiveDismissDisabled(true)
    }

    // MARK: - Step 1: wave + countdown

    private var waveStep: some View {
        VStack(spacing: 0) {
            Spacer()

            rippleView
                .frame(width: 280, height: 280)

            Spacer().frame(height: 32)

            Text("정말 종료할까요?")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(AppColors.primaryText)

            Text(isFirstToday
                 ? "오늘 첫 해제예요. 잠시 숨을 고르고 다음 단계로 넘어가요."
                 : "잠시 숨을 고르면서 한 번 더 생각해봐요.")
                .font(.system(size: 14))
                .foregroundStyle(AppColors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.top, 8)

            Spacer()

            VStack(spacing: 8) {
                PrimaryButton("계속 집중하기") {
                    dismiss()
                }

                SecondaryLinkButton(
                    waveButtonLabel,
                    isEnabled: canConfirmWave,
                    action: advanceFromWave
                )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    private var waveButtonLabel: String {
        if !canConfirmWave { return "\(remaining)초 뒤에 다음으로 넘어가요" }
        return isFirstToday ? "다음 단계로" : "종료할게요"
    }

    private func advanceFromWave() {
        if isFirstToday {
            step = .sentence
        } else {
            onConfirm()
            dismiss()
        }
    }

    // MARK: - Step 2: sentence

    private var sentenceStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("이 문장을 그대로 써주세요")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(AppColors.primaryText)

            Text("\"\(targetSentence)\"")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AppColors.secondaryText)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppColors.surface)
                )

            TextField("여기에 입력", text: $typed, axis: .vertical)
                .lineLimit(2, reservesSpace: true)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(AppColors.primaryText)
                .tint(AppColors.primaryText)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(
                            sentenceMatches ? AppColors.accent : AppColors.divider,
                            lineWidth: 1
                        )
                )

            if !trimmedTyped.isEmpty && !sentenceMatches {
                Text("문장이 달라요. 예시대로 정확히 써야 해요.")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.error)
            }

            Spacer()

            VStack(spacing: 8) {
                PrimaryButton("계속 집중하기") {
                    dismiss()
                }

                SecondaryLinkButton(
                    "다음 단계로",
                    isEnabled: sentenceMatches,
                    action: { step = .passcode }
                )
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Step 3: passcode

    private var passcodeStep: some View {
        AppPasscodeEntryView {
            onConfirm()
            dismiss()
        }
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
        remaining = waitSeconds
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
            if remaining > 0 { remaining -= 1 }
            if remaining == 0 { t.invalidate() }
        }
    }
}

#Preview("first") {
    FocusEndConfirmView(ordinal: 1, onConfirm: {})
}

#Preview("second") {
    FocusEndConfirmView(ordinal: 2, onConfirm: {})
}
