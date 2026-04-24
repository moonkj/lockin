import WidgetKit
import SwiftUI

struct FocusScoreWidget: Widget {
    let kind = "LockinFocusScoreWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FocusScoreWidgetProvider()) { entry in
            // 상태-인지형 deep link — 점수 0 + 비활성 시 바로 집중 시작 intent,
            // 활성 중엔 대시보드, 그 외엔 주간 리포트로.
            FocusScoreWidgetView(entry: entry)
                .widgetURL(entry.deepLinkURL)
        }
        .configurationDisplayName("오늘의 집중")
        .description("집중 점수 + 나무 성장 단계. Large 는 지난 7일 그래프 포함.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}
