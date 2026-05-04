import ManagedSettings
import Foundation

/// Shield 화면의 버튼 탭을 처리한다.
///
/// - primary (돌아가기): Shield 유지. 큐에 '되돌림' 이벤트 기록.
/// - secondary (10초 기다리고 계속): 큐에 인터셉트 요청 기록 후 `.defer` 반환.
///   메인 앱이 포그라운드로 들어오면 큐를 읽어 InterceptView 를 자동 프레젠테이션한다.
///   `NSExtensionContext.open(_:)` 으로의 자동 포그라운드화는 실기기 검증 후 결정.
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
            completionHandler(.defer)
        @unknown default:
            completionHandler(.none)
        }
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
