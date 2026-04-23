import Foundation

/// 외부 URL (`lockinfocus://<key>`) 을 `AppDependencies.Route` 로 변환한다.
/// 위젯의 `widgetURL(_:)` 및 앱 외부 공유 링크에서 재사용.
enum RouteParser {
    static func parse(_ url: URL) -> AppDependencies.Route? {
        guard url.scheme == "lockinfocus" else { return nil }
        let key = url.host ?? url.lastPathComponent
        return AppDependencies.Route(rawValue: key)
    }
}
