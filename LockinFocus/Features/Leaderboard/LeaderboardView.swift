import SwiftUI

/// CloudKit 기반 랭킹 — 일간/주간/월간 탭 + Top 3 메달 + 4~30위 리스트 + 내 순위.
///
/// 모든 비즈니스 로직 (cache · filter · load · submit) 은 `LeaderboardViewModel` 에
/// 위치한다. View 는 vm.@Published 상태를 관찰해서 렌더만 한다.
struct LeaderboardView: View {
    @EnvironmentObject var deps: AppDependencies
    @Environment(\.dismiss) private var dismiss

    @StateObject private var vm: LeaderboardViewModel
    @State private var showNicknameSetup: Bool = false
    @State private var showFriendsSheet: Bool = false

    typealias Scope = LeaderboardViewModel.Scope

    /// 기본 init — 런타임 사용 경로. VM 은 stub 으로 시작하고 .task 에서 실제 deps 와 reconnect.
    init() {
        _vm = StateObject(wrappedValue: LeaderboardViewModel(
            service: _StubLeaderboardService(),
            persistence: InMemoryPersistenceStore()
        ))
    }

    /// 테스트 전용 init — 초기 entries/period/userID 주입해 medal/rankRow 렌더 분기 검증.
    /// VM 의 stub service / InMemoryPersistenceStore 를 만들고 entries 를 직접 채운다.
    init(
        initialPeriod: LeaderboardPeriod,
        initialEntries: [LeaderboardEntry],
        initialMyUserID: String = ""
    ) {
        _vm = StateObject(wrappedValue: LeaderboardViewModel(
            service: _StubLeaderboardService(),
            persistence: InMemoryPersistenceStore(),
            initialPeriod: initialPeriod,
            initialEntries: initialEntries,
            initialMyUserID: initialMyUserID
        ))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView {
                    let visible = vm.entries
                    let maxScore = vm.maxScoreInPeriod
                    VStack(spacing: 20) {
                        scopePicker
                        periodPicker
                        topThreeSection(visible)
                        summaryStrip(visible)
                        rankingList(visible, maxScore: maxScore)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                    .readingWidth()
                }

                if vm.isLoading && vm.entries.isEmpty {
                    ProgressView().scaleEffect(1.2)
                }
            }
            .navigationTitle(vm.scope == .friends ? "친구 랭킹" : "전체 랭킹")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                        .foregroundStyle(AppColors.secondaryText)
                }
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 14) {
                        Button {
                            showFriendsSheet = true
                        } label: {
                            Image(systemName: "person.2")
                                .foregroundStyle(AppColors.primaryText)
                        }
                        .accessibilityLabel("친구 관리")

                        Button {
                            Task {
                                await vm.submitAndRefresh(nicknameSetupTrigger: {
                                    showNicknameSetup = true
                                })
                            }
                        } label: {
                            Image(systemName: "arrow.up.circle")
                                .foregroundStyle(AppColors.primaryText)
                        }
                        .disabled(vm.isSubmitting)
                        .accessibilityLabel("내 점수 랭킹에 등록")
                    }
                }
            }
            .sheet(isPresented: $showNicknameSetup) {
                NicknameSetupView { _ in
                    Task {
                        await vm.submitAndRefresh()
                    }
                }
                .environmentObject(deps)
            }
            .sheet(isPresented: $showFriendsSheet) {
                FriendsManagementView()
                    .environmentObject(deps)
            }
            .task {
                vm.connect(service: deps.leaderboardService, persistence: deps.persistence)
                vm.badgeAwardHandler = { [weak deps] badges in
                    deps?.celebrate(badges)
                }
                await vm.onAppear()
            }
            .onReceive(deps.objectWillChange) { _ in
                // iCloud KV 로 userID 가 다른 기기에서 변경됐을 때 vm 도 따라감.
                vm.refreshMyUserIDIfChanged()
            }
        }
    }

    // MARK: - Sections

    /// 친구 scope 에서 친구가 0 명일 때 보여주는 안내 + CTA.
    private var emptyFriendsPlaceholder: some View {
        VStack(spacing: 14) {
            Image(systemName: "person.2.circle")
                .scaledFont(36)
                .foregroundStyle(AppColors.secondaryText.opacity(0.6))
                .accessibilityHidden(true)

            VStack(spacing: 4) {
                Text("아직 친구가 없어요")
                    .scaledFont(15, weight: .semibold)
                    .foregroundStyle(AppColors.primaryText)
                Text("초대 링크를 공유하면 그룹 랭킹에서 함께 비교할 수 있어요.")
                    .scaledFont(12)
                    .foregroundStyle(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
            }

            Button {
                showFriendsSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
                    Text("친구 초대하기")
                }
                .scaledFont(13, weight: .semibold)
                .foregroundStyle(Color.white)
                .padding(.horizontal, 16)
                .frame(height: 36)
                .background(
                    Capsule().fill(AppColors.primaryText)
                )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    /// 전체 / 친구 범위 전환 세그먼트.
    private var scopePicker: some View {
        HStack(spacing: 0) {
            ForEach(Scope.allCases) { s in
                let isSelected = vm.scope == s
                Button {
                    Haptics.selection()
                    vm.scope = s
                } label: {
                    Text(s.label)
                        .scaledFont(13, weight: isSelected ? .semibold : .regular)
                        .foregroundStyle(isSelected ? AppColors.primaryText : AppColors.secondaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(isSelected ? AppColors.surface : Color.clear)
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(AppColors.divider.opacity(0.3))
        )
    }

    private var periodPicker: some View {
        HStack(spacing: 8) {
            ForEach(LeaderboardPeriod.allCases) { p in
                let isSelected = vm.period == p
                Button {
                    vm.period = p
                } label: {
                    Text(p.label)
                        .scaledFont(14, weight: isSelected ? .semibold : .regular)
                        .foregroundStyle(isSelected ? Color.white : AppColors.secondaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(isSelected ? AppColors.primaryText : AppColors.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(isSelected ? Color.clear : AppColors.divider, lineWidth: 1)
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 4)
    }

    private func topThreeSection(_ visible: [LeaderboardEntry]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(vm.period.label) Top 3")
                .scaledFont(13, weight: .semibold)
                .foregroundStyle(AppColors.primaryText)

            HStack(alignment: .bottom, spacing: 20) {
                if visible.indices.contains(1) {
                    medalCell(rank: 2, entry: visible[1])
                } else {
                    placeholderMedal(rank: 2)
                }
                if visible.indices.contains(0) {
                    medalCell(rank: 1, entry: visible[0])
                } else {
                    placeholderMedal(rank: 1)
                }
                if visible.indices.contains(2) {
                    medalCell(rank: 3, entry: visible[2])
                } else {
                    placeholderMedal(rank: 3)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.surface)
        )
    }

    private func summaryStrip(_ visible: [LeaderboardEntry]) -> some View {
        HStack(spacing: 20) {
            summaryStat(label: "참여자", value: "\(visible.count)명")
            Divider().frame(height: 28)
            summaryStat(
                label: "내 등수",
                value: vm.myRank.map { "\($0)등" } ?? "미등록"
            )
            Divider().frame(height: 28)
            summaryStat(
                label: "상위",
                value: vm.myPercentile.map { "\($0)%" } ?? "—"
            )
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppColors.surface)
        )
    }

    private func summaryStat(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .scaledFont(15, weight: .semibold)
                .foregroundStyle(AppColors.primaryText)
            Text(label)
                .scaledFont(10)
                .foregroundStyle(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }

    private func rankingList(_ visible: [LeaderboardEntry], maxScore: Double) -> some View {
        VStack(spacing: 8) {
            if let errorMessage = vm.errorMessage {
                Text(errorMessage)
                    .scaledFont(12)
                    .foregroundStyle(AppColors.error)
                    .padding(.vertical, 4)
            }

            if vm.scope == .friends && deps.persistence.friendUserIDs.isEmpty {
                emptyFriendsPlaceholder
            } else if visible.count <= 3 {
                Text("아직 등록된 기록이 많지 않아요.\n오른쪽 위 ↑ 버튼으로 내 점수를 등록해보세요.")
                    .scaledFont(13)
                    .foregroundStyle(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 40)
            } else {
                ForEach(Array(visible.prefix(30).enumerated()), id: \.element.id) { index, entry in
                    if index >= 3 {
                        rankRow(rank: index + 1, entry: entry, maxScore: maxScore)
                    }
                }
            }

            // 내 순위가 30위 밖이면 하단에 따로.
            if let rank = vm.myRank, rank > 30, let me = vm.myEntry {
                Divider().padding(.vertical, 6)
                Text("내 순위")
                    .scaledFont(12, weight: .semibold)
                    .foregroundStyle(AppColors.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                rankRow(rank: rank, entry: me, maxScore: maxScore)
            }
        }
    }

    // MARK: - Components

    private func medalCell(rank: Int, entry: LeaderboardEntry) -> some View {
        let size: CGFloat = rank == 1 ? 64 : 54
        return VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(medalGradient(for: rank))
                    .frame(width: size, height: size)
                    .shadow(color: medalColor(for: rank).opacity(0.35), radius: 6, x: 0, y: 3)
                Image(systemName: "trophy.fill")
                    .scaledFont(rank == 1 ? 26 : 22, weight: .semibold)
                    .foregroundStyle(.white)
            }

            Text("\(rank)등")
                .scaledFont(11, weight: .semibold)
                .foregroundStyle(medalColor(for: rank))

            Text(entry.nickname)
                .scaledFont(12, weight: rank == 1 ? .semibold : .medium)
                .foregroundStyle(AppColors.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text("\(entry.score(for: vm.period))점")
                .scaledFont(11, weight: .medium)
                .foregroundStyle(AppColors.secondaryText)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
    }

    private func placeholderMedal(rank: Int) -> some View {
        let size: CGFloat = rank == 1 ? 64 : 54
        return VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(AppColors.divider)
                    .frame(width: size, height: size)
                Image(systemName: "trophy.fill")
                    .scaledFont(rank == 1 ? 26 : 22, weight: .semibold)
                    .foregroundStyle(AppColors.secondaryText.opacity(0.5))
            }
            Text("\(rank)등")
                .scaledFont(11, weight: .semibold)
                .foregroundStyle(AppColors.secondaryText)
            Text("—")
                .scaledFont(12)
                .foregroundStyle(AppColors.secondaryText)
            Text(" ")
                .scaledFont(11)
        }
        .frame(maxWidth: .infinity)
    }

    private func rankRow(rank: Int, entry: LeaderboardEntry, maxScore: Double) -> some View {
        let isMe = entry.userID == vm.myUserID
        let score = entry.score(for: vm.period)
        let ratio: Double = maxScore > 0 ? Double(score) / maxScore : 0
        // VoiceOver 용 통합 라벨 — 메달 색 · 등수 · 이름 · 점수를 한 번에 읽어준다.
        let medalPrefix: String = {
            switch rank {
            case 1: return "금메달 1등"
            case 2: return "은메달 2등"
            case 3: return "동메달 3등"
            default: return "\(rank)등"
            }
        }()
        let meSuffix = isMe ? " 나" : ""
        let a11yLabel = "\(medalPrefix), \(entry.nickname)\(meSuffix), \(score)점"

        return VStack(spacing: 6) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(medalColor(for: rank), lineWidth: 1.5)
                        .frame(width: 28, height: 28)
                    Text("\(rank)")
                        .scaledFont(13, weight: .semibold)
                        .foregroundStyle(medalColor(for: rank))
                }

                Text(entry.nickname)
                    .scaledFont(15, weight: isMe ? .semibold : .regular)
                    .foregroundStyle(AppColors.primaryText)
                    .lineLimit(2)

                if isMe {
                    Text("나")
                        .scaledFont(10, weight: .semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(AppColors.primaryText))
                }

                Spacer()

                Text("\(score)점")
                    .scaledFont(14, weight: .semibold, design: .rounded)
                    .foregroundStyle(medalColor(for: rank))
                    .monospacedDigit()
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppColors.divider)
                        .frame(height: 4)
                    Capsule()
                        .fill(medalColor(for: rank))
                        .frame(width: max(6, proxy.size.width * ratio), height: 4)
                }
            }
            .frame(height: 4)
            .accessibilityHidden(true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isMe ? AppColors.surface : Color.clear)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(a11yLabel)
    }

    // MARK: - Medal palette

    private func medalColor(for rank: Int) -> Color {
        switch rank {
        case 1: return Color(red: 0.95, green: 0.70, blue: 0.20) // gold
        case 2: return Color(red: 0.68, green: 0.70, blue: 0.74) // silver
        case 3: return Color(red: 0.80, green: 0.52, blue: 0.28) // bronze
        default: return Color(red: 0.93, green: 0.55, blue: 0.15) // orange tint for ranks 4+
        }
    }

    private func medalGradient(for rank: Int) -> LinearGradient {
        let base = medalColor(for: rank)
        return LinearGradient(
            colors: [base.opacity(0.9), base],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Stub service

/// LeaderboardView 의 init 들이 VM 을 즉시 만들어야 하는 SwiftUI 제약 때문에 사용하는
/// no-op service. 실제 deps 는 `.task` 에서 `vm.connect(...)` 로 주입된다.
private final class _StubLeaderboardService: LeaderboardServiceProtocol {
    func accountAvailable() async -> Bool { false }
    func submit(
        userID: String, nickname: String,
        dailyScore: Int, weeklyTotal: Int, monthlyTotal: Int, now: Date
    ) async throws -> LeaderboardEntry {
        throw CloudKitLeaderboardService.ServiceError.iCloudUnavailable
    }
    func fetchRanking(period: LeaderboardPeriod, limit: Int) async throws -> [LeaderboardEntry] { [] }
    func fetchAllRaw(limit: Int) async throws -> [LeaderboardEntry] { [] }
    func deleteRecord(userID: String) async throws -> Bool { false }
}
