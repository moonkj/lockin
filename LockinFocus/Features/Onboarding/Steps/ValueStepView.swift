import SwiftUI

/// 온보딩 Step 1 — 가치 제안.
/// 명령형 금지, 느낌표 금지. 차분한 톤.
struct ValueStepView: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                Text("조금 쉬었다 갈까요")
                    .scaledFont(28, weight: .semibold)
                    .foregroundStyle(AppColors.primaryText)
                    .multilineTextAlignment(.center)

                Text("충동과 선택 사이에\n10초의 쉼을 드려요.")
                    .scaledFont(17)
                    .foregroundStyle(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 8) {
                PrimaryButton("시작하기", action: onNext)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }
}

#Preview {
    ValueStepView(onNext: {})
        .background(AppColors.background)
}
