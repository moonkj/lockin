import SwiftUI

/// 앱 전역에서 쓰는 Dynamic Type 지원 폰트 modifier.
///
/// 왜 필요한가:
/// - `.font(.system(size: 20))` 는 사용자의 Dynamic Type 설정을 무시하고
///   항상 20 pt 로 고정된다. 접근성 크기를 키운 사용자가 글자를 읽을 수 없다.
/// - `.font(.body)` 같은 semantic 스타일은 Dynamic Type 을 따르지만, 기본 크기가
///   우리 디자인(17 pt 고정)과 다르거나 weight 를 별도로 붙여야 한다.
///
/// 해결:
/// - `@ScaledMetric` 으로 "기준 크기를 relativeTo 스타일에 맞춰 배율 조절" 한다.
/// - 호출부는 `.scaledFont(18, weight: .medium)` 처럼 기존 픽셀 크기 그대로 쓰면 되고,
///   default Dynamic Type 에서는 현행과 동일한 18 pt 로 렌더링,
///   사용자가 큰 글자 설정을 켜면 body 기준으로 비례 확대된다.
struct ScaledFont: ViewModifier {
    @ScaledMetric private var size: CGFloat
    private let weight: Font.Weight
    private let design: Font.Design

    init(
        size: CGFloat,
        weight: Font.Weight,
        design: Font.Design,
        relativeTo: Font.TextStyle
    ) {
        self._size = ScaledMetric(wrappedValue: size, relativeTo: relativeTo)
        self.weight = weight
        self.design = design
    }

    func body(content: Content) -> some View {
        content.font(.system(size: size, weight: weight, design: design))
    }
}

extension View {
    /// 기존 픽셀 크기(예: 18) 를 유지하면서 Dynamic Type 배율을 따른다.
    /// 대부분의 호출처는 body 를 기준으로 잡으면 자연스럽다.
    ///
    /// - Parameters:
    ///   - size: default Dynamic Type 에서의 픽셀 크기.
    ///   - weight: 기본 `.regular`.
    ///   - design: `.default` / `.rounded` / `.serif` / `.monospaced`.
    ///   - relativeTo: 확대 비율 기준이 되는 semantic 스타일.
    ///     `body`(17) 기준 = 일반 본문,
    ///     `title`(28) 기준 = 큰 헤드라인,
    ///     `caption`(12) 기준 = 작은 라벨.
    func scaledFont(
        _ size: CGFloat,
        weight: Font.Weight = .regular,
        design: Font.Design = .default,
        relativeTo: Font.TextStyle = .body
    ) -> some View {
        modifier(ScaledFont(size: size, weight: weight, design: design, relativeTo: relativeTo))
    }
}
