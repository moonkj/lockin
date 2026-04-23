import WidgetKit
import SwiftUI

struct FocusScoreWidget: Widget {
    let kind = "LockinFocusScoreWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FocusScoreWidgetProvider()) { entry in
            FocusScoreWidgetView(entry: entry)
        }
        .configurationDisplayName("오늘의 집중")
        .description("오늘 집중 점수와 나무 성장 단계.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
