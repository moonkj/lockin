import ManagedSettings
import Foundation

/// Shield 화면의 버튼 탭을 처리한다.
///
/// - primary (돌아가기): Shield 유지. 큐에 '되돌림' 이벤트 기록 + 즉시 +5 점.
/// - secondary (메인 앱에서 풀기): 큐에 인터셉트 요청 + pendingIntentRoute=intercept
///   적재. ShieldActionExtension 은 메인 앱을 직접 포그라운드화할 수 없으므로
///   사용자가 직접 LockinFocus 앱을 열면 RootView.drainPendingIntentRoute() 가
///   route 를 RouterStore 에 전달하고 DashboardView 가 InterceptView 시트
///   (10초 카운트다운 → "그래도 열기") 를 자동으로 띄운다.
class ShieldActionExtensionHandler: ShieldActionDelegate {
    override func handle(
        action: ShieldAction,
        for application: ApplicationToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        switch action {
        case .primaryButtonPressed:
            enqueue(type: "returned", subjectKind: "application")
            completionHandler(.none)
        case .secondaryButtonPressed:
            enqueue(type: "intercept_requested", subjectKind: "application")
            requestMainAppIntercept()
            completionHandler(.defer)
        @unknown default:
            completionHandler(.none)
        }
    }

    override func handle(
        action: ShieldAction,
        for category: ActivityCategoryToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        switch action {
        case .primaryButtonPressed:
            enqueue(type: "returned", subjectKind: "category")
            completionHandler(.none)
        case .secondaryButtonPressed:
            enqueue(type: "intercept_requested", subjectKind: "category")
            requestMainAppIntercept()
            completionHandler(.defer)
        @unknown default:
            completionHandler(.none)
        }
    }

    override func handle(
        action: ShieldAction,
        for webDomain: WebDomainToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        switch action {
        case .primaryButtonPressed:
            enqueue(type: "returned", subjectKind: "webDomain")
            completionHandler(.none)
        case .secondaryButtonPressed:
            enqueue(type: "intercept_requested", subjectKind: "webDomain")
            requestMainAppIntercept()
            completionHandler(.defer)
        @unknown default:
            completionHandler(.none)
        }
    }

    /// secondary 버튼 처리 — pendingIntentRoute 키에 "intercept" 적재. 메인 앱 다음
    /// 진입 시 RootView 가 큐에서 빼서 RouterStore 에 전달.
    private func requestMainAppIntercept() {
        guard let defaults = UserDefaults(suiteName: AppGroup.identifier) else { return }
        defaults.set("intercept", forKey: SharedKeys.pendingIntentRoute)
    }

    private func enqueue(type: String, subjectKind: String) {
        guard let defaults = UserDefaults(suiteName: AppGroup.identifier) else {
            return
        }
        // "돌아가기" 경로는 즉시 +5 점 보상 (점수 규칙 B). 쿨다운·한도 적용된 경우 false.
        // 메인 앱이 다음 진입 시 InterceptView 의 awardReturnPoint() 를 다시 부르지 않도록
        // 큐 이벤트에 alreadyScored 플래그를 표기해서 이중 지급을 막는다.
        var alreadyScored = false
        if type == "returned" {
            alreadyScored = ReturnPointAwarder.awardIfEligible()
        }
        var queue = defaults.array(forKey: SharedKeys.interceptQueue) as? [[String: Any]] ?? []
        queue.append([
            "timestamp": Date().timeIntervalSince1970,
            "type": type,
            "subjectKind": subjectKind,
            "alreadyScored": alreadyScored
        ])
        defaults.set(queue, forKey: SharedKeys.interceptQueue)
    }
}
