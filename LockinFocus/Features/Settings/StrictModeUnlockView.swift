import SwiftUI
import LocalAuthentication

/// 엄격 모드 해제 Friction.
/// 1) 30초 카운트다운
/// 2) 정해진 문장 정확히 입력
/// 3) 본인 확인 — 앱 비번 (설정된 경우) 또는 Face ID/암호 중 사용자가 선택
struct StrictModeUnlockView: View {
    let onSuccess: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var remaining: Int = 30
    @State private var timer: Timer?
    @State private var phrase: String = ""

    @State private var method: UnlockMethod
    @State private var showPasscodeEntry: Bool = false
    @State private var isAuthenticating: Bool = false
    @State private var errorMessage: String?

    private let requiredPhrase = "지금 이 선택을 정말로 원해요"

    private var timerExpired: Bool { remaining == 0 }
    private var phraseMatches: Bool { phrase == requiredPhrase }
    private var canConfirm: Bool { timerExpired && phraseMatches && !isAuthenticating }

    private enum UnlockMethod: String, CaseIterable, Identifiable {
        case appPasscode
        case biometric
        var id: String { rawValue }

        var label: String {
            switch self {
            case .appPasscode: return "앱 비밀번호"
            case .biometric: return "Face ID / 암호"
            }
        }

        var symbol: String {
            switch self {
            case .appPasscode: return "key.fill"
            case .biometric: return "faceid"
            }
        }
    }

    init(onSuccess: @escaping () -> Void) {
        self.onSuccess = onSuccess
        // 기본값: 앱 비번이 설정돼 있으면 앱 비번, 아니면 생체 인증.
        _method = State(initialValue: AppPasscodeStore.isSet ? .appPasscode : .biometric)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("엄격 모드 해제")
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundStyle(AppColors.primaryText)

                            Text("세 단계를 모두 거치면 엄격 모드가 꺼집니다.")
                                .font(.system(size: 14))
                                .foregroundStyle(AppColors.secondaryText)
                        }

                        stepCard(
                            number: 1,
                            title: "30초 기다리기",
                            done: timerExpired,
                            detail: timerExpired
                                ? "기다림 완료"
                                : "\(remaining)초 남음"
                        )

                        stepCard(
                            number: 2,
                            title: "정확히 입력하기",
                            done: phraseMatches,
                            detail: "다음 문장을 그대로 입력하세요: \(requiredPhrase)"
                        ) {
                            TextField("", text: $phrase, axis: .vertical)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .font(.system(size: 15))
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(
                                            phrase.isEmpty
                                                ? AppColors.divider
                                                : (phraseMatches ? AppColors.success : AppColors.warning),
                                            lineWidth: 1
                                        )
                                )
                        }

                        stepCard(
                            number: 3,
                            title: "본인 확인",
                            done: false,
                            detail: AppPasscodeStore.isSet
                                ? "앱 비밀번호 또는 Face ID 중 선택하세요."
                                : "Face ID 또는 기기 암호로 본인 확인. (앱 비밀번호는 설정 → '앱 비밀번호 설정' 에서 지정할 수 있어요.)"
                        ) {
                            Picker("해제 방법", selection: $method) {
                                ForEach(UnlockMethod.allCases) { m in
                                    Label(m.label, systemImage: m.symbol).tag(m)
                                }
                            }
                            .pickerStyle(.segmented)
                            .disabled(!AppPasscodeStore.isSet)
                            .opacity(AppPasscodeStore.isSet ? 1 : 0.5)
                        }

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 13))
                                .foregroundStyle(AppColors.error)
                        }

                        Spacer(minLength: 12)

                        PrimaryButton("해제하기", action: confirm)
                            .disabled(!canConfirm)
                            .opacity(canConfirm ? 1 : 0.4)
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                        .foregroundStyle(AppColors.secondaryText)
                }
            }
            .sheet(isPresented: $showPasscodeEntry) {
                AppPasscodeEntryView {
                    onSuccess()
                    dismiss()
                }
            }
        }
        .onAppear(perform: startCountdown)
        .onDisappear { timer?.invalidate() }
    }

    // MARK: - Step cards

    @ViewBuilder
    private func stepCard<Content: View>(
        number: Int,
        title: String,
        done: Bool,
        detail: String,
        @ViewBuilder extra: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: done ? "checkmark.circle.fill" : "\(number).circle")
                    .font(.system(size: 20))
                    .foregroundStyle(done ? AppColors.success : AppColors.primaryText)
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppColors.primaryText)
            }
            Text(detail)
                .font(.system(size: 13))
                .foregroundStyle(AppColors.secondaryText)
            extra()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppColors.surface)
        )
    }

    private func stepCard(number: Int, title: String, done: Bool, detail: String) -> some View {
        stepCard(number: number, title: title, done: done, detail: detail) { EmptyView() }
    }

    // MARK: - Actions

    private func startCountdown() {
        timer?.invalidate()
        remaining = 30
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
            if remaining > 0 {
                remaining -= 1
            }
            if remaining == 0 {
                t.invalidate()
            }
        }
    }

    private func confirm() {
        errorMessage = nil
        switch method {
        case .appPasscode:
            showPasscodeEntry = true
        case .biometric:
            authenticateBiometric()
        }
    }

    private func authenticateBiometric() {
        isAuthenticating = true
        let context = LAContext()
        context.localizedFallbackTitle = "암호로 인증"

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            errorMessage = "본인 확인을 사용할 수 없어요."
            isAuthenticating = false
            return
        }

        context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: "엄격 모드를 해제하려면 본인 확인이 필요해요."
        ) { success, authError in
            DispatchQueue.main.async {
                isAuthenticating = false
                if success {
                    onSuccess()
                    dismiss()
                } else {
                    errorMessage = authError?.localizedDescription ?? "본인 확인 실패"
                }
            }
        }
    }
}

#Preview {
    StrictModeUnlockView(onSuccess: {})
}
