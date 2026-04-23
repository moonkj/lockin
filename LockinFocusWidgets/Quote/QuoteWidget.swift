import WidgetKit
import SwiftUI

struct QuoteWidget: Widget {
    let kind = "LockinFocusQuoteWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuoteWidgetProvider()) { entry in
            QuoteWidgetView(entry: entry)
        }
        .configurationDisplayName("오늘의 한 줄")
        .description("날마다 바뀌는 집중 한 줄 명언.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
