import SwiftUI
import WidgetKit

/// 집중 점수 위젯 뷰. 홈 화면용(Small/Medium/Large) + 잠금화면 accessory 3종 지원.
struct FocusScoreWidgetView: View {
    let entry: FocusScoreEntry
    @Environment(\.widgetFamily) private var family

    private var stage: TreeStage { TreeStage.from(score: entry.score) }

    var body: some View {
        Group {
            switch family {
            case .systemSmall:          smallView.lockinWidgetContainer()
            case .systemMedium:         mediumView.lockinWidgetContainer()
            case .systemLarge:          largeView.lockinWidgetContainer()
            case .accessoryCircular:    circularAccessory
            case .accessoryRectangular: rectangularAccessory
            case .accessoryInline:      inlineAccessory
            default:                    smallView.lockinWidgetContainer()
            }
        }
    }

    // MARK: - Home screen

    private var smallView: some View {
        VStack(spacing: 6) {
            treeIcon(size: 26, bgSize: 56)

            Text(entry.score == 0 ? "—" : "\(entry.score)")
                .font(.system(size: 30, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .monospacedDigit()

            Text(entry.score == 0 ? "오늘이 시작이에요" : stage.label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var mediumView: some View {
        HStack(spacing: 16) {
            treeIcon(size: 34, bgSize: 72)

            VStack(alignment: .leading, spacing: 4) {
                Text("오늘의 집중")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(entry.score == 0 ? "—" : "\(entry.score)")
                        .font(.system(size: 36, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                        .monospacedDigit()
                    if entry.score > 0 {
                        Text("/ 100")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                }

                Text(entry.score == 0 ? "오늘이 시작이에요" : stage.label)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var largeView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                treeIcon(size: 36, bgSize: 76)
                VStack(alignment: .leading, spacing: 4) {
                    Text("오늘의 집중")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(entry.score == 0 ? "—" : "\(entry.score)")
                            .font(.system(size: 42, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                            .monospacedDigit()
                        if entry.score > 0 {
                            Text("/ 100")
                                .font(.system(size: 16))
                                .foregroundStyle(.secondary)
                        }
                    }
                    Text(entry.score == 0 ? "오늘이 시작이에요" : stage.label)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("지난 7일")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                if let history = entry.weeklyHistory, !history.isEmpty {
                    weeklyBars(history: history)
                } else {
                    Text("아직 기록이 없어요.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func weeklyBars(history: [Int]) -> some View {
        let maxHeight: CGFloat = 72
        return HStack(alignment: .bottom, spacing: 10) {
            ForEach(Array(history.enumerated()), id: \.offset) { _, score in
                VStack(spacing: 4) {
                    Spacer(minLength: 0)
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(.primary)
                        .frame(height: max(4, CGFloat(score) / 100.0 * maxHeight))
                        .opacity(score == 0 ? 0.18 : 1.0)
                    Text("\(score)")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: maxHeight + 18)
    }

    // MARK: - Lock screen accessories

    private var circularAccessory: some View {
        Gauge(value: Double(entry.score), in: 0...100) {
            Text("집중")
        } currentValueLabel: {
            Text("\(entry.score)")
                .font(.system(size: 14, weight: .semibold))
        }
        .gaugeStyle(.accessoryCircular)
        .widgetAccentable()
    }

    private var rectangularAccessory: some View {
        HStack(spacing: 8) {
            Image(systemName: stage.symbolName)
                .font(.system(size: 18))
                .symbolRenderingMode(.hierarchical)
                .widgetAccentable()
            VStack(alignment: .leading, spacing: 1) {
                Text("오늘의 집중")
                    .font(.system(size: 10))
                Text("\(entry.score) · \(stage.label)")
                    .font(.system(size: 14, weight: .medium))
                    .widgetAccentable()
            }
            Spacer(minLength: 0)
        }
    }

    private var inlineAccessory: some View {
        Text("집중 \(entry.score)/100")
    }

    // MARK: - Tree icon

    @ViewBuilder
    private func treeIcon(size: CGFloat, bgSize: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(stage.accentColor.opacity(0.18))
                .frame(width: bgSize, height: bgSize)
            Image(systemName: stage.symbolName)
                .font(.system(size: size))
                .foregroundStyle(stage.accentColor)
                .symbolRenderingMode(.hierarchical)
        }
    }
}
