import SwiftUI

/// 랭킹 참여 전 닉네임 1회 설정.
struct NicknameSetupView: View {
    @EnvironmentObject var deps: AppDependencies
    @Environment(\.dismiss) private var dismiss
    let onSaved: (String) -> Void

    @State private var nickname: String
    @State private var errorMessage: String?

    init(onSaved: @escaping (String) -> Void) {
        self.onSaved = onSaved
        _nickname = State(initialValue: "")
    }

    /// 테스트 전용 init — 초기 nickname / error 주입.
    init(onSaved: @escaping (String) -> Void, initialNickname: String, initialError: String? = nil) {
        self.onSaved = onSaved
        _nickname = State(initialValue: initialNickname)
        _errorMessage = State(initialValue: initialError)
    }

    private var trimmed: String {
        nickname.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSubmit: Bool {
        if case .success = NicknameValidator.validate(nickname) { return true }
        return false
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 20) {
                    Text("닉네임 만들기")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(AppColors.primaryText)

                    Text("랭킹에서 다른 사용자에게 이렇게 보여요.\n2~20자.")
                        .font(.system(size: 14))
                        .foregroundStyle(AppColors.secondaryText)

                    TextField("예: 집중러", text: $nickname)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(AppColors.primaryText)
                        .tint(AppColors.primaryText)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(
                                    errorMessage == nil ? AppColors.divider : AppColors.error,
                                    lineWidth: 1
                                )
                        )
                        .onChange(of: nickname) { newValue in
                            if newValue.count > 20 {
                                nickname = String(newValue.prefix(20))
                            }
                            errorMessage = nil
                        }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 12))
                            .foregroundStyle(AppColors.error)
                    }

                    Spacer()

                    PrimaryButton("저장", action: save)
                        .disabled(!canSubmit)
                        .opacity(canSubmit ? 1 : 0.4)
                }
                .padding(24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                        .foregroundStyle(AppColors.secondaryText)
                }
            }
            .onAppear {
                nickname = deps.persistence.nickname ?? ""
            }
        }
    }

    private func save() {
        switch NicknameValidator.validate(nickname) {
        case .success(let cleaned):
            deps.persistence.nickname = cleaned
            onSaved(cleaned)
            dismiss()
        case .failure(let err):
            errorMessage = err.errorDescription
        }
    }
}
