import Foundation

enum AppGroup {
    static let identifier = "group.com.imurmkj.LockinFocus"

    static var sharedDefaults: UserDefaults {
        guard let defaults = UserDefaults(suiteName: identifier) else {
            fatalError("App Group '\(identifier)' 이 등록되지 않았습니다. Capabilities 확인 요망.")
        }
        return defaults
    }
}

enum SharedKeys {
    static let familySelection = "familySelection"
    static let scheduleStart = "scheduleStart"
    static let scheduleEnd = "scheduleEnd"
    static let strictModeActive = "strictModeActive"
    static let focusScoreToday = "focusScoreToday"
}
