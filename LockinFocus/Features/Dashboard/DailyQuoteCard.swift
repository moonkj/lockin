import SwiftUI

/// 대시보드 하단 "오늘의 명언" 카드. 탭하면 전체 명언 목록 시트가 열린다.
/// 본문은 이탤릭, 저자는 카드 하단 오른쪽 정렬.
struct DailyQuoteCard: View {
    let onTap: () -> Void
    private var quote: DailyQuote { QuoteProvider.today() }

    var body: some View {
        Button(action: onTap) {
            content
        }
        .buttonStyle(.plain)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "quote.bubble")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppColors.secondaryText)
                Text("오늘의 명언")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppColors.secondaryText)
            }

            Text("\"\(quote.text)\"")
                .font(.system(size: 18, weight: .regular))
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
