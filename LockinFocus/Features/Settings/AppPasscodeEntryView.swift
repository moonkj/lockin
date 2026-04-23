import SwiftUI

/// 엄격 모드 해제 시 앱 비번 입력. 저장된 Keychain 값과 일치하면 onSuccess.
/// 틀리면 빈 필드로 초기화하고 경고 카피 표시.
struct AppPasscodeEntryView: View {
    let onSuccess: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var input: String = ""
    @State private var errorMessage: String?
    @State private var attempts: Int = 0

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 20) {
                    Text("앱 비밀번호 입력")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(AppColors.primaryText)

                    Text("설정한 6자리 비번을 입력하세요.")
                        .font(.system(size: 14))
                        .foregroundStyle(AppColors.secondaryText)

                    SecureField("숫자 6자리", text: $input)
                        .keyboardType(.numberPad)
                        .font(.system(size: 28, weight: .medium, design: .rounded))
                        .monospacedDigit()
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
                            .font(.system(size: 13))
                            .foregroundStyle(AppColors.error)
                    }

                    Spacer()
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                        .foregroundStyle(AppColors.secondaryText)
                }
            }
        }
    }

    private func verify() {
        if AppPasscodeStore.verify(input) {
            onSuccess()
            dismiss()
        } else {
            attempts += 1
            errorMessage = "비밀번호가 달라요. 다시 입력해주세요."
            input = ""
        }
    }
}

#Preview {
    AppPasscodeEntryView(onSuccess: {})
}
