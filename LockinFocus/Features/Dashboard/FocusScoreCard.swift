import SwiftUI

/// 대시보드 최상단 카드 — 오늘 집중 점수 + 나무 성장 시각화.
/// 점수 0 ~ 100 을 6 단계 나무로 매핑해서 차분하게 표현.
struct FocusScoreCard: View {
    let score: Int

    private var stage: TreeStage { TreeStage.from(score: score) }

    var body: some View {
        VStack(spacing: 14) {
            Text("오늘의 집중")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppColors.secondaryText)

            tree

            HStack(spacing: 8) {
                Text(score == 0 ? "—" : "\(score)")
                    .font(.system(size: 48, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.primaryText)
                    .monospacedDigit()

                if score > 0 {
                    Text("/ 100")
                        .font(.system(size: 17))
                        .foregroundStyle(AppColors.secondaryText)
                        .baselineOffset(6)
                }
            }

            Text(score == 0 ? "오늘이 시작이에요" : stage.label)
                .font(.system(size: 13))
                .foregroundStyle(AppColors.secondaryText)

            Text("돌아가기 +5 (3분 쿨다운) · 집중 15분 완주 +15 · 하루 첫 실행 +5")
                .font(.system(size: 11))
                .foregroundStyle(AppColors.secondaryText.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.surface)
        )
    }

    private var tree: some View {
        ZStack {
            Circle()
                .fill(stage.accentColor.opacity(0.12))
                .frame(width: 72, height: 72)

            Image(systemName: stage.symbolName)
                .font(.system(size: 32, weight: .regular))
                .foregroundStyle(stage.accentColor)
                .symbolRenderingMode(.hierarchical)
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        FocusScoreCard(score: 0)
        FocusScoreCard(score: 15)
        FocusScoreCard(score: 55)
        FocusScoreCard(score: 95)
    }
    .padding(24)
    .background(AppColors.background)
}
