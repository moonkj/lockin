import SwiftUI

/// 친구 목록 + 초대 링크 공유 + 제거.
///
/// 초대 링크는 내 userID 와 닉네임을 담아 `lockinfocus://friend?uid=X&nick=Y`
/// 형태로 만들어지며, 상대가 열면 RootView 의 alert 에서 친구 추가 확인을 받는다.
struct FriendsManagementView: View {
    @EnvironmentObject var deps: AppDependencies
    @Environment(\.dismiss) private var dismiss

    @State private var friendIDs: [String] = []
    @State private var nicknameCache: [String: String] = [:]
    @State private var pendingRemoval: (uid: String, nickname: String)?
    @State private var showNicknameSetup: Bool = false

    private var myUserID: String { deps.persistence.leaderboardUserID }
    private var myNickname: String? { deps.persistence.nickname }

    private var shareURL: URL? {
        guard let nick = myNickname, !nick.isEmpty else { return nil }
        return FriendInviteLink.shareURL(myUserID: myUserID, myNickname: nick)
    }

    private var shareMessage: String {
        // 앱 이름 노출 금지 (CLAUDE.md 카피 규칙) — 앱 이름 대신 기능 설명만.
        let nick = myNickname ?? "저"
        return "\(nick)와 함께 집중 점수 그룹 랭킹을 해봐요. 링크를 눌러 친구로 추가하세요."
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        inviteCard
                        friendListSection
                        Spacer(minLength: 24)
                    }
                    .padding(20)
                    .readingWidth()
                }
            }
            .navigationTitle("친구")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                        .foregroundStyle(AppColors.secondaryText)
                }
            }
            .confirmationDialog(
                pendingRemoval.map { "\($0.nickname) 삭제" } ?? "친구 삭제",
                isPresented: Binding(
                    get: { pendingRemoval != nil },
                    set: { if !$0 { pendingRemoval = nil } }
                ),
                titleVisibility: .visible,
                presenting: pendingRemoval
            ) { removal in
                Button("삭제", role: .destructive) {
                    performRemove(uid: removal.uid)
                }
                Button("취소", role: .cancel) { pendingRemoval = nil }
            } message: { removal in
                Text("\(removal.nickname)님을 친구 목록에서 삭제할까요? 그룹 랭킹에서 더 이상 보이지 않아요.")
            }
            .sheet(isPresented: $showNicknameSetup) {
                NicknameSetupView { _ in }
                    .environmentObject(deps)
            }
        }
        .onAppear(perform: reload)
    }

    private var inviteCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("친구 초대")
                .scaledFont(15, weight: .semibold)
                .foregroundStyle(AppColors.primaryText)

            Text("링크를 공유해 친구 목록에 서로를 추가하면, 랭킹 화면 위 \u{201C}친구\u{201D} 탭에서만 우리끼리 비교할 수 있어요.")
                .scaledFont(12)
                .foregroundStyle(AppColors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            if let url = shareURL {
                ShareLink(item: url, message: Text(shareMessage)) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                        Text("초대 링크 공유")
                    }
                    .scaledFont(14, weight: .semibold)
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(AppColors.primaryText)
                    )
                }
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("초대 링크를 만들려면 먼저 닉네임이 필요해요.")
                        .scaledFont(12)
                        .foregroundStyle(AppColors.secondaryText)
                    Button {
                        showNicknameSetup = true
                    } label: {
                        Text("닉네임 설정하기")
                            .scaledFont(14, weight: .semibold)
                            .foregroundStyle(AppColors.primaryText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(AppColors.primaryText, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppColors.surface)
        )
    }

    @ViewBuilder
    private var friendListSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("내 친구 \(friendIDs.count)명")
                .scaledFont(13, weight: .semibold)
                .foregroundStyle(AppColors.primaryText)

            if friendIDs.isEmpty {
                Text("아직 친구가 없어요. 위의 초대 링크를 공유해보세요.")
                    .scaledFont(12)
                    .foregroundStyle(AppColors.secondaryText)
                    .padding(.vertical, 12)
            } else {
                VStack(spacing: 6) {
                    ForEach(friendIDs, id: \.self) { uid in
                        friendRow(uid: uid, nickname: nicknameCache[uid] ?? uid.prefix(6) + "…")
                    }
                }
            }
        }
    }

    private func friendRow<S: StringProtocol>(uid: String, nickname: S) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(AppColors.divider.opacity(0.6))
                .frame(width: 32, height: 32)
                .overlay(
                    Text(String(nickname.prefix(1)))
                        .scaledFont(14, weight: .semibold)
                        .foregroundStyle(AppColors.primaryText)
                )

            Text(nickname)
                .scaledFont(14, weight: .medium)
                .foregroundStyle(AppColors.primaryText)

            Spacer()

            Button {
                pendingRemoval = (uid: uid, nickname: String(nickname))
            } label: {
                Text("삭제")
                    .scaledFont(12)
                    .foregroundStyle(AppColors.error)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(AppColors.surface)
        )
    }

    private func reload() {
        friendIDs = deps.persistence.friendUserIDs
        nicknameCache = deps.persistence.friendNicknameCache
    }

    private func performRemove(uid: String) {
        remove(uid: uid)
        pendingRemoval = nil
    }

    private func remove(uid: String) {
        var ids = deps.persistence.friendUserIDs
        ids.removeAll { $0 == uid }
        deps.persistence.friendUserIDs = ids
        var cache = deps.persistence.friendNicknameCache
        cache.removeValue(forKey: uid)
        deps.persistence.friendNicknameCache = cache
        reload()
    }
}

#Preview {
    FriendsManagementView()
        .environmentObject(AppDependencies.preview())
}
