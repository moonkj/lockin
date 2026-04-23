import SwiftUI

@main
struct LockinFocusApp: App {
    @StateObject private var deps = AppDependencies.live()

    init() {
        // 재설치 직후 iOS Keychain 에 남은 이전 설치의 비번을 초기화.
        // UserDefaults.standard 는 앱 컨테이너와 함께 지워지므로 "처음 실행"의 신호로 쓸 수 있다.
        let defaults = UserDefaults.standard
        if !defaults.bool(forKey: "hasLaunchedBefore") {
            AppPasscodeStore.clear()
            defaults.set(true, forKey: "hasLaunchedBefore")
        }

        // 다른 기기에서 바뀐 닉네임·유저ID 를 초기에 한번 당겨온다.
        ICloudKeyValueStore.synchronize()

        // 권한이 이미 승인돼 있으면 주간 리포트 알림 스케줄 재등록.
        WeeklyReportScheduler.reschedule()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(deps)
                // 앱 전체 흰색 테마 유지. FamilyActivityPicker 같은 시스템 뷰도
                // 기기 다크 모드를 따라가지 않고 라이트 스킨으로 렌더링된다.
                .preferredColorScheme(.light)
        }
    }
}
