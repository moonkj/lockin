import SwiftUI
import Charts

/// 최근 7일 집중 점수 바 차트 + 주 평균.
struct WeeklyReportView: View {
    @EnvironmentObject var deps: AppDependencies
    @Environment(\.dismiss) private var dismiss

    @State private var history: [DailyFocus] = []

    private var weekAverage: Int {
        guard !history.isEmpty else { return 0 }
        let sum = history.reduce(0) { $0 + $1.score }
        return sum / history.count
    }

    private var bestDay: DailyFocus? {
        history.max(by: { $0.score < $1.score })
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header

                        chart

                        summary

                        Spacer(minLength: 16)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("주간 리포트")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                        .foregroundStyle(AppColors.secondaryText)
                }
            }
        }
        .onAppear(perform: load)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("지난 7일")
                .font(.system(size: 13))
                .foregroundStyle(AppColors.secondaryText)

            Text("평균 \(weekAverage) / 100")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(AppColors.primaryText)
        }
    }

    private var chart: some View {
        Chart(history) { item in
            BarMark(
                x: .value("날짜", item.shortWeekday),
                y: .value("점수", item.score)
            )
            .foregroundStyle(AppColors.primaryText)
            .cornerRadius(6)
        }
        .chartYScale(domain: 0...100)
        .frame(height: 220)
        .padding(.vertical, 8)
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let best = bestDay, best.score > 0 {
                row("가장 집중한 날", value: "\(best.shortWeekday)요일 · \(best.score)점")
            }
            row("기록된 날", value: "\(history.filter { $0.score > 0 }.count)일")
            row("총 점수 합", value: "\(history.reduce(0) { $0 + $1.score })점")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.surface)
        )
    }

    private func row(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14))
                .foregroundStyle(AppColors.secondaryText)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppColors.primaryText)
        }
    }

    private func load() {
        history = deps.persistence.dailyFocusHistory(lastDays: 7)
    }
}

#Preview {
    WeeklyReportView()
        .environmentObject(AppDependencies.preview())
}
