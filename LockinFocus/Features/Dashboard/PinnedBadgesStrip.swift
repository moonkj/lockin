import SwiftUI

/// Dashboard header 아래에 띄우는 핀 고정 뱃지 수평 스트립.
/// 최대 3개. 한 개도 없으면 view 자체를 숨기기 위해 EmptyView 반환.
struct PinnedBadgesStrip: View {
    let pinnedIDs: [String]
    let onTap: (Badge) -> Void

    /// id → Badge dict 캐시. body 재평가마다 Badge.allCases.first(where:) × 핀 수
    /// (최대 26 × 3 = 78 비교) 를 반복하던 cost 제거. static let 은 thread-safe.
    private static let badgesByID: [String: Badge] = {
        var dict: [String: Badge] = [:]
        for badge in Badge.allCases {
            dict[badge.id] = badge
        }
        return dict
    }()

    private var pinnedBadges: [Badge] {
        pinnedIDs.compactMap { Self.badgesByID[$0] }
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
