import SwiftUI

/// 온보딩 Step 2 — 시스템 기본 허용 프리셋.
/// 쟁점 6: 전화 / 메시지 / 설정 은 기본 허용 안내(해제 불가 설명).
/// 시계 / 지도 / 카메라 는 기본 체크, 해제 가능 (Phase 3 MVP 에선 단순 안내로 표시).
struct SystemPresetStepView: View {
    let onNext: () -> Void

    private struct PresetItem: Identifiable {
        let id = UUID()
        let name: String
        let symbol: String
        let isRequired: Bool
    }

    private let items: [PresetItem] = [
        .init(name: "전화", symbol: "phone", isRequired: true),
        .init(name: "메시지", symbol: "message", isRequired: true),
        .init(name: "설정", symbol: "gearshape", isRequired: true),
        .init(name: "시계", symbol: "clock", isRequired: false),
        .init(name: "지도", symbol: "map", isRequired: false),
        .init(name: "카메라", symbol: "camera", isRequired: false),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("기본 앱은 항상 쓸 수 있어요")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(AppColors.primaryText)

                Text("전화와 메시지, 설정은 차단되지 않아요.\n필요한 시스템 앱을 안전하게 남겨둡니다.")
                    .font(.system(size: 15))
                    .foregroundStyle(AppColors.secondaryText)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)

            VStack(spacing: 0) {
                ForEach(items) { item in
                    HStack(spacing: 14) {
                        Image(systemName: item.symbol)
                            .font(.system(size: 18))
                            .foregroundStyle(AppColors.primaryText)
                            .frame(width: 28)

                        Text(item.name)
                            .font(.system(size: 16))
                            .foregroundStyle(AppColors.primaryText)

                        Spacer()

                        Text(item.isRequired ? "항상 허용" : "기본 허용")
                            .font(.system(size: 13))
                            .foregroundStyle(AppColors.secondaryText)
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)

                    if item.id != items.last?.id {
                        Rectangle()
                            .fill(AppColors.divider)
                            .frame(height: 0.5)
                            .padding(.leading, 58)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppColors.surface)
            )
            .padding(.horizontal, 24)

            Spacer(minLength: 12)

            PrimaryButton("다음", action: onNext)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
        }
    }
}

#Preview {
    SystemPresetStepView(onNext: {})
        .background(AppColors.background)
}
