import SwiftUI

/// 오늘의 명언 확대 시트. 위젯과 같은 폰트 형식 (큰 `"` glyph + 이탤릭 본문 + 이탤릭 저자).
/// 하루 하나만 — 전체 목록 진입 없음. 공유만 제공.
struct QuoteDetailSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var quote: DailyQuote = QuoteProvider.today()

    private var shareText: String {
        if let author = quote.author {
            return "\"\(quote.text)\"\n— \(author)\n\n락인 포커스"
        }
        return "\"\(quote.text)\"\n\n락인 포커스"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 20) {
                    Spacer()

                    Text("\u{201C}")
                        .font(.system(size: 72, weight: .bold, design: .serif))
                        .foregroundStyle(AppColors.secondaryText.opacity(0.7))
                        .frame(height: 42, alignment: .top)

                    Text(quote.text)
                        .font(.system(size: 24, weight: .regular))
                        .italic()
                        .foregroundStyle(AppColors.primaryText)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)

                    if let author = quote.author {
                        Text("— \(author)")
                            .font(.system(size: 16))
                            .italic()
                            .foregroundStyle(AppColors.secondaryText)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }

                    Spacer()

                    ShareLink(item: shareText) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                            Text("공유하기")
                        }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppColors.primaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(AppColors.divider, lineWidth: 1)
                        )
                    }
                    .padding(.bottom, 16)
                }
                .padding(.horizontal, 28)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                        .foregroundStyle(AppColors.secondaryText)
                }
            }
        }
    }
}

#Preview {
    QuoteDetailSheet()
}
