import SwiftUI

/// 온보딩 Step 5 — 앱 비밀번호 설정.
/// 6자리 숫자 두 번 입력해서 일치하면 Keychain 에 저장 후 다음 단계.
/// "건너뛰기" 선택 가능. 건너뛰면 이후 잠금 시작 시 토스트로 재안내.
struct PasscodeStepView: View {
    let onNext: () -> Void

    @State private var first: String = ""
    @State private var second: String = ""
    @State private var step: Step = .first
    @State private var errorMessage: String?

    private enum Step { case first, confirm }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text(step == .first ? "앱 비밀번호를 정해주세요" : "다시 한 번 입력해주세요")
                    .scaledFont(28, weight: .semibold)
                    .foregroundStyle(AppColors.primaryText)

                Text(step == .first
                     ? "하루 첫 집중 해제 때 확인용으로 써요. iPhone 잠금 암호와는 별개예요."
                     : "확인을 위해 방금 정한 6자리를 한 번 더 입력해주세요.")
                    .scaledFont(15)
                    .foregroundStyle(AppColors.secondaryText)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)

            SecureField("숫자 6자리", text: step == .first ? $first : $second)
                .keyboardType(.numberPad)
                .scaledFont(28, weight: .medium, design: .rounded)
                .monospacedDigit()
                .foregroundStyle(AppColors.primaryText)
                .tint(AppColors.primaryText)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(
                            errorMessage == nil ? AppColors.divider : AppColors.error,
                            lineWidth: 1
                        )
                )
                .padding(.horizontal, 24)
                .onChange(of: first) { _ in
                    first = String(first.prefix(6).filter(\.isNumber))
                    if step == .first && first.count == 6 { advance() }
                }
                .onChange(of: second) { _ in
                    second = String(second.prefix(6).filter(\.isNumber))
                    if step == .confirm && second.count == 6 { advance() }
                }

            if let errorMessage {
                Text(errorMessage)
                    .scaledFont(13)
                    .foregroundStyle(AppColors.error)
                    .padding(.horizontal, 24)
            }

            Spacer()

            VStack(spacing: 10) {
                Button("건너뛰기") { onNext() }
                    .scaledFont(15)
                    .foregroundStyle(AppColors.secondaryText)
            }
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity)
        }
    }

    private func advance() {
        switch step {
        case .first:
            if first.count == 6 {
                step = .confirm
                errorMessage = nil
            }
        case .confirm:
            if second.count == 6 {
                if first == second {
                    _ = AppPasscodeStore.save(first)
                    onNext()
                } else {
                    errorMessage = "비밀번호가 달라요. 처음부터 다시 입력해주세요."
                    first = ""
                    second = ""
                    step = .first
                }
            }
        }
    }
}

#Preview {
    PasscodeStepView(onNext: {})
        .background(AppColors.background)
}
