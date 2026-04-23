import SwiftUI

/// 게이미피케이션: 오늘 집중 점수(0~100)에 따라 나무가 성장한다.
/// 이모지 대신 SF Symbol + 색상 단계로 표현 (카피 가이드: 과도한 이모지 금지).
enum TreeStage: Int, CaseIterable {
    case seed       // 0
    case sprout     // 1~20
    case sapling    // 21~40
    case young      // 41~60
    case grown      // 61~80
    case flourish   // 81~100

    static func from(score: Int) -> TreeStage {
        switch score {
        case ..<1: return .seed
        case 1...20: return .sprout
        case 21...40: return .sapling
        case 41...60: return .young
        case 61...80: return .grown
        default: return .flourish
        }
    }

    var label: String {
        switch self {
        case .seed:     return "씨앗"
        case .sprout:   return "새싹"
        case .sapling:  return "어린 나무"
        case .young:    return "자라는 나무"
        case .grown:    return "큰 나무"
        case .flourish: return "열매 맺는 나무"
        }
    }

    /// SF Symbol 이름 (iOS 16+ 보증).
    var symbolName: String {
        switch self {
        case .seed:     return "circle.fill"
        case .sprout:   return "leaf"
        case .sapling:  return "leaf.fill"
        case .young:    return "camera.macro"
        case .grown:    return "tree"
        case .flourish: return "tree.fill"
        }
    }

    /// 단계별 강조 색 — 차분한 초록 계열 + 마지막 단계만 따뜻한 금색.
    var accentColor: Color {
        switch self {
        case .seed:     return Color(red: 0.65, green: 0.65, blue: 0.67)
        case .sprout:   return Color(red: 0.55, green: 0.75, blue: 0.50)
        case .sapling:  return Color(red: 0.40, green: 0.70, blue: 0.45)
        case .young:    return Color(red: 0.22, green: 0.62, blue: 0.40)
        case .grown:    return Color(red: 0.15, green: 0.55, blue: 0.35)
        case .flourish: return Color(red: 0.92, green: 0.68, blue: 0.20)
        }
    }
}
