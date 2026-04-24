import SwiftUI

/// 대시보드 최상단 카드 — 오늘 집중 점수 + 나무 성장 시각화.
/// 점수 0 ~ 100 을 6 단계 나무로 매핑해서 차분하게 표현.
struct FocusScoreCard: View {
    let score: Int
    /// 사용자가 설정한 오늘의 목표 점수 (0 ~ 100). 0 이면 목표 표시를 숨긴다.
    var goal: Int = 0

    private var stage: TreeStage { TreeStage.from(score: score) }

    var body: some View {
        VStack(spacing: 14) {
            Text("오늘의 집중")
                .scaledFont(14, weight: .medium)
                .foregroundStyle(AppColors.secondaryText)

            tree

            HStack(spacing: 8) {
                Text(score == 0 ? "—" : "\(score)")
                    .scaledFont(48, weight: .semibold, design: .rounded)
                    .foregroundStyle(AppColors.primaryText)
                    .monospacedDigit()

                if score > 0 {
                    Text("/ 100")
                        .scaledFont(17)
                        .foregroundStyle(AppColors.secondaryText)
                        .baselineOffset(6)
                }
            }

            Text(score == 0 ? "오늘이 시작이에요" : stage.label)
                .scaledFont(13)
                .foregroundStyle(AppColors.secondaryText)

            if goal > 0 {
                goalProgress
            }

            Text("돌아가기 +5 (3분 쿨다운) · 집중 15분 완주 +15 · 하루 첫 실행 +5")
                .scaledFont(11)
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

    /// 목표 대비 진척 — 달성 전엔 "목표까지 N점", 달성 후엔 축하 라벨 + 색상 강조.
    @ViewBuilder
    private var goalProgress: some View {
        let clamped = max(0, min(100, goal))
        let progress = Double(min(score, clamped)) / Double(max(1, clamped))
        let reached = score >= clamped
        VStack(spacing: 6) {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppColors.divider.opacity(0.6))
                        .frame(height: 5)
                    Capsule()
                        .fill(reached ? stage.accentColor : AppColors.primaryText)
                        .frame(width: max(4, proxy.size.width * progress), height: 5)
                }
            }
            .frame(height: 5)
            .padding(.horizontal, 24)
            .accessibilityHidden(true)

            Text(reached
                 ? "오늘 목표 \(clamped)점 달성"
                 : "목표까지 \(max(0, clamped - score))점 남음")
                .scaledFont(11, weight: reached ? .semibold : .regular)
                .foregroundStyle(reached ? stage.accentColor : AppColors.secondaryText)
        }
    }

    private var tree: some View {
        ZStack {
            Circle()
                .fill(stage.accentColor.opacity(0.12))
                .frame(width: 72, height: 72)

            Image(systemName: stage.symbolName)
                .scaledFont(32, weight: .regular)
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
