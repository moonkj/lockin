import WidgetKit
import SwiftUI

struct FocusScoreWidget: Widget {
    let kind = "LockinFocusScoreWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FocusScoreWidgetProvider()) { entry in
            FocusScoreWidgetView(entry: entry)
                .widgetURL(URL(string: "lockinfocus://weeklyReport"))
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
