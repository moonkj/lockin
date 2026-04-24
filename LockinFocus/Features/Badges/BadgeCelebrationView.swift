import SwiftUI

/// 뱃지 획득 시 화면을 가로채 중앙에 크게 표시하는 축하 모달.
/// 배경을 어둡게 깔고, 뱃지 아이콘 뒤에 방사형 글로우 + 페이드인 애니메이션.
struct BadgeCelebrationView: View {
    let badge: Badge
    let onConfirm: () -> Void

    @State private var appeared: Bool = false

    var body: some View {
        ZStack {
            // 배경 — fullScreenCover 는 불투명이라 직접 어두운 그라데이션으로 채운다.
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.06, blue: 0.10),
                    Color(red: 0.12, green: 0.12, blue: 0.16)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // 뱃지 색상의 은은한 방사형 글로우를 배경에 깔아 축하 무드를 살림.
            Circle()
                .fill(badge.accentColor.opacity(0.22))
                .frame(width: 420, height: 420)
                .blur(radius: 80)

            VStack(spacing: 20) {
                Text("뱃지 획득")
                    .scaledFont(13, weight: .semibold)
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.7))

                badgeArt

                VStack(spacing: 8) {
                    Text(badge.title)
                        .scaledFont(22, weight: .semibold)
                        .foregroundStyle(AppColors.primaryText)
                        .multilineTextAlignment(.center)

                    Text(badge.detail)
                        .scaledFont(14)
                        .foregroundStyle(AppColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }

                Button(action: onConfirm) {
                    Text("확인")
                        .scaledFont(16, weight: .semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(AppColors.primaryText)
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .padding(28)
            .frame(maxWidth: 340)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(AppColors.background)
                    .shadow(color: .black.opacity(0.2), radius: 24, x: 0, y: 12)
            )
            .scaleEffect(appeared ? 1 : 0.85)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                appeared = true
            }
            // 뱃지 획득 순간 긍정 햅틱 — 모달 등장과 함께.
            Haptics.success()
        }
    }

    private var badgeArt: some View {
        ZStack {
            // 방사형 글로우 두 겹.
            Circle()
                .fill(badge.accentColor.opacity(0.18))
                .frame(width: 180, height: 180)
                .blur(radius: 12)

            Circle()
                .fill(badge.accentColor.opacity(0.28))
                .frame(width: 120, height: 120)

            Circle()
                .fill(badge.accentColor)
                .frame(width: 96, height: 96)
                .shadow(color: badge.accentColor.opacity(0.4), radius: 16, x: 0, y: 6)

            Image(systemName: badge.symbol)
                .scaledFont(42, weight: .semibold)
                .foregroundStyle(.white)
        }
        .frame(width: 180, height: 180)
    }
}

#Preview {
    BadgeCelebrationView(badge: .perfectDay, onConfirm: {})
}
