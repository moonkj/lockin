import SwiftUI

/// 대시보드 하단 "오늘의 명언" 카드.
/// 위젯과 동일한 폰트 체계 (큰 `"` glyph + 이탤릭 본문 + 이탤릭 저자) 를 따른다.
/// 탭하면 확대 시트가 열린다.
struct DailyQuoteCard: View {
    let onTap: () -> Void
    /// body 재평가마다 Date/Calendar 연산 발생하는 것을 피하기 위해 onAppear 에서 1회 캐시.
    @State private var quote: DailyQuote = QuoteProvider.today()

    var body: some View {
        Button(action: onTap) {
            content
        }
        .buttonStyle(.plain)
        .onAppear { quote = QuoteProvider.today() }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "quote.bubble")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppColors.secondaryText)
                    .accessibilityHidden(true)
                Text("오늘의 명언")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppColors.secondaryText)
            }

            // 큰 opening-quote glyph — 위젯과 동일.
            Text("\u{201C}")
                .font(.system(size: 44, weight: .bold, design: .serif))
                .foregroundStyle(AppColors.secondaryText.opacity(0.7))
                .frame(height: 28, alignment: .top)

            Text(quote.text)
                .font(.system(size: 18))
                .italic()
                .foregroundStyle(AppColors.primaryText)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)

            if let author = quote.author {
                Text("— \(author)")
                    .font(.system(size: 14))
                    .italic()
                    .foregroundStyle(AppColors.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.surface)
        )
    }
}

#Preview {
    DailyQuoteCard(onTap: {})
        .padding(20)
        .background(AppColors.background)
}
