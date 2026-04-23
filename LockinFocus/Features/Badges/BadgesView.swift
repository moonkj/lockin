import SwiftUI

/// 뱃지 수집 화면. 획득한 것은 컬러, 미획득은 회색 잠금 상태로 표시.
struct BadgesView: View {
    @EnvironmentObject var deps: AppDependencies
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    private var earned: Set<String> { deps.persistence.earnedBadgeIDs }
    private var all: [Badge] { Badge.allCases }

    @State private var selectedBadge: Badge?

    init(initialSelectedBadge: Badge? = nil) {
        _selectedBadge = State(initialValue: initialSelectedBadge)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        summary

                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(all) { badge in
                                cell(for: badge, unlocked: earned.contains(badge.id))
                            }
                        }

                        Text("순위 뱃지는 참가자 100명 이상인 랭킹에서만 획득할 수 있어요.")
                            .font(.system(size: 12))
                            .foregroundStyle(AppColors.secondaryText)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 8)
                            .padding(.horizontal, 8)

                        Spacer(minLength: 12)
                    }
                    .padding(20)
                }

                if let selectedBadge {
                    BadgeDetailCardView(badge: selectedBadge) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            self.selectedBadge = nil
                        }
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
            .navigationTitle("뱃지")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                        .foregroundStyle(AppColors.secondaryText)
                }
            }
        }
    }

    private var summary: some View {
        HStack {
            Text("\(earned.count) / \(all.count) 획득")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppColors.primaryText)
            Spacer()
            Text("집중 지킴 \(deps.persistence.totalReturnCount)회")
                .font(.system(size: 12))
                .foregroundStyle(AppColors.secondaryText)
        }
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private func cell(for badge: Badge, unlocked: Bool) -> some View {
        let cellBody = VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill((unlocked ? badge.accentColor : AppColors.divider).opacity(unlocked ? 0.14 : 0.4))
                    .frame(width: 68, height: 68)
                Image(systemName: unlocked ? badge.symbol : "lock.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(unlocked ? badge.accentColor : AppColors.secondaryText)
                    .symbolRenderingMode(.hierarchical)
            }

            Text(badge.title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(unlocked ? AppColors.primaryText : AppColors.secondaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.9)

            Text(unlocked ? badge.detail : "아직 잠겨 있어요")
                .font(.system(size: 10))
                .foregroundStyle(AppColors.secondaryText)
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppColors.surface)
        )

        if unlocked {
            Button {
                withAnimation(.easeIn(duration: 0.15)) {
                    selectedBadge = badge
                }
            } label: {
                cellBody
            }
            .buttonStyle(.plain)
        } else {
            cellBody
        }
    }
}

#Preview {
    BadgesView()
        .environmentObject({
            let d = AppDependencies.preview()
            d.persistence.earnedBadgeIDs = [
                Badge.firstReturn.id,
                Badge.returnNovice.id,
                Badge.perfectDay.id
            ]
            d.persistence.totalReturnCount = 23
            return d
        }())
}
