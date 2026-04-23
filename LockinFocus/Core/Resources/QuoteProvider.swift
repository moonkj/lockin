import Foundation

/// 날짜 기반 오늘의 명언 선택기.
/// 같은 날짜에는 항상 같은 명언을 반환한다 (`dayOfYear % count`).
/// 데이터는 당분간 샘플 30개. "원데이" 앱 데이터가 들어오면 교체 예정.
enum QuoteProvider {
    static let sample: [DailyQuote] = [
        .init(text: "시작이 반이다.", author: nil),
        .init(text: "천 리 길도 한 걸음부터.", author: nil),
        .init(text: "포기하지 않는 자가 이긴다.", author: nil),
        .init(text: "오늘의 나는 어제의 나보다 한 발 나아갔다.", author: nil),
        .init(text: "작은 습관이 큰 변화를 만든다.", author: nil),
        .init(text: "집중은 최고의 선물이다.", author: "마사 베크"),
        .init(text: "할 수 있다고 믿는 자가 결국 해낸다.", author: "베르길리우스"),
        .init(text: "시간은 가장 공평한 자원이다.", author: nil),
        .init(text: "완벽보다 꾸준함이 이긴다.", author: nil),
        .init(text: "오늘 한 걸음이 내일의 길이 된다.", author: nil),
        .init(text: "집중하는 사람에게 운이 찾아온다.", author: nil),
        .init(text: "깊이는 속도보다 강하다.", author: nil),
        .init(text: "방해를 줄이면 삶이 또렷해진다.", author: nil),
        .init(text: "한 번에 한 가지만, 그러나 제대로.", author: nil),
        .init(text: "작은 진전도 진전이다.", author: nil),
        .init(text: "모든 큰 일은 지루한 반복에서 나온다.", author: nil),
        .init(text: "지금 이 순간에 머무세요.", author: nil),
        .init(text: "마음이 흔들려도 발은 나아간다.", author: nil),
        .init(text: "자제력은 자유의 다른 이름이다.", author: nil),
        .init(text: "꾸준함이 재능을 이긴다.", author: nil),
        .init(text: "하루를 이기면 한 주가 바뀐다.", author: nil),
        .init(text: "시간을 다스리는 자가 삶을 다스린다.", author: nil),
        .init(text: "작은 선택이 쌓여 당신이 된다.", author: nil),
        .init(text: "집중은 거절에서 시작된다.", author: "스티브 잡스"),
        .init(text: "오늘 최선을 다하면 내일이 가볍다.", author: nil),
        .init(text: "유혹을 한 번 이기면 다음은 쉽다.", author: nil),
        .init(text: "깊이 집중할 때 시간은 선물이 된다.", author: nil),
        .init(text: "멈춤도 전진의 한 형태다.", author: nil),
        .init(text: "나중은 오지 않는다. 지금이 있을 뿐.", author: nil),
        .init(text: "단순함은 궁극의 정교함이다.", author: "레오나르도 다빈치"),
    ]

    /// 오늘에 해당하는 명언 1개 반환.
    static func today(calendar: Calendar = .current, now: Date = Date()) -> DailyQuote {
        guard !sample.isEmpty else {
            return DailyQuote(text: "오늘도 한 걸음.", author: nil)
        }
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: now) ?? 1
        let index = (dayOfYear - 1 + sample.count) % sample.count
        return sample[index]
    }
}
