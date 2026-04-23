import SwiftUI

/// 유도 어려운 액션 ("그래도 열기", "건너뛰기" 등)에 쓰는 텍스트 링크 스타일.
/// - 연회색 텍스트. 밑줄 없음.
/// - 탭 영역은 접근성 최소 44pt 유지.
struct SecondaryLinkButton: View {
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
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(isEnabled ? AppColors.secondaryText : AppColors.secondaryText.opacity(0.4))
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

#Preview {
    VStack(spacing: 12) {
        SecondaryLinkButton("그래도 열기") {}
        SecondaryLinkButton("10초 뒤에 선택할 수 있어요", isEnabled: false) {}
    }
    .padding(24)
    .background(AppColors.background)
}
