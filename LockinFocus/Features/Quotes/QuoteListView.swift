import SwiftUI

/// 전체 명언 리스트. 오늘의 명언을 상단에 고정하고 나머지 393+개를 스크롤.
struct QuoteListView: View {
    @Environment(\.dismiss) private var dismiss

    private let all: [DailyQuote] = QuoteProvider.allQuotes()
    private let todays: DailyQuote = QuoteProvider.today()

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                List {
                    Section {
                        quoteCell(todays)
                            .listRowBackground(AppColors.surface)
                    } header: {
                        sectionHeader("오늘의 한 줄")
                    }

                    Section {
                        ForEach(Array(all.enumerated()), id: \.offset) { _, quote in
                            quoteCell(quote)
                                .listRowBackground(AppColors.surface)
                        }
                    } header: {
                        sectionHeader("전체 (\(all.count))")
                    }
                }
                .scrollContentBackground(.hidden)
                .background(AppColors.background)
            }
            .navigationTitle("명언")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                        .foregroundStyle(AppColors.secondaryText)
                }
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(AppColors.primaryText)
            .textCase(nil)
    }

    private func quoteCell(_ quote: DailyQuote) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("“\(quote.text)”")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppColors.primaryText)
                .fixedSize(horizontal: false, vertical: true)
            if let author = quote.author {
                Text("— \(author)")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.secondaryText)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    QuoteListView()
}
