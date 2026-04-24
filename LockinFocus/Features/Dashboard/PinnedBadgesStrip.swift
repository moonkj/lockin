import SwiftUI

/// Dashboard header 아래에 띄우는 핀 고정 뱃지 수평 스트립.
/// 최대 3개. 한 개도 없으면 view 자체를 숨기기 위해 EmptyView 반환.
struct PinnedBadgesStrip: View {
    let pinnedIDs: [String]
    let onTap: (Badge) -> Void

    private var pinnedBadges: [Badge] {
        pinnedIDs.compactMap { id in Badge.allCases.first(where: { $0.id == id }) }
    }

    var body: some View {
        if pinnedBadges.isEmpty {
            EmptyView()
        } else {
            HStack(spacing: 10) {
                ForEach(pinnedBadges, id: \.id) { badge in
                    Button {
                        onTap(badge)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: badge.symbol)
                                .scaledFont(12, weight: .semibold)
                                .foregroundStyle(badge.accentColor)
                            Text(badge.title)
                                .scaledFont(11, weight: .medium)
                                .foregroundStyle(AppColors.primaryText)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(AppColors.surface)
                        )
                        .overlay(
                            Capsule().stroke(badge.accentColor.opacity(0.3), lineWidth: 1)
                        )
                        .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("핀 고정 뱃지 \(badge.title)")
                }
                Spacer(minLength: 0)
            }
        }
    }
}
