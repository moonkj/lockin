import SwiftUI
import UIKit

/// 수동 집중 종료 전 개입 뷰.
/// 하루 첫 번째 해제: 10초 원 파형 → 문장 한 줄 입력 → 6자리 비번 → 종료.
/// 두 번째 해제: 30초 원 파형만. 세 번째 이상: 60초 원 파형만.
struct FocusEndConfirmView: View {
    /// 오늘 이번이 몇 번째 해제인지 (1부터 시작).
    let ordinal: Int
    let onConfirm: () -> Void

    @Environment(\.dismiss) private var dismiss

    /// 내부 상태 머신. 테스트에서 초기 step/remaining 을 주입하기 위해 internal.
    enum Step {
        case wave
        case sentence
        case passcode
    }

    @State private var step: Step
    @State private var remaining: Int
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

    /// 기본 사용자 경로 — 카운트다운 시작점.
    init(ordinal: Int, onConfirm: @escaping () -> Void) {
        self.ordinal = ordinal
        self.onConfirm = onConfirm
        _step = State(initialValue: .wave)
        let initial: Int
        switch ordinal {
        case ...1: initial = 10
        case 2:    initial = 30
        default:   initial = 60
        }
        _remaining = State(initialValue: initial)
    }

    /// 테스트 전용 — 초기 step, remaining, typed 값을 직접 제어.
    init(
        ordinal: Int,
        initialStep: Step,
        initialRemaining: Int = 0,
        initialTyped: String = "",
        onConfirm: @escaping () -> Void
    ) {
        self.ordinal = ordinal
        self.onConfirm = onConfirm
        _step = State(initialValue: initialStep)
        _remaining = State(initialValue: initialRemaining)
        _typed = State(initialValue: initialTyped)
    }

    private var canConfirmWave: Bool { remaining == 0 }

    private var trimmedTyped: String {
        typed.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 한국어 입력기 IME 가 결합 자모(NFD) 로 보내주는 문자열을 표준 NFC 로 맞추고,
    /// 공백이 두 번 들어간 경우(모바일 키보드 오토스페이스, 전각→반각 등)도 정규화.
    /// `==` 비교 전에 양쪽 모두 이 정규화를 태운다.
    private static func normalizeForMatch(_ s: String) -> String {
        // precomposed = NFC 정규화. 자소 분리/결합 둘 다 같은 문자열로 수렴.
        let nfc = s.precomposedStringWithCanonicalMapping
        // 내부 공백이 둘 이상이면 하나로 접어 비교. 사용자가 쉼표 뒤에 실수로 스페이스
        // 2번 쳐도 통과하도록.
        let collapsedSpaces = nfc.split(separator: " ", omittingEmptySubsequences: true).joined(separator: " ")
        return collapsedSpaces
    }

    private var sentenceMatches: Bool {
        Self.normalizeForMatch(trimmedTyped) == Self.normalizeForMatch(targetSentence)
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            Group {
                switch step {
                case .wave:     waveStep
                case .sentence: sentenceStep
                case .passcode: passcodeStep
                }
            }
            .readingWidth(560)
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
                .scaledFont(24, weight: .semibold)
                .foregroundStyle(AppColors.primaryText)

            Text(isFirstToday
                 ? "오늘 첫 해제예요. 잠시 숨을 고르고 다음 단계로 넘어가요."
                 : "잠시 숨을 고르면서 한 번 더 생각해봐요.")
                .scaledFont(14)
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
                .scaledFont(22, weight: .semibold)
                .foregroundStyle(AppColors.primaryText)

            Text("\"\(targetSentence)\"")
                .scaledFont(16, weight: .medium)
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
                .scaledFont(18, weight: .medium)
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
                    .scaledFont(12)
                    .foregroundStyle(AppColors.error)
            }

            Spacer()

            VStack(spacing: 8) {
                PrimaryButton("계속 집중하기") {
                    dismiss()
                }

                SecondaryLinkButton(
                    sentenceNextLabel,
                    isEnabled: sentenceMatches,
                    action: advanceFromSentence
                )
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 비번이 설정돼 있으면 "다음 단계로" (passcode step), 없으면 "종료할게요" (즉시 종료).
    private var sentenceNextLabel: String {
        AppPasscodeStore.isSet ? "다음 단계로" : "종료할게요"
    }

    /// 문장 통과 후: 비번이 설정된 경우만 passcode step 으로.
    /// 비번 미설정 유저가 갇히지 않도록 바로 onConfirm 호출.
    private func advanceFromSentence() {
        if AppPasscodeStore.isSet {
            step = .passcode
        } else {
            onConfirm()
            dismiss()
        }
    }

    // MARK: - Step 3: passcode

    @EnvironmentObject private var deps: AppDependencies

    private var passcodeStep: some View {
        let allowBiometric = Self.allowBiometric(
            toggle: deps.persistence.useBiometricForPasscode,
            score: deps.persistence.focusScoreToday,
            goal: deps.persistence.focusGoalScore
        )
        return AppPasscodeEntryView(
            onSuccess: {
                onConfirm()
                dismiss()
            },
            useBiometric: allowBiometric
        )
    }

    /// Face ID 는 "오늘 목표 달성 후" 에만 비번 단축 키로 동작.
    /// 목표 미달이면 토글이 켜져있어도 6자리 입력 그대로 유지 — 마찰이 핵심 가치라
    /// 누구나 매일 우회되면 의미가 없음. 목표를 넘긴 보상으로만 제공.
    /// 순수 함수로 추출 — UI 무관 단위 테스트 가능.
    static func allowBiometric(toggle: Bool, score: Int, goal: Int) -> Bool {
        guard toggle else { return false }
        guard goal > 0 else { return false }
        return score >= goal
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
                    .scaledFont(40, weight: .semibold, design: .rounded)
                    .foregroundStyle(AppColors.primaryText)
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
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
        // 테스트에서 step 을 바로 sentence/passcode 로 주입한 경우엔
        // 카운트다운이 초기화돼선 안 된다 (remaining 을 0 으로 유지).
        guard step == .wave else { return }
        timer?.invalidate()
        announceRemainingIfVO()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
            if remaining > 0 { remaining -= 1 }
            if remaining == 5 || remaining == 3 || remaining == 1 {
                announceRemainingIfVO()
            }
            if remaining == 0 {
                t.invalidate()
                announceReadyIfVO()
            }
        }
    }

    private func announceRemainingIfVO() {
        guard UIAccessibility.isVoiceOverRunning else { return }
        UIAccessibility.post(notification: .announcement, argument: "\(remaining)초 남음")
    }

    private func announceReadyIfVO() {
        guard UIAccessibility.isVoiceOverRunning else { return }
        UIAccessibility.post(notification: .announcement, argument: "다음 단계로 진행할 수 있어요")
    }
}

#Preview("first") {
    FocusEndConfirmView(ordinal: 1, onConfirm: {})
}

#Preview("second") {
    FocusEndConfirmView(ordinal: 2, onConfirm: {})
}
