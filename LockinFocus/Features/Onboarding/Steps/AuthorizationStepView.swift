import SwiftUI

/// 온보딩 Step 5 — FamilyControls 권한 요청.
/// 거부 시: "설정으로 이동" + "다시 요청" 버튼 제공.
struct AuthorizationStepView: View {
    @Binding var denied: Bool
    let onAuthorize: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                Text("마지막 한 단계예요")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(AppColors.primaryText)
                    .multilineTextAlignment(.center)

                Text("Apple의 스크린타임 기능을 사용하려면\n권한이 필요해요.\n이 권한은 이 기기 안에서만 쓰입니다.")
                    .font(.system(size: 15))
                    .foregroundStyle(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 8) {
                if denied {
                    Text("권한이 꺼져 있어요. 설정에서 허용을 켜주세요.")
                        .font(.system(size: 13))
                        .foregroundStyle(AppColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    PrimaryButton("설정으로 이동", action: onOpenSettings)
                    SecondaryLinkButton("다시 요청", action: onAuthorize)
                } else {
                    PrimaryButton("허용하기", action: onAuthorize)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }
}

#Preview("Default") {
    AuthorizationStepView(denied: .constant(false), onAuthorize: {}, onOpenSettings: {})
        .background(AppColors.background)
}

#Preview("Denied") {
    AuthorizationStepView(denied: .constant(true), onAuthorize: {}, onOpenSettings: {})
        .background(AppColors.background)
}
