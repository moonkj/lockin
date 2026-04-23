import SwiftUI
import Charts

/// 리포트 — 일간/주간/월간 3개 범위를 Picker 로 전환.
struct ReportView: View {
    @EnvironmentObject var deps: AppDependencies
    @Environment(\.dismiss) private var dismiss

    enum Range: String, CaseIterable, Identifiable {
        case daily = "일간"
        case weekly = "주간"
        case monthly = "월간"
        var id: String { rawValue }
    }

    @State private var range: Range = .weekly

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                VStack(spacing: 16) {
                    HStack(spacing: 8) {
                        ForEach(Range.allCases) { r in
                            let isSelected = range == r
                            Button {
                                range = r
                            } label: {
                                Text(r.rawValue)
                                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                                    .foregroundStyle(isSelected ? Color.white : AppColors.secondaryText)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 36)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(isSelected ? AppColors.primaryText : AppColors.surface)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .stroke(isSelected ? Color.clear : AppColors.divider, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    ScrollView {
                        switch range {
                        case .daily:   DailyReport()
                        case .weekly:  WeeklyReport()
                        case .monthly: MonthlyReport()
                        }
                    }
                }
            }
            .navigationTitle("리포트")
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

// MARK: - 일간

private struct DailyReport: View {
    @EnvironmentObject var deps: AppDependencies

    private var score: Int { deps.persistence.focusScoreToday }
    private var stage: TreeStage { TreeStage.from(score: score) }

    var body: some View {
        VStack(spacing: 16) {
            card {
                VStack(spacing: 14) {
                    treeCircle
                    Text(score == 0 ? "—" : "\(score)")
                        .font(.system(size: 48, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppColors.primaryText)
                        .monospacedDigit()
                    Text(score == 0 ? "오늘이 시작이에요" : stage.label)
                        .font(.system(size: 13))
                        .foregroundStyle(AppColors.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            card {
                VStack(spacing: 10) {
                    summaryRow("남은 목표", value: score == 100 ? "완료" : "+\(100 - score)")
                    Divider()
                    summaryRow("획득 뱃지", value: "\(deps.persistence.earnedBadgeIDs.count) / \(Badge.allCases.count)")
                    Divider()
                    summaryRow("누적 집중 지킴", value: "\(deps.persistence.totalReturnCount)회")
                }
            }
        }
        .padding(20)
    }

    private var treeCircle: some View {
        ZStack {
            Circle()
                .fill(stage.accentColor.opacity(0.16))
                .frame(width: 84, height: 84)
            Image(systemName: stage.symbolName)
                .font(.system(size: 36))
                .foregroundStyle(stage.accentColor)
                .symbolRenderingMode(.hierarchical)
        }
    }
}

// MARK: - 주간

private struct WeeklyReport: View {
    @EnvironmentObject var deps: AppDependencies

    @State private var history: [DailyFocus] = []

    private var average: Int {
        guard !history.isEmpty else { return 0 }
        return history.reduce(0) { $0 + $1.score } / history.count
    }

    var body: some View {
        VStack(spacing: 16) {
            card {
                VStack(alignment: .leading, spacing: 4) {
                    Text("최근 7일 평균")
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.secondaryText)
                    Text("\(average) / 100")
                        .font(.system(size: 30, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppColors.primaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            card {
                Chart(history) { item in
                    BarMark(
                        x: .value("요일", item.shortWeekday),
                        y: .value("점수", item.score)
                    )
                    .foregroundStyle(AppColors.primaryText)
                    .cornerRadius(4)
                }
                .chartYScale(domain: 0...100)
                .frame(height: 200)
            }

            card {
                VStack(spacing: 10) {
                    summaryRow("기록된 날", value: "\(history.filter { $0.score > 0 }.count)일")
                    Divider()
                    summaryRow("총점", value: "\(history.reduce(0) { $0 + $1.score })점")
                    if let best = history.max(by: { $0.score < $1.score }), best.score > 0 {
                        Divider()
                        summaryRow("최고 점수", value: "\(best.shortWeekday)요일 \(best.score)점")
                    }
                }
            }
        }
        .padding(20)
        .onAppear { history = deps.persistence.dailyFocusHistory(lastDays: 7) }
    }
}

// MARK: - 월간

private struct MonthlyReport: View {
    @EnvironmentObject var deps: AppDependencies

    @State private var history: [DailyFocus] = []

    private var average: Int {
        guard !history.isEmpty else { return 0 }
        return history.reduce(0) { $0 + $1.score } / history.count
    }

    private var activeDays: Int {
        history.filter { $0.score > 0 }.count
    }

    var body: some View {
        VStack(spacing: 16) {
            card {
                HStack(spacing: 20) {
                    stat(title: "평균", value: "\(average)")
                    Divider().frame(height: 36)
                    stat(title: "기록 일수", value: "\(activeDays)")
                    Divider().frame(height: 36)
                    stat(title: "총점", value: "\(history.reduce(0) { $0 + $1.score })")
                }
                .frame(maxWidth: .infinity)
            }

            card {
                VStack(alignment: .leading, spacing: 8) {
                    Text("최근 30일")
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.secondaryText)
                    Chart(history) { item in
                        BarMark(
                            x: .value("날짜", item.displayDate, unit: .day),
                            y: .value("점수", item.score)
                        )
                        .foregroundStyle(AppColors.primaryText)
                        .cornerRadius(2)
                    }
                    .chartYScale(domain: 0...100)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day, count: 7))
                    }
                    .frame(height: 180)
                }
            }
        }
        .padding(20)
        .onAppear { history = deps.persistence.dailyFocusHistory(lastDays: 30) }
    }

    private func stat(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.primaryText)
            Text(title)
                .font(.system(size: 11))
                .foregroundStyle(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Shared

private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
    content()
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.surface)
        )
}

private func summaryRow(_ title: String, value: String) -> some View {
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

#Preview {
    ReportView()
        .environmentObject(AppDependencies.preview())
}
