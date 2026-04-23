import Foundation

enum AppGroup {
    static let identifier = "group.com.moonkj.LockinFocus"

    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }
}

enum SharedKeys {
    static let familySelection = "familySelection"
    static let scheduleStart = "scheduleStart"
    static let scheduleEnd = "scheduleEnd"
    static let strictModeActive = "strictModeActive"
    static let focusScoreToday = "focusScoreToday"
}
