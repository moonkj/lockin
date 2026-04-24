import SwiftUI

/// 뱃지 상세 보기 — 그리드에서 획득한 뱃지를 탭했을 때 가운데로 확대되며 회전해 등장.
/// 탭 바깥 or "닫기" 버튼으로 해제.
struct BadgeDetailCardView: View {
    let badge: Badge
    let onClose: () -> Void

    @State private var rotation: Double = -180
    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            // 딤 배경 — 탭하면 닫힘.
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { onClose() }

            VStack(spacing: 18) {
                Text("획득한 뱃지")
                    .scaledFont(12, weight: .semibold)
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.7))

                card

                Text(badge.title)
                    .scaledFont(20, weight: .semibold)
                    .foregroundStyle(.white)

                Text(badge.detail)
                    .scaledFont(14)
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Button(action: onClose) {
                    Text("닫기")
                        .scaledFont(15, weight: .semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 10)
                        .background(
                            Capsule().stroke(Color.white.opacity(0.5), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
            }
            .scaleEffect(scale)
            .opacity(opacity)
            .rotation3DEffect(
                .degrees(rotation),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.6
            )
        }
        .onAppear {
            withAnimation(.spring(response: 0.65, dampingFraction: 0.7)) {
                rotation = 0
                scale = 1
                opacity = 1
            }
        }
    }

    private var card: some View {
        ZStack {
            // 카드 뒷판.
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            badge.accentColor.opacity(0.95),
                            badge.accentColor.opacity(0.72)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 220, height: 300)
                .shadow(color: badge.accentColor.opacity(0.45), radius: 20, x: 0, y: 10)

            VStack(spacing: 14) {
                Circle()
                    .fill(.white.opacity(0.18))
                    .frame(width: 140, height: 140)
                    .overlay(
                        Image(systemName: badge.symbol)
                            .scaledFont(64, weight: .semibold)
                            .foregroundStyle(.white)
                    )

                Text(badge.title)
                    .scaledFont(15, weight: .semibold)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)
                    .lineLimit(2)
            }
            .frame(width: 220, height: 300)
        }
    }
}

#Preview {
    ZStack {
        Color.gray.ignoresSafeArea()
        BadgeDetailCardView(badge: .perfectDay, onClose: {})
    }
}
