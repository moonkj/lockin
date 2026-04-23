import FamilyControls

/// `FamilyActivitySelection` 의 UI 표시용 요약 문자열.
///
/// iOS 의 `ActivityCategoryToken` 은 불투명 값이라 카테고리 안의 앱 수를 코드에서
/// 알 수 없다. "총 N개" 한 덩어리로 표시하면 카테고리 1개(=수십 앱)와 개별 앱 1개가
/// 구분되지 않아 사용자가 혼란스러워 한다. 그래서 앱/카테고리/웹도메인을 분리 표기한다.
extension FamilyActivitySelection {
    /// 예: "앱 5 · 카테고리 2", 빈 상태면 nil.
    var displayBreakdown: String? {
        var parts: [String] = []
        if !applicationTokens.isEmpty {
            parts.append("앱 \(applicationTokens.count)")
        }
        if !categoryTokens.isEmpty {
            parts.append("카테고리 \(categoryTokens.count)")
        }
        if !webDomainTokens.isEmpty {
            parts.append("웹 \(webDomainTokens.count)")
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    /// 선택된 총 항목 수 (앱 + 카테고리 + 웹). "비어있음" 판정용.
    var totalItemCount: Int {
        applicationTokens.count + categoryTokens.count + webDomainTokens.count
    }
}
