import SwiftUI

/// 뱃지 카탈로그 — 사용자의 행동 패턴에 따라 잠금 해제되는 성취 배지.
/// 각 뱃지는 **일회성**(한 번 획득하면 영구) 이며, 규칙 판정은 `BadgeEngine` 이 담당.
/// id(rawValue) 는 UserDefaults 에 저장되므로 **절대 변경 금지**.
enum Badge: String, Codable, CaseIterable, Identifiable {
    // Shield 앞에서 "돌아가기" 선택을 집계하는 시리즈 (= 유혹을 극복한 횟수).
    case firstReturn
    case returnNovice    // 10회
    case returnAdept     // 50회
    case returnMaster    // 100회

    // 점수 관련
    case perfectDay      // 하루 100점
    case streak3Days     // 3일 연속 기록
    case streak7Days     // 7일 연속 기록

    // 모드 관련
    case strictSurvivor  // 엄격 모드 해제 완료 1회
    case detoxStarter    // 도파민 디톡스 첫 사용

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstReturn:    return "첫 집중 지킴"
        case .returnNovice:   return "집중 지킴 10회"
        case .returnAdept:    return "집중 지킴 50회"
        case .returnMaster:   return "집중 지킴 100회"
        case .perfectDay:     return "완벽한 하루"
        case .streak3Days:    return "3일 연속 집중"
        case .streak7Days:    return "일주일 완주"
        case .strictSurvivor: return "엄격 모드 완주"
        case .detoxStarter:   return "첫 디톡스"
        }
    }

    var detail: String {
        switch self {
        case .firstReturn:    return "차단 화면에서 처음으로 돌아섰어요."
        case .returnNovice:   return "차단 화면에서 10번 돌아섰어요."
        case .returnAdept:    return "차단 화면에서 50번 돌아섰어요."
        case .returnMaster:   return "차단 화면에서 100번 돌아선 사람은 흔치 않아요."
        case .perfectDay:     return "하루 동안 100점을 모았어요."
        case .streak3Days:    return "3일 동안 매일 집중 점수를 남겼어요."
        case .streak7Days:    return "7일 연속 집중을 이어갔어요."
        case .strictSurvivor: return "엄격 모드를 끝까지 겪고 해제했어요."
        case .detoxStarter:   return "도파민 디톡스 모드를 시작해봤어요."
        }
    }

    var symbol: String {
        switch self {
        case .firstReturn:    return "arrow.uturn.backward.circle.fill"
        case .returnNovice:   return "10.circle.fill"
        case .returnAdept:    return "50.circle.fill"
        case .returnMaster:   return "100.circle.fill"
        case .perfectDay:     return "sun.max.fill"
        case .streak3Days:    return "flame.fill"
        case .streak7Days:    return "flame.circle.fill"
        case .strictSurvivor: return "lock.shield.fill"
        case .detoxStarter:   return "bolt.circle.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .firstReturn:    return Color(red: 0.22, green: 0.62, blue: 0.40)
        case .returnNovice:   return Color(red: 0.22, green: 0.62, blue: 0.40)
        case .returnAdept:    return Color(red: 0.15, green: 0.55, blue: 0.35)
        case .returnMaster:   return Color(red: 0.92, green: 0.68, blue: 0.20)
        case .perfectDay:     return Color(red: 0.92, green: 0.68, blue: 0.20)
        case .streak3Days:    return Color(red: 0.88, green: 0.40, blue: 0.20)
        case .streak7Days:    return Color(red: 0.80, green: 0.25, blue: 0.18)
        case .strictSurvivor: return Color(red: 0.20, green: 0.25, blue: 0.55)
        case .detoxStarter:   return Color(red: 0.55, green: 0.30, blue: 0.75)
        }
    }
}
