import SwiftUI

/// 대시보드 하단 "오늘의 명언" 카드.
/// 날짜에 따라 샘플 리스트에서 한 문장을 뽑아 하루 동안 동일하게 보여준다.
struct DailyQuoteCard: View {
    private var quote: DailyQuote { QuoteProvider.today() }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "quote.bubble")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppColors.secondaryText)
                Text("오늘의 한 줄")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppColors.secondaryText)
            }

            Text("“\(quote.text)”")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(AppColors.primaryText)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            if let author = quote.author {
                Text("— \(author)")
                    .font(.system(size: 13))
                    .foregroundStyle(AppColors.secondaryText)
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
    DailyQuoteCard()
        .padding(20)
        .background(AppColors.background)
}
