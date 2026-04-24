import SwiftUI

/// 앱 최상단 뷰. 온보딩 완료 여부에 따라 분기하고, Extension 이 쌓은
/// interceptQueue 를 포그라운드 전환 시마다 비워 `InterceptView` 를 자동 프레젠테이션.
struct RootView: View {
    @EnvironmentObject var deps: AppDependencies
    @Environment(\.scenePhase) private var scenePhase

    @State private var showIntercept: Bool = false

    var body: some View {
        Group {
            if deps.persistence.hasCompletedOnboarding {
                DashboardView()
            } else {
                OnboardingContainerView()
            }
        }
        .background(AppColors.background.ignoresSafeArea())
        .onAppear {
            drainQueue()
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                drainQueue()
            }
        }
        .onOpenURL { url in
            if let payload = FriendInviteLink.parse(url) {
                deps.requestFriendInvite(payload)
            } else if let route = RouteParser.parse(url) {
                deps.requestRoute(route)
            }
        }
        .alert(
            "친구 추가",
            isPresented: Binding(
                get: { deps.pendingFriendInvite != nil },
                set: { if !$0 { deps.consumeFriendInvite() } }
            ),
            presenting: deps.pendingFriendInvite
        ) { _ in
            Button("추가") { deps.acceptFriendInvite() }
            Button("취소", role: .cancel) { deps.consumeFriendInvite() }
        } message: { payload in
            Text("\(payload.nickname)님을 친구로 추가하시겠어요?\n추가하면 그룹 랭킹에서 함께 비교할 수 있어요.")
        }
        .sheet(isPresented: $showIntercept) {
            InterceptView()
                .environmentObject(deps)
        }
        .fullScreenCover(item: Binding(
            get: { deps.currentCelebratedBadge },
            set: { newValue in
                // SwiftUI 가 자체적으로 nil 을 set 할 때만 큐를 당긴다.
                // "확인" 버튼 경로는 onConfirm 에서 이미 dismissCelebratedBadge 를 호출.
                if newValue == nil { deps.dismissCelebratedBadge() }
            }
        )) { badge in
            BadgeCelebrationView(badge: badge) {
                deps.dismissCelebratedBadge()
            }
        }
    }

    private func drainQueue() {
        let events = deps.persistence.drainInterceptQueue()
        guard !events.isEmpty else { return }
        showIntercept = true
    }
}

#Preview("Onboarding") {
    let d = AppDependencies.preview()
    d.persistence.hasCompletedOnboarding = false
    return RootView().environmentObject(d)
}

#Preview("Dashboard") {
    let d = AppDependencies.preview()
    d.persistence.hasCompletedOnboarding = true
    return RootView().environmentObject(d)
}
