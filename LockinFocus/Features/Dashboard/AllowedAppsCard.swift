import SwiftUI
import FamilyControls

/// 대시보드 허용 앱 카드.
/// 쟁점 2 준수: 앱 이름 노출 금지. 총 개수 + "편집" 링크만.
struct AllowedAppsCard: View {
    let selection: FamilyActivitySelection
    let onEdit: () -> Void

    private var count: Int {
        selection.applicationTokens.count + selection.categoryTokens.count
    }

    var body: some View {
        Button(action: onEdit) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("허용 앱")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppColors.secondaryText)

                    Text(count == 0 ? "설정된 허용 앱이 없습니다" : "\(count)개")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(AppColors.primaryText)
                }

                Spacer()

                HStack(spacing: 4) {
                    Text("편집")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppColors.primaryText)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppColors.secondaryText)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppColors.surface)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AllowedAppsCard(selection: FamilyActivitySelection(), onEdit: {})
        .padding(24)
        .background(AppColors.background)
}
