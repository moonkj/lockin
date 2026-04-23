import Foundation

/// ShieldActionExtension 은 메인 앱 Core/Shared/AppGroup.swift 를 공유하지 않는다.
/// 메인 앱의 `AppGroup.identifier` / `SharedKeys.*` 와 **반드시 같은 값** 을 유지.
enum AppGroup {
    static let identifier = "group.com.moonkj.LockinFocus"
}

enum SharedKeys {
    static let interceptQueue = "interceptQueue"
}
