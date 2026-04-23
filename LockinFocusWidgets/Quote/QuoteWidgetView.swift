import SwiftUI
import WidgetKit

/// 명언 위젯 뷰. 홈 화면 전용 (Small/Medium/Large). 잠금화면은 UX 권고로 제외.
struct QuoteWidgetView: View {
    let entry: QuoteEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .systemLarge: largeView
            default:           smallMediumView
            }
        }
        .lockinWidgetContainer()
    }

    private var smallMediumView: some View {
        VStack(alignment: .leading, spacing: 8) {
            header

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
    }

    private var largeView: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
                .font(.system(size: 14, weight: .medium))

            Spacer(minLength: 0)

            Text("\"\(entry.quote.text)\"")
                .font(.system(size: 22))
                .italic()
                .foregroundStyle(.primary)
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            if let author = entry.quote.author {
                Text("— \(author)")
                    .font(.system(size: 14))
                    .italic()
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: "quote.bubble")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
            Text("오늘의 명언")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }
}
