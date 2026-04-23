import SwiftUI

/// 앱 최상단 뷰. 온보딩 완료 여부에 따라 분기하고, Extension 이 쌓은
/// interceptQueue 를 포그라운드 전환 시마다 비워 `InterceptView` 를 자동 프레젠테이션.
struct RootView: View {
    @EnvironmentObject var deps: AppDependencies
    @Environment(\.scenePhase) private var scenePhase

    @State private var hasOnboarded: Bool = false
    @State private var showIntercept: Bool = false

    var body: some View {
        Group {
            if hasOnboarded {
                DashboardView()
            } else {
                OnboardingContainerView()
            }
        }
        .background(AppColors.background.ignoresSafeArea())
        .onAppear {
            refreshState()
            drainQueue()
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                refreshState()
                drainQueue()
            }
        }
        .sheet(isPresented: $showIntercept) {
            InterceptView()
                .environmentObject(deps)
        }
    }

    private func refreshState() {
        hasOnboarded = deps.persistence.hasCompletedOnboarding
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
