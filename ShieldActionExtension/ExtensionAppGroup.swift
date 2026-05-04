import Foundation

/// ShieldActionExtension 은 메인 앱 Core/Shared/AppGroup.swift 를 공유하지 않는다.
/// 메인 앱의 `AppGroup.identifier` / `SharedKeys.*` 와 **반드시 같은 값** 을 유지.
enum AppGroup {
    static let identifier = "group.com.moonkj.LockinFocus"
}

enum SharedKeys {
    static let interceptQueue = "interceptQueue"
    /// 메인 앱이 다음 포그라운드 진입 시 RootView.drainPendingIntentRoute() 가 읽고
    /// RouterStore.requestRoute(...) 로 전달. ShieldExtension secondary 누름 처리에 사용.
    /// 메인 앱의 PersistenceKeys.pendingIntentRoute 와 정확히 같은 값이어야 함.
    static let pendingIntentRoute = "pendingIntentRoute"
}
