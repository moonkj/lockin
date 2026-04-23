import SwiftUI
import WidgetKit

/// 명언 위젯. OneDay 스타일:
/// - 상단에 앱 이름 "락인 포커스" (tracking 있는 소문자 영문 느낌)
/// - 큰 open-quote glyph
/// - 본문은 여백 있게, 이탤릭 유지 (다크모드 자동 대응: primary/secondary)
/// - 저자는 하단 왼쪽 정렬
struct QuoteWidgetView: View {
    let entry: QuoteEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .systemSmall: smallView
            case .systemLarge: largeView
            default:           mediumView
            }
        }
        .lockinWidgetContainer()
    }

    // MARK: - Building blocks

    private var appNameHeader: some View {
        HStack {
            Text("락인 포커스")
                .font(.system(size: 10, weight: .medium))
                .tracking(2)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
    }

    private func bigQuoteGlyph(size: CGFloat) -> some View {
        Text("\u{201C}")
            .font(.system(size: size, weight: .bold, design: .serif))
            .foregroundStyle(.secondary.opacity(0.7))
            .frame(height: size * 0.55, alignment: .top)
    }

    // MARK: - Small

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 6) {
            appNameHeader

            bigQuoteGlyph(size: 28)

            Text(entry.quote.text)
                .font(.system(size: 12))
                .italic()
                .foregroundStyle(.primary)
                .lineLimit(6)
                .minimumScaleFactor(0.6)
                .multilineTextAlignment(.leading)

            if let author = entry.quote.author {
                Text("— \(author)")
                    .font(.system(size: 10))
                    .italic()
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Medium

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 8) {
            appNameHeader

            bigQuoteGlyph(size: 32)

            Text(entry.quote.text)
                .font(.system(size: 14))
                .italic()
                .foregroundStyle(.primary)
                .lineLimit(6)
                .minimumScaleFactor(0.65)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            if let author = entry.quote.author {
                Text("— \(author)")
                    .font(.system(size: 12))
                    .italic()
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Large

    private var largeView: some View {
        VStack(alignment: .leading, spacing: 14) {
            appNameHeader

            bigQuoteGlyph(size: 48)

            Text(entry.quote.text)
                .font(.system(size: 20))
                .italic()
                .foregroundStyle(.primary)
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
                .lineLimit(12)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            if let author = entry.quote.author {
                Text("— \(author)")
                    .font(.system(size: 14))
                    .italic()
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
