import SwiftUI
import WidgetKit

struct FocusScoreWidgetView: View {
    let entry: FocusScoreEntry
    @Environment(\.widgetFamily) private var family

    private var stage: TreeStage { TreeStage.from(score: entry.score) }

    var body: some View {
        Group {
            if family == .systemSmall {
                smallView
            } else {
                mediumView
            }
        }
        .lockinWidgetContainer()
    }

    private var smallView: some View {
        VStack(spacing: 6) {
            treeIcon(size: 26, bgSize: 56)

            Text(entry.score == 0 ? "—" : "\(entry.score)")
                .font(.system(size: 30, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.primaryText)
                .monospacedDigit()

            Text(entry.score == 0 ? "오늘이 시작이에요" : stage.label)
                .font(.system(size: 11))
                .foregroundStyle(AppColors.secondaryText)
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
                    .foregroundStyle(AppColors.secondaryText)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(entry.score == 0 ? "—" : "\(entry.score)")
                        .font(.system(size: 36, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppColors.primaryText)
                        .monospacedDigit()
                    if entry.score > 0 {
                        Text("/ 100")
                            .font(.system(size: 14))
                            .foregroundStyle(AppColors.secondaryText)
                    }
                }

                Text(entry.score == 0 ? "오늘이 시작이에요" : stage.label)
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.secondaryText)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func treeIcon(size: CGFloat, bgSize: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(stage.accentColor.opacity(0.14))
                .frame(width: bgSize, height: bgSize)
            Image(systemName: stage.symbolName)
                .font(.system(size: size))
                .foregroundStyle(stage.accentColor)
                .symbolRenderingMode(.hierarchical)
        }
    }
}
