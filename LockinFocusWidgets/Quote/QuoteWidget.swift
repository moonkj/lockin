import WidgetKit
import SwiftUI

struct QuoteWidget: Widget {
    let kind = "LockinFocusQuoteWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuoteWidgetProvider()) { entry in
            QuoteWidgetView(entry: entry)
                .widgetURL(URL(string: "lockinfocus://quoteDetail"))
        }
        .configurationDisplayName("오늘의 명언")
        .description("날마다 바뀌는 집중 한 줄. Small · Medium · Large.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
