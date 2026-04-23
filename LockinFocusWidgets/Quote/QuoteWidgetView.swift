import SwiftUI
import WidgetKit

struct QuoteWidgetView: View {
    let entry: QuoteEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "quote.bubble")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppColors.secondaryText)
                Text("오늘의 한 줄")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppColors.secondaryText)
            }

            Text("“\(entry.quote.text)”")
                .font(.system(size: family == .systemSmall ? 13 : 15, weight: .medium))
                .foregroundStyle(AppColors.primaryText)
                .lineLimit(family == .systemSmall ? 5 : 6)
                .minimumScaleFactor(0.8)
                .multilineTextAlignment(.leading)

            if let author = entry.quote.author {
                Text("— \(author)")
                    .font(.system(size: 11))
                    .foregroundStyle(AppColors.secondaryText)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .lockinWidgetContainer()
    }
}
