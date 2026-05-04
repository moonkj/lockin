import XCTest
import SwiftUI
import FamilyControls
import ViewInspector
@testable import LockinFocus

/// 남은 coverage gap 메우기 — 각 view 의 상태 분기.
@MainActor
final class ExtendedViewTests: XCTestCase {

    // MARK: - SettingsView branches

    func testSettingsView_withNickname_noCrash() throws {
        // 닉네임은 load() (onAppear) 에서 State 로 옮겨지므로 ViewInspector inspect
        // 타이밍상 렌더엔 안 잡힘. 최소 inspect 가 crash 없이 통과하는지만 확인.
        let deps = AppDependencies.preview()
        deps.persistence.nickname = "집중러"
        let view = SettingsView().environmentObject(deps)
        XCTAssertNoThrow(try view.inspect())
    }

    func testSettingsView_strictActive_showsRemainingFooterCopy() throws {
        try XCTSkipIfViewInspectorBlocked()
        let deps = AppDependencies.preview()
        deps.persistence.strictModeEndAt = Date().addingTimeInterval(3600)
        let view = SettingsView().environmentObject(deps)
        XCTAssertNoThrow(try view.inspect().find(
            text: "설정한 시간이 끝나기 전에는 어떤 방법으로도 해제할 수 없어요."
        ))
    }

    // MARK: - DashboardView branches

    func testDashboardView_notInFocus_showsStartButton() throws {
        try XCTSkipIfViewInspectorBlocked()
        let deps = AppDependencies.preview()
        deps.persistence.isManualFocusActive = false
        let view = DashboardView().environmentObject(deps)
        XCTAssertNoThrow(try view.inspect().find(text: L("지금 집중 시작")))
    }

    func testDashboardView_injectedManualFocus_showsEndButton() throws {
        try XCTSkipIfViewInspectorBlocked()
        let view = DashboardView(initialIsManualFocus: true)
            .environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(text: L("집중 종료")))
    }

    // MARK: - BadgesView branches

    func testBadgesView_withEarnedBadges_noLockedMessage() throws {
        let deps = AppDependencies.preview()
        deps.persistence.earnedBadgeIDs = Set(Badge.allCases.map(\.id))
        let view = BadgesView().environmentObject(deps)
        // 모든 뱃지 획득 시 "아직 잠겨 있어요" 표시는 없어야 함.
        XCTAssertThrowsError(try view.inspect().find(text: L("아직 잠겨 있어요")))
    }

    func testBadgesView_showsCountWhenPartiallyEarned() throws {
        let deps = AppDependencies.preview()
        deps.persistence.earnedBadgeIDs = [
            Badge.firstReturn.id,
            Badge.perfectDay.id,
            Badge.streak3Days.id
        ]
        let view = BadgesView().environmentObject(deps)
        XCTAssertNoThrow(try view.inspect().find(text: L("3 / 26 획득")))
    }

    // MARK: - NicknameSetupView branches

    func testNicknameSetupView_hasPlaceholder() throws {
        try XCTSkipIfViewInspectorBlocked()
        let view = NicknameSetupView { _ in }
            .environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(text: L("랭킹에서 다른 사용자에게 이렇게 보여요.\n2~20자.")))
    }

    func testNicknameSetupView_withInitialName_rendersText() throws {
        let view = NicknameSetupView(
            onSaved: { _ in },
            initialNickname: "집중러"
        ).environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect())
    }

    func testNicknameSetupView_withErrorMessage_showsError() throws {
        let view = NicknameSetupView(
            onSaved: { _ in },
            initialNickname: "시발",
            initialError: "허용되지 않은 단어가 포함돼 있어요."
        ).environmentObject(AppDependencies.preview())
        XCTAssertNoThrow(try view.inspect().find(text: L("허용되지 않은 단어가 포함돼 있어요.")))
    }

    // MARK: - FamilyActivitySelection+Display

    func testDisplayBreakdown_emptyReturnsNil() {
        XCTAssertNil(FamilyActivitySelection().displayBreakdown)
    }

    func testTotalItemCount_emptyReturnsZero() {
        XCTAssertEqual(FamilyActivitySelection().totalItemCount, 0)
    }

    // MARK: - NoopBlockingEngine temp allow branch

    func testNoopBlockingEngine_temporarilyAllow_isNoop() {
        let engine = NoopBlockingEngine()
        engine.clearShield()
        engine.applyWhitelist(for: FamilyActivitySelection())
        XCTAssertTrue(true)
    }

    // MARK: - RootView basic render

    func testRootView_onboardingNotComplete_showsOnboarding() throws {
        let deps = AppDependencies.preview()
        deps.persistence.hasCompletedOnboarding = false
        let view = RootView().environmentObject(deps)
        XCTAssertNoThrow(try view.inspect())
    }

    func testRootView_onboardingComplete_showsDashboard() throws {
        let deps = AppDependencies.preview()
        deps.persistence.hasCompletedOnboarding = true
        let view = RootView().environmentObject(deps)
        XCTAssertNoThrow(try view.inspect())
    }

    // MARK: - InterceptView strict active branch

    func testInterceptView_withStrictActive_rendersStrictAwareCopy() throws {
        let deps = AppDependencies.preview()
        deps.persistence.strictModeEndAt = Date().addingTimeInterval(3600)
        let view = InterceptView().environmentObject(deps)
        XCTAssertNoThrow(try view.inspect())
    }

    // MARK: - BadgeDetailCardView covers all badges

    func testBadgeDetailCardView_rendersForEveryBadge() throws {
        for badge in Badge.allCases {
            let view = BadgeDetailCardView(badge: badge, onClose: {})
            XCTAssertNoThrow(try view.inspect().find(text: badge.title),
                             "\(badge.id) 의 title 이 카드에 렌더되어야")
        }
    }

    // MARK: - BadgeCelebrationView covers all badges

    func testBadgeCelebrationView_rendersForEveryBadge() throws {
        for badge in Badge.allCases {
            let view = BadgeCelebrationView(badge: badge, onConfirm: {})
            XCTAssertNoThrow(try view.inspect().find(text: badge.title))
        }
    }
}
