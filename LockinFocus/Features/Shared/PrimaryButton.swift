import SwiftUI

/// 락인 포커스의 기본 Primary 버튼.
/// - 검은 배경 + 흰 글자
/// - Radius 12pt / 높이 52pt
/// - 흰색 배경 UI 위에서 주요 액션을 강조하는 유일한 대비 요소.
struct PrimaryButton: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void

    init(_ title: String, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .scaledFont(17, weight: .semibold)
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isEnabled ? AppColors.primaryText : AppColors.primaryText.opacity(0.3))
                )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .contentShape(Rectangle())
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryButton("시작하기") {}
        PrimaryButton("비활성", isEnabled: false) {}
    }
    .padding(24)
    .background(AppColors.background)
}
