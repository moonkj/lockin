import SwiftUI

/// iPad/Regular-width에서 콘텐츠가 가로로 너무 퍼지는 걸 막는 모디파이어.
///
/// iPhone (Compact) 에서는 `.frame(maxWidth: 640)` 이 화면 폭보다 커서 무시되므로
/// 추가 비용 없이 그대로 통과한다. iPad Portrait (~820pt) / Landscape (~1180pt)
/// 에서는 콘텐츠를 640pt 폭으로 제한하고 가운데 정렬해 긴 줄 → 가독성 하락을 피한다.
///
/// 사용처: ScrollView 내부 VStack, NavigationStack 의 Form, 온보딩 스텝 VStack 등.
struct ReadingWidthModifier: ViewModifier {
    let maxWidth: CGFloat

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

extension View {
    /// iPad 등 넓은 화면에서 중앙 정렬 + 최대 폭 제한.
    /// Compact (iPhone) 에서는 동작하지 않음.
    func readingWidth(_ maxWidth: CGFloat = 640) -> some View {
        modifier(ReadingWidthModifier(maxWidth: maxWidth))
    }
}
