import SwiftUI
import FamilyControls

/// 허용 앱 재선택 시트. `FamilyActivityPicker` 를 시트 본문으로 노출.
/// 실기기 + 권한 부여 상태에서만 실제 앱 목록이 보인다.
struct AppSelectionView: View {
    @Binding var selection: FamilyActivitySelection
    let onDone: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("쉬게 할 앱")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(AppColors.primaryText)

                        Text("여기서 고른 앱·카테고리만 집중 시간에 쉬어요.\n시스템 앱은 고르지 않으면 자동으로 열립니다.")
                            .font(.system(size: 14))
                            .foregroundStyle(AppColors.secondaryText)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    FamilyActivityPicker(selection: $selection)
                        .padding(.top, 12)

                    PrimaryButton("저장", action: onDone)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") {
                        dismiss()
                    }
                    .foregroundStyle(AppColors.secondaryText)
                }
            }
        }
    }
}

#Preview {
    AppSelectionView(selection: .constant(FamilyActivitySelection()), onDone: {})
}
