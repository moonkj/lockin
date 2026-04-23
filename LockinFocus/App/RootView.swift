import SwiftUI

struct RootView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("락인 포커스")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(AppColors.primaryText)
            Text("설계 단계 진행 중")
                .font(.body)
                .foregroundStyle(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background.ignoresSafeArea())
    }
}

#Preview {
    RootView()
}
