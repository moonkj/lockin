import SwiftUI
import FamilyControls

/// 대시보드 보조 카드 — "도파민 디톡스" 프리셋.
/// 평소 허용 세트보다 더 짧게(예: 전화만) 묶어 둔 "엄격한 집중" 모드를 빠르게 토글.
/// 프리셋 selection 이 비어 있으면 "프리셋 설정" 액션을 권유, 1개 이상일 때만 시작 가능.
struct DetoxPresetCard: View {
    @Binding var selection: FamilyActivitySelection
    let isActive: Bool
    let onTap: () -> Void
    let onEdit: () -> Void

    private var count: Int {
        selection.applicationTokens.count
        + selection.categoryTokens.count
        + selection.webDomainTokens.count
    }

    private var canStart: Bool { count > 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("도파민 디톡스")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.primaryText)

                Spacer()

                Button("프리셋 편집", action: onEdit)
                    .font(.system(size: 13))
                    .foregroundStyle(AppColors.secondaryText)
            }

            Text(detailText)
                .font(.system(size: 13))
                .foregroundStyle(AppColors.secondaryText)

            Button(action: onTap) {
                HStack(spacing: 8) {
                    Image(systemName: isActive ? "bolt.slash.fill" : "bolt.fill")
                        .font(.system(size: 14))
                    Text(isActive ? "디톡스 종료" : "디톡스 시작")
                        .font(.system(size: 15, weight: .semibold))
                    Spacer()
                }
                .padding(.horizontal, 14)
                .frame(height: 44)
                .foregroundStyle(canStart ? Color.white : AppColors.secondaryText)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(canStart ? AppColors.primaryText : AppColors.divider)
                )
            }
            .buttonStyle(.plain)
            .disabled(!canStart)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.surface)
        )
    }

    private var detailText: String {
        if count == 0 {
            return "프리셋이 비어 있어요. 먼저 허용할 앱을 골라주세요. (예: 전화·메시지만)"
        }
        return "평소보다 더 엄격하게, 이 \(count)개만 열어두고 나머지를 잠가요."
    }
}

#Preview {
    VStack(spacing: 16) {
        DetoxPresetCard(
            selection: .constant(FamilyActivitySelection()),
            isActive: false,
            onTap: {},
            onEdit: {}
        )
        DetoxPresetCard(
            selection: .constant(FamilyActivitySelection()),
            isActive: true,
            onTap: {},
            onEdit: {}
        )
    }
    .padding(20)
    .background(AppColors.background)
}
