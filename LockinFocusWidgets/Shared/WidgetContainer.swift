import SwiftUI

/// iOS 17+ 의 `containerBackground(for: .widget)` 과 그 이전을 정리해주는 헬퍼.
/// 현재 deployment target 은 iOS 16 이므로 두 경로 모두 지원해야 한다.
extension View {
    @ViewBuilder
    func lockinWidgetContainer() -> some View {
        if #available(iOS 17.0, *) {
            self.containerBackground(for: .widget) {
                AppColors.background
            }
        } else {
            self.padding(12).background(AppColors.background)
        }
    }
}
