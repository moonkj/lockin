import SwiftUI

/// 오늘의 명언 확대 시트. 하루 하나만 — 전체 목록 진입 없음.
/// 공유만 제공.
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

                VStack(spacing: 24) {
                    Spacer()

                    VStack(spacing: 20) {
                        Image(systemName: "quote.bubble.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(AppColors.secondaryText)

                        Text("\"\(quote.text)\"")
                            .font(.system(size: 22, weight: .regular))
                            .italic()
                            .foregroundStyle(AppColors.primaryText)
                            .multilineTextAlignment(.center)
                            .lineSpacing(6)
                            .fixedSize(horizontal: false, vertical: true)

                        if let author = quote.author {
                            Text("— \(author)")
                                .font(.system(size: 16))
                                .italic()
                                .foregroundStyle(AppColors.secondaryText)
                        }
                    }
                    .padding(.horizontal, 28)

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
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
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
