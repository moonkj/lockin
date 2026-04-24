import Foundation
import AppIntents

/// Siri / Shortcut 자동화용 App Intents.
///
/// 구조: 각 intent 의 `perform()` 은 실제 비즈니스 로직을 직접 실행하지 않고,
/// `lockinfocus://startFocus` / `endFocus` URL 딥링크를 열어 앱이 포그라운드로
/// 돌아온 뒤 `RootView.onOpenURL` → `RouteParser.parse` → `AppDependencies` 로
/// 흐르게 한다. 이유:
/// 1. `AppDependencies` 는 `@MainActor` / SwiftUI `@StateObject` 라 intent process 에서
///    접근이 까다롭다.
/// 2. 사용자는 "집중 시작" 음성 명령 시 앱 UI 에서 상태 변화를 눈으로 확인하고 싶다.
/// 3. 딥링크 경로는 이미 iOS 가 앱 프로세스 부팅을 책임져 구현 부담이 적다.
///
/// ShowScore 는 UI 로 이동할 필요 없으므로 UserDefaults 에서 직접 읽어 문자열로 반환.

@available(iOS 16.0, *)
struct StartFocusIntent: AppIntent {
    static var title: LocalizedStringResource = "지금 집중 시작"
    static var description = IntentDescription("허용 앱만 남기고 잠금을 적용해 바로 집중을 시작해요.")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        // AppGroup UserDefaults 에 pending 플래그 기록 → 앱 foreground 진입 시 RootView 소비.
        UserDefaults(suiteName: AppGroup.identifier)?
            .set(AppDependencies.Route.startFocus.rawValue, forKey: PersistenceKeys.pendingIntentRoute)
        return .result()
    }
}

@available(iOS 16.0, *)
struct EndFocusIntent: AppIntent {
    static var title: LocalizedStringResource = "집중 종료"
    static var description = IntentDescription("집중 세션을 마무리하고 잠금을 풀어요. 엄격 모드 중엔 동작하지 않아요.")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        UserDefaults(suiteName: AppGroup.identifier)?
            .set(AppDependencies.Route.endFocus.rawValue, forKey: PersistenceKeys.pendingIntentRoute)
        return .result()
    }
}

/// 오늘 집중 점수를 읽어 Siri / Shortcut 에 문자열로 반환. UI 진입 없이 처리.
@available(iOS 16.0, *)
struct ShowFocusScoreIntent: AppIntent {
    static var title: LocalizedStringResource = "오늘의 집중 점수"
    static var description = IntentDescription("오늘 쌓인 집중 점수와 연속 기록을 알려드려요.")

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let defaults = UserDefaults(suiteName: AppGroup.identifier) ?? .standard
        let today = ShowFocusScoreIntent.todayString()
        let storedDate = defaults.string(forKey: PersistenceKeys.focusScoreDateKey)
        let score = (storedDate == today) ? defaults.integer(forKey: SharedKeys.focusScoreToday) : 0
        let phrase = score == 0
            ? "오늘은 아직 기록이 없어요."
            : "오늘 집중 점수는 \(score)점이에요."
        return .result(value: phrase, dialog: IntentDialog(stringLiteral: phrase))
    }

    private static func todayString() -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
}

/// AppShortcuts 자동 등록. iOS 16+ 가 이 provider 를 스캔해 Siri 에서 수동 설정 없이
/// "Hey Siri, 지금 집중 시작" 같은 phrase 를 바로 인식한다.
@available(iOS 16.0, *)
struct LockinFocusShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartFocusIntent(),
            phrases: [
                "\(.applicationName) 집중 시작",
                "지금 집중 시작 in \(.applicationName)"
            ],
            shortTitle: "집중 시작",
            systemImageName: "play.circle.fill"
        )
        AppShortcut(
            intent: EndFocusIntent(),
            phrases: [
                "\(.applicationName) 집중 종료",
                "집중 끝 in \(.applicationName)"
            ],
            shortTitle: "집중 종료",
            systemImageName: "pause.circle.fill"
        )
        AppShortcut(
            intent: ShowFocusScoreIntent(),
            phrases: [
                "\(.applicationName) 오늘 점수",
                "오늘 집중 점수 in \(.applicationName)"
            ],
            shortTitle: "오늘의 점수",
            systemImageName: "leaf.fill"
        )
    }
}
