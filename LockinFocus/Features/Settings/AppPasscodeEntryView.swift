import SwiftUI

/// 엄격 모드 해제 시 앱 비번 입력. 저장된 Keychain 값과 일치하면 onSuccess.
/// 틀리면 빈 필드로 초기화하고 경고 카피 표시.
///
/// `useBiometric=true` 이면 onAppear 에서 Face ID / Touch ID 를 먼저 시도하고,
/// 성공하면 곧바로 onSuccess. 실패·취소 시 기존 6자리 입력 UI 로 폴백.
struct AppPasscodeEntryView: View {
    let onSuccess: () -> Void
    /// Face ID / Touch ID 시도할지. 호출부 (Settings) 가 preference 에 따라 넘긴다.
    let useBiometric: Bool

    @Environment(\.dismiss) private var dismiss

    @State private var input: String
    @State private var errorMessage: String?
    @State private var attempts: Int = 0
    @State private var biometricAttempted: Bool = false

    init(onSuccess: @escaping () -> Void, useBiometric: Bool = false) {
        self.onSuccess = onSuccess
        self.useBiometric = useBiometric
        _input = State(initialValue: "")
    }

    /// 테스트 전용 — 초기 에러 메시지 표시 상태를 주입.
    init(onSuccess: @escaping () -> Void, initialError: String?) {
        self.onSuccess = onSuccess
        self.useBiometric = false
        _input = State(initialValue: "")
        _errorMessage = State(initialValue: initialError)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 20) {
                    Text("앱 비밀번호 입력")
                        .scaledFont(26, weight: .semibold)
                        .foregroundStyle(AppColors.primaryText)

                    Text("설정한 6자리 비번을 입력하세요.")
                        .scaledFont(14)
                        .foregroundStyle(AppColors.secondaryText)

                    SecureField("숫자 6자리", text: $input)
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
                        .onChange(of: input) { newValue in
                            let filtered = String(newValue.prefix(6).filter(\.isNumber))
                            if filtered != input { input = filtered }
                            if input.count == 6 { verify() }
                        }

                    if let errorMessage {
                        Text(errorMessage)
                            .scaledFont(13)
                            .foregroundStyle(AppColors.error)
                    }

                    Spacer()
                }
                .padding(20)
                .readingWidth(560)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                        .foregroundStyle(AppColors.secondaryText)
                }
            }
            .onAppear {
                // 뷰 등장 시 Face ID / Touch ID 한 번 시도. 실패 시 6자리 입력으로 fallback.
                // biometricAttempted 로 중복 prompt 방지.
                if useBiometric, !biometricAttempted, BiometricAuth.isAvailable {
                    biometricAttempted = true
                    BiometricAuth.authenticate { ok in
                        if ok {
                            Haptics.success()
                            onSuccess()
                            dismiss()
                        }
                        // 실패/취소는 조용히 — 기존 숫자 입력 UI 가 그대로 사용 가능.
                    }
                }
            }
        }
    }

    private func verify() {
        // 사전 점검 — 이미 lockout 상태면 verify 호출 안 하고 안내만.
        if AppPasscodeStore.isLockedOut() {
            errorMessage = lockoutMessage()
            input = ""
            return
        }
        if AppPasscodeStore.verify(input) {
            onSuccess()
            dismiss()
        } else {
            attempts += 1
            // verify() 내부에서 lockout 진입했을 가능성 — 별도 안내 카피.
            if AppPasscodeStore.isLockedOut() {
                errorMessage = lockoutMessage()
            } else {
                errorMessage = "비밀번호가 달라요. 다시 입력해주세요."
            }
            input = ""
        }
    }

    /// lockout 잔여 시간을 분/초로 보여주는 카피.
    private func lockoutMessage() -> String {
        let remaining = Int(AppPasscodeStore.lockoutRemainingSeconds().rounded(.up))
        if remaining <= 0 {
            return "비밀번호가 달라요. 다시 입력해주세요."
        }
        let m = remaining / 60
        let s = remaining % 60
        if m > 0 {
            return "5회 연속 틀려서 잠시 잠겼어요. \(m)분 \(s)초 뒤에 다시 시도해주세요."
        }
        return "5회 연속 틀려서 잠시 잠겼어요. \(s)초 뒤에 다시 시도해주세요."
    }
}

#Preview {
    AppPasscodeEntryView(onSuccess: {})
}
