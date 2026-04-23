import SwiftUI

@main
struct LockinFocusApp: App {
    @StateObject private var deps = AppDependencies.live()

    init() {
        // 권한이 이미 승인돼 있으면 주간 리포트 알림 스케줄 재등록.
        WeeklyReportScheduler.reschedule()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(deps)
        }
    }
}
