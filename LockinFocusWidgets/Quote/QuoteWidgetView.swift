import SwiftUI
import WidgetKit

/// 명언 위젯 뷰. 다크모드 지원을 위해 시스템 primary/secondary 색 사용.
/// 본문은 이탤릭, 저자는 오른쪽 정렬.
struct QuoteWidgetView: View {
    let entry: QuoteEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "quote.bubble")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("오늘의 명언")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Text("\"\(entry.quote.text)\"")
                .font(.system(size: family == .systemSmall ? 13 : 15))
                .italic()
                .foregroundStyle(.primary)
                .lineLimit(family == .systemSmall ? 5 : 6)
                .minimumScaleFactor(0.8)
                .multilineTextAlignment(.leading)

            if let author = entry.quote.author {
                Text("— \(author)")
                    .font(.system(size: 11))
                    .italic()
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .lockinWidgetContainer()
    }
}
