import SwiftUI

/// 온보딩 Step 3 — 필수 앱 안내.
/// iOS 자동 보호 앱(전화/메시지/설정)과 사용자가 다음 단계 Picker 에서 **직접 체크해야**
/// 보호되는 앱(카메라/지도/시계 등)을 분리해서 정직하게 보여준다.
struct SystemPresetStepView: View {
    let onNext: () -> Void

    private struct PresetItem: Identifiable {
        let id = UUID()
        let name: String
        let symbol: String
        let kind: Kind

        enum Kind {
            /// iOS Screen Time API 가 자동으로 Shield 에서 제외하는 핵심 시스템 앱.
            case iosProtected
            /// Apple API 제약으로 앱이 자동 허용할 수 없는 앱. Picker 에서 사용자가 체크 필요.
            case needsManual
        }
    }

    private let items: [PresetItem] = [
        .init(name: "전화", symbol: "phone", kind: .iosProtected),
        .init(name: "메시지", symbol: "message", kind: .iosProtected),
        .init(name: "설정", symbol: "gearshape", kind: .iosProtected),
        .init(name: "카메라", symbol: "camera", kind: .needsManual),
        .init(name: "지도", symbol: "map", kind: .needsManual),
        .init(name: "시계", symbol: "clock", kind: .needsManual),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("핵심 시스템 앱은 iOS 가 보호해요")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(AppColors.primaryText)

                Text("전화·메시지·설정은 아무것도 안 고르셔도 iOS 가 자동 보호합니다.\n카메라·지도처럼 ⚠️ 표시된 앱은 다음 단계에서 꼭 체크해주세요.")
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

                        labelFor(item.kind)
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

    @ViewBuilder
    private func labelFor(_ kind: PresetItem.Kind) -> some View {
        switch kind {
        case .iosProtected:
            Text("iOS 자동 보호")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppColors.success)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(AppColors.success.opacity(0.12))
                )
        case .needsManual:
            Text("⚠️ 직접 체크")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppColors.warning)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(AppColors.warning.opacity(0.12))
                )
        }
    }
}

#Preview {
    SystemPresetStepView(onNext: {})
        .background(AppColors.background)
}
