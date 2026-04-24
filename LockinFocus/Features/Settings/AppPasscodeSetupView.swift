import SwiftUI

/// 앱 비밀번호 초기 설정. 4자리 숫자 두 번 입력해서 일치하면 Keychain 저장.
/// 엄격 모드 해제 시 "앱 비번" 옵션을 사용하려면 먼저 여기서 설정되어야 한다.
struct AppPasscodeSetupView: View {
    let onDone: (Bool) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var first: String
    @State private var second: String
    @State private var step: Step
    @State private var errorMessage: String?

    enum Step { case first, confirm }

    init(onDone: @escaping (Bool) -> Void) {
        self.onDone = onDone
        _first = State(initialValue: "")
        _second = State(initialValue: "")
        _step = State(initialValue: .first)
    }

    /// 테스트 전용 init — 초기 step 및 이전 입력값을 주입.
    init(onDone: @escaping (Bool) -> Void, initialStep: Step, initialFirst: String = "", initialErrorMessage: String? = nil) {
        self.onDone = onDone
        _first = State(initialValue: initialFirst)
        _second = State(initialValue: "")
        _step = State(initialValue: initialStep)
        _errorMessage = State(initialValue: initialErrorMessage)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 20) {
                    Text(step == .first ? "앱 비밀번호 설정" : "비밀번호 다시 입력")
                        .scaledFont(26, weight: .semibold)
                        .foregroundStyle(AppColors.primaryText)

                    Text(step == .first
                         ? "엄격 모드를 해제할 때 쓸 6자리 숫자 비번을 정해주세요. iPhone 잠금 암호와는 별개예요."
                         : "확인을 위해 한 번 더 입력해주세요.")
                        .scaledFont(14)
                        .foregroundStyle(AppColors.secondaryText)

                    SecureField("숫자 6자리", text: step == .first ? $first : $second)
                        .keyboardType(.numberPad)
                        .scaledFont(28, weight: .medium, design: .rounded)
                        .monospacedDigit()
                        .foregroundStyle(AppColors.primaryText)
                        .tint(AppColors.primaryText)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(AppColors.divider, lineWidth: 1)
                        )
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
                    }

                    Spacer()
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        onDone(false)
                        dismiss()
                    }
                    .foregroundStyle(AppColors.secondaryText)
                }
            }
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
                    onDone(true)
                    dismiss()
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
    AppPasscodeSetupView(onDone: { _ in })
}
