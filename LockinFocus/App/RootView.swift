import SwiftUI
import FamilyControls

/// 앱 최상단 뷰. 온보딩 완료 여부에 따라 분기하고, Extension 이 쌓은
/// interceptQueue 를 포그라운드 전환 시마다 비워 `InterceptView` 를 자동 프레젠테이션.
struct RootView: View {
    @EnvironmentObject var deps: AppDependencies
    @Environment(\.scenePhase) private var scenePhase

    @State private var showIntercept: Bool = false
    /// 직전 drain 한 큐의 returned 이벤트 중 하나라도 Extension 이 이미 +5 부여했으면 true.
    /// InterceptView 의 "돌아가기" 가 같은 행위에 점수를 다시 주지 않도록 전달.
    @State private var lastDrainHadScoredReturn: Bool = false

    /// `hasCompletedOnboarding` 이 true 라도 FamilyControls 권한이 미부여 (`.notDetermined`)
    /// 라면 차단 자체가 작동하지 않으므로 온보딩으로 강제 회귀.
    /// 발생 케이스:
    ///   1) devicectl install 로 덮어쓸 때 App Group container 데이터는 잔존하지만
    ///      FamilyControls 권한 상태는 새 빌드 기준으로 재초기화된 경우.
    ///   2) iOS 설정에서 사용자가 권한을 회수한 후 앱 재시작.
    /// 이 가드 없이는 사용자가 온보딩 단계를 못 거쳐서 권한 요청 자체가 뜨지 않고,
    /// 차단도 동작하지 않는 dead state 에 빠진다.
    private var shouldShowOnboarding: Bool {
        if !deps.persistence.hasCompletedOnboarding { return true }
        let status = AuthorizationCenter.shared.authorizationStatus
        return status == .notDetermined
    }

    var body: some View {
        Group {
            if shouldShowOnboarding {
                OnboardingContainerView()
            } else {
                DashboardView()
            }
        }
        .background(AppColors.background.ignoresSafeArea())
        .onAppear {
            drainQueue()
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .active:
                deps.resumeTicker()
                drainQueue()
                drainPendingIntentRoute()
            case .background:
                // 백그라운드에선 tick 을 완전히 끄고, 시스템에 wake-up 을 맡긴다
                // (Live Activity / DeviceActivity / 로컬 알림 이 이미 설치돼 있어
                // strict 만료 등은 그쪽 경로로 사용자에게 노출된다).
                deps.pauseTicker()
            case .inactive:
                break
            @unknown default:
                break
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
            // 외부 URL 로 들어온 닉네임은 항상 sanitize 후 표시.
            // sanitize 발동 시 (닉네임이 "친구" 익명 라벨로 떨어진 경우) 사용자가 누군지
            // 식별할 수 있도록 userID 끝 4자리를 보조 표기.
            let display = AppDependencies.safeDisplayName(for: payload.nickname)
            let suffix = String(payload.userID.suffix(4))
            Text("\(display)님 (ID …\(suffix)) 을 친구로 추가하시겠어요?\n추가하면 그룹 랭킹에서 함께 비교할 수 있어요.")
        }
        .sheet(isPresented: $showIntercept) {
            InterceptView(skipReturnScore: lastDrainHadScoredReturn)
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
        // returned 타입이고 Extension 이 이미 점수 부여한 케이스가 한 건이라도 있으면
        // 이 sheet 회상 흐름에선 점수 skip.
        lastDrainHadScoredReturn = events.contains {
            $0.type == .returned && $0.alreadyScored
        }
        showIntercept = true
    }

    /// Siri App Intent 가 남긴 pending route 키를 읽어 `deps.requestRoute` 로 전달한다.
    /// 소비 즉시 키를 지워 재진입 시 중복 실행 방지.
    private func drainPendingIntentRoute() {
        let ud = UserDefaults(suiteName: AppGroup.identifier)
        guard let raw = ud?.string(forKey: PersistenceKeys.pendingIntentRoute),
              let route = AppDependencies.Route(rawValue: raw) else { return }
        ud?.removeObject(forKey: PersistenceKeys.pendingIntentRoute)
        deps.requestRoute(route)
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
