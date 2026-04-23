import SwiftUI

/// 뱃지 카탈로그 — 사용자의 행동 패턴에 따라 잠금 해제되는 성취 배지.
/// 각 뱃지는 **일회성**(한 번 획득하면 영구) 이며, 규칙 판정은 `BadgeEngine` 이 담당.
/// id(rawValue) 는 UserDefaults 에 저장되므로 **절대 변경 금지**.
enum Badge: String, Codable, CaseIterable, Identifiable {
    // 돌아가기 누적
    case firstReturn
    case returnNovice
    case returnAdept
    case returnMaster

    // 점수·스트릭
    case perfectDay
    case streak3Days
    case streak7Days

    // 엄격
    case strictSurvivor
    case strictSurvivor3

    // 수동 집중·누적 집중 시간
    case firstManualFocus
    case focusHour1
    case focusHour5
    case focusHour20
    case focusHour50

    // 주간 평균
    case weekAverage60
    case weekAverage80

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstReturn:       return "첫 집중 지킴"
        case .returnNovice:      return "집중 지킴 10회"
        case .returnAdept:       return "집중 지킴 50회"
        case .returnMaster:      return "집중 지킴 100회"
        case .perfectDay:        return "완벽한 하루"
        case .streak3Days:       return "3일 연속 집중"
        case .streak7Days:       return "일주일 완주"
        case .strictSurvivor:    return "엄격 모드 완주"
        case .strictSurvivor3:   return "엄격 3회 완주"
        case .firstManualFocus:  return "첫 집중 시작"
        case .focusHour1:        return "1시간 집중"
        case .focusHour5:        return "5시간 집중"
        case .focusHour20:       return "20시간 집중"
        case .focusHour50:       return "50시간 집중"
        case .weekAverage60:     return "주 평균 60점"
        case .weekAverage80:     return "주 평균 80점"
        }
    }

    var detail: String {
        switch self {
        case .firstReturn:       return "차단 화면에서 처음으로 돌아섰어요."
        case .returnNovice:      return "차단 화면에서 10번 돌아섰어요."
        case .returnAdept:       return "차단 화면에서 50번 돌아섰어요."
        case .returnMaster:      return "차단 화면에서 100번 돌아선 사람은 흔치 않아요."
        case .perfectDay:        return "하루 동안 100점을 모았어요."
        case .streak3Days:       return "3일 동안 매일 집중 점수를 남겼어요."
        case .streak7Days:       return "7일 연속 집중을 이어갔어요."
        case .strictSurvivor:    return "엄격 모드를 끝까지 겪고 해제했어요."
        case .strictSurvivor3:   return "엄격 모드를 세 번 완주했어요."
        case .firstManualFocus:  return "'지금 집중 시작' 을 처음 눌렀어요."
        case .focusHour1:        return "누적 집중 시간이 1시간을 넘었어요."
        case .focusHour5:        return "누적 집중 시간이 5시간을 넘었어요."
        case .focusHour20:       return "누적 집중 시간이 20시간을 넘었어요."
        case .focusHour50:       return "누적 집중 시간이 50시간을 넘었어요."
        case .weekAverage60:     return "최근 7일 평균 점수가 60을 넘었어요."
        case .weekAverage80:     return "최근 7일 평균 점수가 80을 넘었어요."
        }
    }

    var symbol: String {
        switch self {
        case .firstReturn:       return "arrow.uturn.backward.circle.fill"
        case .returnNovice:      return "10.circle.fill"
        case .returnAdept:       return "50.circle.fill"
        case .returnMaster:      return "100.circle.fill"
        case .perfectDay:        return "sun.max.fill"
        case .streak3Days:       return "flame.fill"
        case .streak7Days:       return "flame.circle.fill"
        case .strictSurvivor:    return "lock.shield.fill"
        case .strictSurvivor3:   return "lock.shield"
        case .firstManualFocus:  return "play.circle.fill"
        case .focusHour1:        return "hourglass"
        case .focusHour5:        return "hourglass.tophalf.filled"
        case .focusHour20:       return "hourglass.bottomhalf.filled"
        case .focusHour50:       return "clock.arrow.circlepath"
        case .weekAverage60:     return "star.leadinghalf.filled"
        case .weekAverage80:     return "star.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .firstReturn:       return Color(red: 0.22, green: 0.62, blue: 0.40)
        case .returnNovice:      return Color(red: 0.22, green: 0.62, blue: 0.40)
        case .returnAdept:       return Color(red: 0.15, green: 0.55, blue: 0.35)
        case .returnMaster:      return Color(red: 0.92, green: 0.68, blue: 0.20)
        case .perfectDay:        return Color(red: 0.92, green: 0.68, blue: 0.20)
        case .streak3Days:       return Color(red: 0.88, green: 0.40, blue: 0.20)
        case .streak7Days:       return Color(red: 0.80, green: 0.25, blue: 0.18)
        case .strictSurvivor:    return Color(red: 0.20, green: 0.25, blue: 0.55)
        case .strictSurvivor3:   return Color(red: 0.10, green: 0.15, blue: 0.45)
        case .firstManualFocus:  return Color(red: 0.20, green: 0.55, blue: 0.75)
        case .focusHour1:        return Color(red: 0.30, green: 0.55, blue: 0.75)
        case .focusHour5:        return Color(red: 0.25, green: 0.50, blue: 0.80)
        case .focusHour20:       return Color(red: 0.18, green: 0.42, blue: 0.78)
        case .focusHour50:       return Color(red: 0.60, green: 0.45, blue: 0.85)
        case .weekAverage60:     return Color(red: 0.80, green: 0.60, blue: 0.20)
        case .weekAverage80:     return Color(red: 0.90, green: 0.55, blue: 0.10)
        }
    }
}
