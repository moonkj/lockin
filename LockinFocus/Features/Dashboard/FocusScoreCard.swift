import SwiftUI

/// 대시보드 최상단 카드 — 오늘 집중 점수.
/// 쟁점 14: 숫자 0~100 만. 나무 그림/시도 횟수는 Phase 5.
struct FocusScoreCard: View {
    let score: Int

    var body: some View {
        VStack(spacing: 12) {
            Text("오늘의 집중")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppColors.secondaryText)
                .textCase(nil)

            Text(score == 0 ? "—" : "\(score)")
                .font(.system(size: 64, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.primaryText)
                .monospacedDigit()

            Text(score == 0 ? "오늘이 시작이에요" : "\(score) / 100")
                .font(.system(size: 13))
                .foregroundStyle(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.surface)
        )
    }
}

#Preview {
    VStack(spacing: 12) {
        FocusScoreCard(score: 0)
        FocusScoreCard(score: 72)
    }
    .padding(24)
    .background(AppColors.background)
}
