import SwiftUI

/// 위젯 공통 컨테이너.
/// iOS 17+ 은 `containerBackground(for: .widget)`, 그 이전은 수동 padding + background.
/// 배경 색은 `Color(uiColor: .systemBackground)` → 라이트 모드는 흰색, 다크 모드는 검정 계열.
extension View {
    @ViewBuilder
    func lockinWidgetContainer() -> some View {
        if #available(iOS 17.0, *) {
            self.containerBackground(for: .widget) {
                Color(uiColor: .systemBackground)
            }
        } else {
            self
                .padding(12)
                .background(Color(uiColor: .systemBackground))
        }
    }
}
