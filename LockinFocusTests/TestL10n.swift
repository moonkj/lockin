import Foundation

/// 테스트 locale-agnostic helper.
///
/// ViewInspector 의 `find(text:)` / `find(button:)` 는 화면에 렌더링된 문자열과 정확히
/// 매칭한다. 6개 언어 Localizable.strings 가 활성화된 뒤에는 시뮬레이터 기본 locale
/// (영어) 에서 "취소" 가 "Cancel" 로 렌더되어 테스트가 깨진다.
///
/// 해결: 테스트가 기대하는 Korean 원문 key 를 `L("…")` 로 감싸면 런타임 locale 이
/// 무엇이든 현재 Bundle 기준으로 해석된 값을 반환한다. 즉 시뮬레이터가 영어이면
/// "Cancel" 이 반환되고 버튼 라벨도 "Cancel" 이므로 매칭 성공. Korean 시뮬레이터면
/// "취소" 로 양쪽 일치.
///
/// Localizable.strings 에 없는 key 는 key 자체(= Korean 원문)를 반환해 회귀 없음.
func L(_ key: String) -> String {
    Bundle.main.localizedString(forKey: key, value: key, table: nil)
}
