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

        // 하루 마감 알림 — 사용자가 설정에서 on 해뒀으면 재등록, 아니면 정리.
        let dailyOn = UserDefaults(suiteName: AppGroup.identifier)?
            .bool(forKey: PersistenceKeys.dailySummaryNotification) ?? false
        DailySummaryScheduler.rescheduleIfEnabled(when: dailyOn)

        // 주 1회 스트릭 보존 토큰 — deps 초기화된 뒤 Dashboard onAppear 에서 호출.
        // 앱이 월요일에 열리지 않을 수도 있으니 (매주 갱신) 매 launch 에 체크.
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(deps)
                // 앱 전체 흰색 테마 유지. FamilyActivityPicker 같은 시스템 뷰도
                // 기기 다크 모드를 따라가지 않고 라이트 스킨으로 렌더링된다.
                .preferredColorScheme(.light)
                // Dynamic Type 지원: .xSmall ~ .accessibility2 범위로 제한해
                // 레이아웃이 극단적 크기에서 깨지는 것을 방지. scaledFont 가 이 범위를
                // 따라 배율 적용.
                .dynamicTypeSize(.xSmall ... .accessibility2)
        }
    }
}
